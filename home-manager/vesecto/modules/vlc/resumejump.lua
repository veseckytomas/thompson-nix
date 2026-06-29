--   ________
--  /_  __/ /_  ____  ____ ___  ____  _________  ____
--   / / / __ \/ __ \/ __ `__ \/ __ \/ ___/ __ \/ __ \
--  / / / / / / /_/ / / / / / / /_/ (__  ) /_/ / / / /
-- /_/ /_/ /_/\____/_/ /_/ /_/ .___/____/\____/_/ /_/
--                          /_/
-- Tomáš Vesecký
-- Email: vesecky@proton.me
-- GitHub: veseckytomas
-- GitLab: vesecky.tomas

-- resumejump.lua - VLC Lua interface script
-- Remembers the last-played file per folder and auto-jumps to it when the same
-- folder is opened again as a playlist inside VLC (Media -> Open Folder, etc.).
-- Works together with the native resume feature (qt-continue=2): this script
-- picks the correct episode, VLC resumes the saved playback position.

-- Resume data is mutable runtime state, so it lives under XDG_STATE_HOME
-- (falling back to ~/.local/state) rather than under VLC's config dir.
local function mkdir_p(p)
    if not p or p == "" or p == "/" then return end
    local parent = p:match("^(.*)/[^/]+$")
    if parent and parent ~= "" and parent ~= p then mkdir_p(parent) end
    pcall(function() vlc.io.mkdir(p, "0755") end)
end

local function resume_state_file()
    local base = os.getenv("XDG_STATE_HOME")
    if not base or base == "" then
        base = (os.getenv("HOME") or "") .. "/.local/state"
    end
    local dir = base .. "/vlc"
    mkdir_p(dir)
    return dir .. "/resumejump-state.txt"
end

local state_file = resume_state_file()

-- Persistent state:
--   session_state[dir] = uri  -> last episode watched in that exact directory.
--   last_watched       = uri  -> the single most-recently watched episode.
-- On open we jump to last_watched if it is in the opened playlist (so opening
-- the whole series resumes wherever you were); otherwise we fall back to the
-- current directory's own last episode (so opening one season resumes it).
local session_state = {}
local last_watched = nil
local LAST_KEY = "__LAST__"

-- Per-playlist resume state machine. A fresh "Open Folder" replaces the
-- playlist; we detect that by its signature (the first item's path) and resume
-- exactly once, suppressing recording until we've landed so the transient item
-- VLC auto-plays during loading cannot clobber the saved episode.
--   phase: "init" (assessing) -> "resuming" (jumped, awaiting land) -> "done".
local tracked_sig = nil
local phase = "done"
local resume_target = nil
local resume_wait = 0
local RESUME_GIVEUP_TICKS = 8

-- While in "init" we wait for the playlist to finish populating (it loads
-- incrementally, especially with --recursive=expand) before falling back to a
-- per-directory target, so we don't act on a half-loaded list.
local init_count = -1
local init_stable = 0
local INIT_STABLE_TICKS = 3

local function load_state()
    local f = io.open(state_file, "r")
    if f then
        for line in f:lines() do
            local dir, last = line:match("^([^\t]+)\t([^\t]+)$")
            if dir and last then
                if dir == LAST_KEY then
                    last_watched = last
                else
                    session_state[dir] = last
                end
            end
        end
        f:close()
    end
end

local function save_state()
    local f, err = io.open(state_file, "w")
    if not f then
        vlc.msg.warn("resumejump: cannot write state: " .. tostring(err))
        return
    end
    for dir, last in pairs(session_state) do
        f:write(dir .. "\t" .. last .. "\n")
    end
    if last_watched then
        f:write(LAST_KEY .. "\t" .. last_watched .. "\n")
    end
    f:close()
end

load_state()

local function normalize(path)
    if not path then return nil end
    if path:sub(1, 17) == "file://localhost/" then
        path = path:sub(18)
    elseif path:sub(1, 7) == "file://" then
        path = path:sub(8)
    end
    return path
end

-- Compare two URIs ignoring percent-encoding differences.
local function same_uri(a, b)
    if not a or not b then return false end
    if a == b then return true end
    return vlc.strings.decode_uri(a) == vlc.strings.decode_uri(b)
end

local function parent_dir(uri)
    local path = normalize(vlc.strings.decode_uri(uri))
    if not path then return nil end
    path = path:gsub("/+$", "")
    local dir = path:match("^(.*)/[^/]*$")
    return dir
end

-- VLC 3.0's playlist.get("root", true) returns the full playlist as a tree.
-- Recursively collect leaf items (nodes with .path and no .children).
local function collect_leaves(node, items)
    if not node or type(node) ~= "table" then return end
    if node.flags and node.flags.disabled then return end
    if type(node.children) == "table" then
        for _, child in ipairs(node.children) do
            collect_leaves(child, items)
        end
    elseif node.path then
        table.insert(items, node)
    end
end

local function playlist_items()
    local ok, pl = pcall(vlc.playlist.get, "root", true)
    if not ok or type(pl) ~= "table" then return {} end
    local items = {}
    collect_leaves(pl, items)
    return items
end

local function current_uri()
    local ok, item = pcall(vlc.input.item)
    if not ok or not item then return nil end
    local ok2, uri = pcall(function() return item:uri() end)
    if ok2 then return uri end
    return nil
end

local function find_index(items, target)
    if not target then return nil end
    for i, item in ipairs(items) do
        if item.path and same_uri(item.path, target) then return i end
    end
    return nil
end

-- Identify a playlist load by its first item; a fresh "Open Folder" replaces
-- the playlist (and thus its first item), while navigating within it does not.
local function playlist_sig(items)
    if #items == 0 then return "" end
    return tostring(items[1].path or "")
end

-- Issue the jump from cur (at cur_idx) to target (at tgt_idx) and enter the
-- "resuming" phase so we wait for it to land before recording.
local function do_jump(target, cur_idx, tgt_idx)
    local skip = tgt_idx - cur_idx
    vlc.msg.info("resumejump: jumping to episode " .. tostring(target) .. " (skip " .. tostring(skip) .. ")")
    pcall(function() vlc.playlist.skip(skip) end)
    resume_target = target
    resume_wait = 0
    phase = "resuming"
end

-- On folder open, jump from whatever VLC auto-started to the resume target.
local function update_resume()
    local items = playlist_items()
    if #items < 2 then return end -- not a multi-item playlist / still loading

    local sig = playlist_sig(items)
    if sig ~= tracked_sig then
        tracked_sig = sig
        phase = "init"
        resume_target = nil
        resume_wait = 0
        init_count = -1
        init_stable = 0
    end

    if phase == "done" then return end

    local cur = current_uri()
    if not cur then return end -- nothing playing yet; wait

    if phase == "resuming" then
        if same_uri(cur, resume_target) then
            phase = "done"
        else
            resume_wait = resume_wait + 1
            if resume_wait > RESUME_GIVEUP_TICKS then
                phase = "done"
            end
        end
        return
    end

    -- phase == "init": resume to the global last-watched episode once it is in
    -- the playlist. The list loads incrementally (more so with --recursive=
    -- expand), so if it is not there yet we wait until the playlist stops
    -- growing before falling back, to avoid acting on a half-loaded list.
    local cur_idx = find_index(items, cur)
    if not cur_idx then return end -- current not locatable yet; wait

    local lw_idx = last_watched and find_index(items, last_watched) or nil
    if lw_idx then
        if same_uri(cur, last_watched) then
            phase = "done"
        else
            do_jump(last_watched, cur_idx, lw_idx)
        end
        return
    end

    -- Global last-watched not present (yet). Wait for the playlist to stop
    -- growing before concluding it is genuinely absent.
    if #items ~= init_count then
        init_count = #items
        init_stable = 0
        return
    end
    init_stable = init_stable + 1
    if init_stable < INIT_STABLE_TICKS then return end

    -- Loading has settled and last-watched is absent from this playlist: fall
    -- back to this directory's own last episode (or settle, allowing recording).
    local cur_dir = parent_dir(cur)
    local fb = cur_dir and session_state[cur_dir] or nil
    local fb_idx = fb and find_index(items, fb) or nil
    if fb_idx and not same_uri(cur, fb) then
        do_jump(fb, cur_idx, fb_idx)
    else
        phase = "done"
    end
end

-- Record the episode the user is actually watching so we can resume next time.
local function try_record()
    -- Suppress recording until the playlist has settled (see update_resume), so
    -- the transient item that plays during folder-open/jump can't clobber state.
    -- The #items guard also keeps standalone single-file playback out of state.
    if phase ~= "done" then return end
    if #playlist_items() < 2 then return end

    local uri = current_uri()
    if not uri then return end
    local dir = parent_dir(uri)
    if not dir then return end

    local changed = false
    if not same_uri(session_state[dir] or "", uri) then
        session_state[dir] = uri
        changed = true
    end
    if not same_uri(last_watched or "", uri) then
        last_watched = uri
        changed = true
    end
    if changed then
        save_state()
    end
end

-- main polling loop
while true do
    pcall(function()
        update_resume()
        try_record()
    end)
    pcall(function()
        vlc.misc.mwait(vlc.misc.mdate() + 1000000)
    end)
end

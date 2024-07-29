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

return {
  "mistricky/codesnap.nvim",
  lazy = false,
  build = "make",
  cmd = "CodeSnapPreviewOn",
  config = function()
    require("codesnap").setup({
      bg_color = "#535c68",
      watermark = "",
      has_line_number = false,
      mac_window_bar = false,
    })
  end,
}

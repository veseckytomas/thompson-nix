//   ________
//  /_  __/ /_  ____  ____ ___  ____  _________  ____
//   / / / __ \/ __ \/ __ `__ \/ __ \/ ___/ __ \/ __ \
//  / / / / / / /_/ / / / / / / /_/ (__  ) /_/ / / / /
// /_/ /_/ /_/\____/_/ /_/ /_/ .___/____/\____/_/ /_/
//                          /_/
// Tomáš Vesecký
// Email: vesecky@proton.me
// GitHub: veseckytomas
// GitLab: vesecky.tomas
import { Database } from "bun:sqlite";
import { existsSync } from "node:fs";
import os from "node:os";
import path from "node:path";
import { tool } from "@opencode-ai/plugin";

const z = tool.schema;

const description = `List opencode sessions across ALL projects/directories from the local opencode SQLite database (read-only).

Use when the agent needs to find or resume work done anywhere on the machine, not just in the current directory: "what sessions exist", "where did I work on X", "find the session about Y", "resume my earlier work elsewhere". opencode 1.18.34 has no server API for cross-project session listing, so this tool reads the local DB directly.

Each result row gives the last-updated time (UTC), session title, the session's absolute directory, the owning project worktree, and the session id. A full result for resuming work elsewhere = the absolute directory plus the session id.

opencode groups sessions by project, not by directory, so sibling git worktrees of one repo share a project and appear under several directories; directory/search filters therefore match the project worktree as well as the session directory, which is what makes them agree with "opencode session list".

Filtering: "search" matches (case-insensitively) against session titles and (case-sensitively) against the session directory and project worktree as a substring; "directory" filters by substring of either path; "includeArchived" and "includeSubsessions" are off by default; "limit" caps rows (default 30, max 200), newest-updated first, and the header always reports how many matched in total so truncation is visible.

Returns a markdown table, or a short message when the database is missing/empty or nothing matches the filters.`;

const args = {
  limit: z
    .number()
    .int()
    .min(1)
    .max(200)
    .optional()
    .describe("Maximum number of sessions to return (default 30, hard cap 200), newest-updated first"),
  search: z
    .string()
    .optional()
    .describe("Substring matched case-insensitively against the session title and case-sensitively against the directory path"),
  directory: z.string().optional().describe("Substring filter on the session's absolute directory path"),
  includeArchived: z.boolean().optional().describe("Include archived sessions (default false)"),
  includeSubsessions: z.boolean().optional().describe("Include subsessions (children of other sessions, default false)"),
};

const dbPath = process.env.OPENCODE_DB
  ? process.env.OPENCODE_DB
  : (process.env.XDG_DATA_HOME || path.join(os.homedir(), ".local", "share")) + "/opencode/opencode.db";

const escapeCell = (v) => String(v ?? "").replaceAll("|", "\\|").replace(/[\r\n]+/g, " ");

const truncateTitle = (title) => (title.length > 80 ? title.slice(0, 80) + "…" : title);

export const SessionListAllPlugin = async ({ client, project, directory, worktree, serverUrl, $ }) => ({
  tool: {
    session_list_all: tool({
      description,
      args,
      execute: async (args, context) => {
        if (!existsSync(dbPath)) {
          return `No opencode database at ${dbPath}; opencode has no sessions recorded yet.`;
        }

        const limit = Math.min(Math.max(Number(args.limit) || 30, 1), 200);
        const includeArchived = args.includeArchived ?? false;
        const includeSubsessions = args.includeSubsessions ?? false;

        let db;
        try {
          // Same-process DB owner also holds the writer; a fresh readonly connection per call sees the latest committed WAL state and can never wedge the writer.
          db = new Database(dbPath, { readonly: true });
        } catch (err) {
          return `failed to open opencode database at ${dbPath}: ${err.message}`;
        }

        let rows;
        let total = 0;
        try {
          const clauses = [];
          const params = [];
          if (!includeArchived) clauses.push("s.time_archived IS NULL");
          if (!includeSubsessions) clauses.push("s.parent_id IS NULL");
          // opencode scopes sessions by project, so a path is resolved to its project(s) and every session there matches - sibling worktrees share one project and would otherwise be invisible.
          const pathScope = `(instr(s.directory, ?) > 0 OR instr(ifnull(p.worktree, ''), ?) > 0 OR s.project_id IN (SELECT s2.project_id FROM "session" s2 LEFT JOIN project p2 ON p2.id = s2.project_id WHERE instr(s2.directory, ?) > 0 OR instr(ifnull(p2.worktree, ''), ?) > 0))`;
          if (args.directory) {
            clauses.push(pathScope);
            params.push(args.directory, args.directory, args.directory, args.directory);
          }
          if (args.search) {
            clauses.push(`(instr(lower(s.title), lower(?)) > 0 OR ${pathScope})`);
            params.push(args.search, args.search, args.search, args.search, args.search);
          }

          const from = `FROM "session" s LEFT JOIN project p ON p.id = s.project_id`;
          const where = clauses.length ? " WHERE " + clauses.join(" AND ") : "";
          total = db.prepare(`SELECT COUNT(*) AS n ${from}${where}`).get(...params).n;

          const query = `SELECT s.id, s.slug, s.title, s.directory, s.time_created, s.time_updated, s.summary_additions, s.summary_deletions, p.worktree AS project_worktree, p.name AS project_name
${from}${where} ORDER BY s.time_updated DESC LIMIT ?`;
          rows = db.prepare(query).all(...params, limit);
        } finally {
          db.close();
        }

        if (rows.length === 0) {
          const activeFilters = [
            args.search && `search=${JSON.stringify(args.search)}`,
            args.directory && `directory=${JSON.stringify(args.directory)}`,
            includeArchived ? "archived included" : "archived excluded",
            includeSubsessions ? "subsessions included" : "subsessions excluded",
          ].filter(Boolean);
          return `No sessions found${activeFilters.length ? " (filters: " + activeFilters.join(", ") + ")" : ""}.`;
        }

        const directoryCount = new Set(rows.map((r) => r.directory)).size;
        const hidden = total - rows.length;
        const lines = [
          `Found ${total} session(s) across ${directoryCount} distinct directories — showing latest ${rows.length} (UTC timestamps).${hidden > 0 ? ` ${hidden} more match; raise "limit" (max 200) to see them.` : ""}`,
          "",
          "| Updated | Title | Directory | Project worktree | ID |",
          "| --- | --- | --- | --- | --- |",
        ];
        for (const row of rows) {
          const updated = new Date(row.time_updated).toISOString().slice(0, 16).replace("T", " ");
          const title = escapeCell(truncateTitle(String(row.title ?? "")));
          const dir = escapeCell(row.directory);
          const worktree = escapeCell(row.project_worktree === row.directory ? "=" : (row.project_worktree ?? "—"));
          const id = escapeCell(row.id);
          lines.push(`| ${updated} | ${title} | ${dir} | ${worktree} | ${id} |`);
        }
        return lines.join("\n");
      },
    }),
  },
});

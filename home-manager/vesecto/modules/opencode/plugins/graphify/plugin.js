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
// graphify opencode plugin: nudge toward the targeted graphify MCP tools before grepping when a graph exists.
import { existsSync } from "fs";
import { join } from "path";

export const GraphifyPlugin = async ({ directory }) => {
  const remindedSessions = new Set();

  return {
    "tool.execute.before": async (input, output) => {
      if (remindedSessions.has(input.sessionID)) return;
      if (!existsSync(join(directory, "graphify-out", "graph.json"))) return;

      if (input.tool === "bash") {
        // Must agree with the graphify block in AGENTS.md; a banner advertising prose
        // `graphify query` would contradict it and provoke the costly call it avoids.
        // Reminder must stay backtick/$()-free: the hook echoes it via bash, which would execute them.
        // ';' not '&&': Windows PowerShell 5.1 rejects '&&' as a statement separator (#1646).
        output.args.command =
          'echo "[graphify] knowledge graph at graphify-out/. Prefer the graphify MCP tools over grepping raw files, narrowest first: GetNode/GetNeighbors for a known label, ShortestPath for two nodes, GraphStats/GodNodes/GetCommunity to orient, QueryGraph only for open-ended exploration. Matching is lexical, so name the exact indexed label. Read GRAPH_REPORT.md only for whole-repo review." ; ' +
          output.args.command;
        remindedSessions.add(input.sessionID);
      }
    },
  };
};

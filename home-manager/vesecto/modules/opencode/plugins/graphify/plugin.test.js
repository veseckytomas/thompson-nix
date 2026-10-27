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
import assert from "node:assert/strict";
import { mkdirSync, mkdtempSync, rmSync, writeFileSync } from "node:fs";
import { tmpdir } from "node:os";
import { join } from "node:path";
import test from "node:test";

import { GraphifyPlugin } from "./plugin.js";

const bannerPrefix = 'echo "[graphify] knowledge graph at graphify-out/.';

const invoke = async (hook, tool, sessionID, command = "pwd") => {
  const output = { args: { command } };
  await hook({ tool, sessionID, callID: `${sessionID}-${tool}` }, output);
  return output.args.command;
};

const withProject = async (hasGraph, run) => {
  const directory = mkdtempSync(join(tmpdir(), "graphify-plugin-test-"));
  try {
    if (hasGraph) {
      mkdirSync(join(directory, "graphify-out"));
      writeFileSync(join(directory, "graphify-out", "graph.json"), "{}");
    }
    await run(directory);
  } finally {
    rmSync(directory, { recursive: true, force: true });
  }
};

test("adds the banner once per session when a graph exists", async () => {
  await withProject(true, async (directory) => {
    const plugin = await GraphifyPlugin({ directory });
    const hook = plugin["tool.execute.before"];

    const first = await invoke(hook, "bash", "session-a");
    const repeated = await invoke(hook, "bash", "session-a");
    const otherSession = await invoke(hook, "bash", "session-b");

    assert.equal(first.startsWith(bannerPrefix), true);
    assert.equal(repeated, "pwd");
    assert.equal(otherSession.startsWith(bannerPrefix), true);
  });
});

test("does not add the banner to non-bash tools", async () => {
  await withProject(true, async (directory) => {
    const plugin = await GraphifyPlugin({ directory });

    const command = await invoke(plugin["tool.execute.before"], "read", "session-a");

    assert.equal(command, "pwd");
  });
});

test("does not add the banner when the graph is absent", async () => {
  await withProject(false, async (directory) => {
    const plugin = await GraphifyPlugin({ directory });

    const command = await invoke(plugin["tool.execute.before"], "bash", "session-a");

    assert.equal(command, "pwd");
  });
});

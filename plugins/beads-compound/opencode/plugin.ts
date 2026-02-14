/**
 * beads-compound plugin for OpenCode
 *
 * Ports auto-recall.sh and memory-capture.sh hooks to OpenCode's event system.
 * Subagent wrapup is handled separately via tool.execute.after with tool=task filter.
 */

import type { Plugin } from "@opencode-ai/plugin";
import { resolve } from "node:path";

export default {
  // Set CLAUDE_PROJECT_DIR globally for all bd commands
  "shell.env": async ({ directory }) => {
    // Validate that directory is an absolute path (security)
    if (!directory || !resolve(directory).startsWith("/")) {
      return {};
    }

    return {
      CLAUDE_PROJECT_DIR: directory,
    };
  },

  // Auto-recall: inject relevant knowledge at session start
  "session.created": async ({ directory }) => {
    // Validate absolute path (security)
    if (!directory || !resolve(directory).startsWith("/")) {
      return;
    }

    const hookScript = resolve(
      import.meta.dir,
      "../hooks/auto-recall.sh"
    );

    const proc = Bun.spawn(["bash", hookScript], {
      env: {
        ...process.env,
        CLAUDE_PROJECT_DIR: directory,
      },
      stdout: "pipe",
      stderr: "pipe",
    });

    const stdout = await new Response(proc.stdout).text();
    const stderr = await new Response(proc.stderr).text();

    if (stderr) {
      console.error("[beads-compound] auto-recall error:", stderr);
    }

    // Parse JSON output
    try {
      const output = JSON.parse(stdout);
      if (output.hookSpecificOutput?.systemMessage) {
        return {
          systemMessage: output.hookSpecificOutput.systemMessage,
        };
      }
    } catch (err) {
      // Not JSON or parse error - no output to inject
    }

    return;
  },

  // Memory capture: extract knowledge from bd comments add commands
  "tool.execute.after": async ({ tool, input, directory }) => {
    // Pre-filter: only process bash commands (performance optimization)
    if (tool !== "bash") {
      return;
    }

    const command = input?.command;
    if (!command || typeof command !== "string") {
      return;
    }

    // Pre-filter: check for bd comments pattern before spawning subprocess
    // This is a hot path - 95% of bash commands are not bd comments
    if (!command.match(/bd\s+comments?\s+add\s+/)) {
      return;
    }

    // Pre-filter: check for knowledge prefixes
    if (!command.match(/(INVESTIGATION:|LEARNED:|DECISION:|FACT:|PATTERN:)/)) {
      return;
    }

    // Validate directory path (security)
    if (!directory || !resolve(directory).startsWith("/")) {
      return;
    }

    // Construct stdin payload in Claude Code format
    const stdinPayload = JSON.stringify({
      tool_name: "Bash",
      tool_input: {
        command: command,
      },
      cwd: directory,
    });

    const hookScript = resolve(
      import.meta.dir,
      "../hooks/memory-capture.sh"
    );

    // Use Bun.spawn() with stdin piping (security: prevents shell injection)
    const proc = Bun.spawn(["bash", hookScript], {
      env: {
        ...process.env,
        CLAUDE_PROJECT_DIR: directory,
      },
      stdin: "pipe",
      stdout: "pipe",
      stderr: "pipe",
    });

    // Write stdin payload
    const writer = proc.stdin.getWriter();
    await writer.write(new TextEncoder().encode(stdinPayload));
    await writer.close();

    const stderr = await new Response(proc.stderr).text();
    if (stderr) {
      console.error("[beads-compound] memory-capture error:", stderr);
    }

    return;
  },
} satisfies Plugin;

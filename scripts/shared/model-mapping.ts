/**
 * Model tier mapping across platforms
 * Preserves cost/quality tiers (haiku/sonnet/opus) while using platform-native models
 */

import { readFileSync } from "node:fs";
import { join } from "node:path";

// Load model configuration from file
let modelConfig: any;
try {
  const configPath = join(import.meta.dir, "model-config.json");
  modelConfig = JSON.parse(readFileSync(configPath, "utf-8"));
} catch {
  // Fallback to defaults if config file doesn't exist
  modelConfig = {
    opencode: {
      haiku: "anthropic/claude-haiku-4-5-20251001",
      sonnet: "anthropic/claude-sonnet-4-5-20250929",
      opus: "anthropic/claude-opus-4-6",
    },
    gemini: {
      haiku: "gemini-2.5-flash",
      sonnet: "gemini-2.5-pro",
      opus: "gemini-2.5-pro",
    },
  };
}

export const MODEL_TIERS = {
  claude: {
    haiku: "haiku",
    sonnet: "sonnet",
    opus: "opus",
    inherit: "inherit",
  },
  opencode: {
    haiku: modelConfig.opencode.haiku,
    sonnet: modelConfig.opencode.sonnet,
    opus: modelConfig.opencode.opus,
    inherit: "inherit",
  },
  gemini: {
    haiku: modelConfig.gemini.haiku,
    sonnet: modelConfig.gemini.sonnet,
    opus: modelConfig.gemini.opus, // Gemini has no equivalent to Opus, use Pro
    inherit: "inherit",
  },
} as const;

/**
 * Maps a Claude Code model tier to OpenCode model ID
 */
export function mapToOpenCode(claudeModel: string): string {
  const model = claudeModel.toLowerCase();

  // If already a full model ID, validate and return
  if (model.includes("/") || model.includes("-")) {
    return claudeModel;
  }

  // Map tier to OpenCode model ID
  const tier = model as keyof typeof MODEL_TIERS.opencode;
  if (tier in MODEL_TIERS.opencode) {
    return MODEL_TIERS.opencode[tier];
  }

  // Default to inherit if unknown
  return "inherit";
}

/**
 * Maps a Claude Code model tier to Gemini model ID
 */
export function mapToGemini(claudeModel: string): string {
  const model = claudeModel.toLowerCase();

  // If it's "inherit", keep it
  if (model === "inherit") {
    return "inherit";
  }

  // If already a Gemini model, return as-is
  if (model.startsWith("gemini-")) {
    return claudeModel;
  }

  // Map tier to Gemini model ID
  const tier = model as keyof typeof MODEL_TIERS.gemini;
  if (tier in MODEL_TIERS.gemini) {
    return MODEL_TIERS.gemini[tier];
  }

  // Default to gemini-2.5-pro if unknown
  return "gemini-2.5-pro";
}

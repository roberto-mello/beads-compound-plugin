import { load as yamlLoad, dump as yamlDump } from "js-yaml";

/**
 * Safely parses YAML frontmatter from markdown content
 * Uses SAFE_SCHEMA to prevent code execution via malicious YAML
 */
export function parseFrontmatter(content: string): Record<string, any> {
  const match = content.match(/^---\n([\s\S]+?)\n---/);
  if (!match) {
    return {};
  }

  try {
    // Use CORE_SCHEMA (safer than DEFAULT_SCHEMA, blocks !!python/object etc)
    const parsed = yamlLoad(match[1], {
      schema: yamlLoad.CORE_SCHEMA,
      json: true, // Only allow JSON-compatible subset
    });

    if (typeof parsed !== "object" || parsed === null || Array.isArray(parsed)) {
      throw new Error("Invalid frontmatter structure - must be object");
    }

    return parsed as Record<string, any>;
  } catch (err: any) {
    throw new Error(`Frontmatter parse error: ${err.message}`);
  }
}

/**
 * Extracts body content (everything after frontmatter)
 */
export function extractBody(content: string): string {
  const match = content.match(/^---\n[\s\S]+?\n---\n([\s\S]*)$/);
  return match ? match[1] : content;
}

/**
 * Safely stringifies frontmatter to YAML
 */
export function stringifyFrontmatter(obj: Record<string, any>): string {
  return yamlDump(obj, {
    schema: yamlDump.CORE_SCHEMA,
    noRefs: true, // Prevent circular references
    lineWidth: -1, // Don't wrap lines
  });
}

/**
 * Reconstructs markdown file with frontmatter
 */
export function buildMarkdown(frontmatter: Record<string, any>, body: string): string {
  const yaml = stringifyFrontmatter(frontmatter).trim();
  return `---\n${yaml}\n---\n${body}`;
}

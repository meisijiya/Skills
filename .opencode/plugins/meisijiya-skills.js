#!/usr/bin/env node
/**
 * meisijiya-skills OpenCode plugin
 *
 * Hard-injects meisijiya-skills bootstrap context (using-meisijiya-skills/SKILL.md)
 * into the first user message of every session, and registers the skills
 * directory so OpenCode's native skill tool can list them.
 *
 * Pattern adapted from obra/superpowers (Jesse Vincent):
 * https://github.com/obra/superpowers/blob/main/.opencode/plugins/superpowers.js
 *
 * SDK reference (verified 2026-07):
 *   - Hooks interface: https://raw.githubusercontent.com/anomalyco/opencode/dev/packages/plugin/src/index.ts
 *   - Config.skills.paths schema: https://raw.githubusercontent.com/anomalyco/opencode/dev/packages/core/src/v1/config/skills.ts
 *   - Runtime skill discovery: packages/opencode/src/skill/index.ts#L197
 *
 * Critical gotcha: must mutate in-place (issue #25754) — reassigning
 * `output.messages = newArr` is a silent no-op. This file mutates
 * `firstUser.parts` in place via `unshift`, which is safe.
 *
 * Install:
 *   mkdir -p ~/.config/opencode/plugins
 *   ln -sf <repo>/.opencode/plugins/meisijiya-skills.js \
 *          ~/.config/opencode/plugins/meisijiya-skills.js
 *
 * Disable (symlink only):
 *   rm ~/.config/opencode/plugins/meisijiya-skills.js
 */

import path from 'path';
import fs from 'fs';
import os from 'os';

const EXTREMELY_IMPORTANT_MARKER = 'EXTREMELY_IMPORTANT';

// Module-level cache: bootstrap file does not change during a session.
// See superpowers.js for the same pattern (avoids redundant disk reads per step).
let _bootstrapCache = undefined; // undefined = not yet loaded, null = file missing

/**
 * Strip simple YAML frontmatter from a SKILL.md.
 * Only handles the format OpenCode skills emit: `key: value` lines,
 * no nested objects. Returns the body content.
 */
function stripFrontmatter(content) {
  const match = content.match(/^---\n([\s\S]*?)\n---\n([\s\S]*)$/);
  return match ? match[2] : content;
}

/**
 * Load + cache the bootstrap content from `~/.agents/skills/using-meisijiya-skills/SKILL.md`,
 * stripped of frontmatter and wrapped in <EXTREMELY_IMPORTANT> tags.
 *
 * Returns null if the file does not exist or cannot be read — in which case the
 * plugin degrades silently (OpenCode will still run, just without the bootstrap).
 */
function loadBootstrap() {
  if (_bootstrapCache !== undefined) return _bootstrapCache;

  const bootstrapPath = path.join(
    os.homedir(), '.agents', 'skills',
    'using-meisijiya-skills', 'SKILL.md'
  );

  try {
    if (!fs.existsSync(bootstrapPath)) {
      _bootstrapCache = null;
      return null;
    }
    const fullContent = fs.readFileSync(bootstrapPath, 'utf8');
    const body = stripFrontmatter(fullContent);

    _bootstrapCache = `<${EXTREMELY_IMPORTANT_MARKER}>
You have meisijiya-skills.

**IMPORTANT: The using-meisijiya-skills skill content is included below. It is ALREADY LOADED - you are currently following it. Do NOT use the skill tool to load "using-meisijiya-skills" again - that would be redundant.**

${body}
</${EXTREMELY_IMPORTANT_MARKER}>`;
    return _bootstrapCache;
  } catch (e) {
    _bootstrapCache = null;
    return null;
  }
}

export const MeisijiyaSkillsPlugin = async ({ client, directory }) => {
  const skillsDir = path.join(os.homedir(), '.agents', 'skills');

  return {
    /**
     * Register the meisijiya-skills directory with OpenCode's native skill tool
     * so it can discover + list + invoke installed skills.
     * Equivalent to a global `npx skills add`; doesn't require symlinks.
     */
    config: async (config) => {
      config.skills = config.skills || {};
      config.skills.paths = config.skills.paths || [];
      if (!config.skills.paths.includes(skillsDir)) {
        config.skills.paths.push(skillsDir);
      }
    },

    /**
     * Inject the bootstrap into the first user message of every session.
     *
     * Why only first:
     *   - Bootstrap is "intro to using skills" — redundant after first turn.
     *   - Issue #750: system messages get repeated every turn, bloating tokens.
     *   - We use a user message (unshift) to avoid that and to keep cache locality.
     *
     * Idempotency: this hook fires on every agent step (OpenCode reloads messages
     * from DB each step, see superpowers.js comment block). We guard against
     * double-injection by checking for the EXTREMELY_IMPORTANT marker.
     * This is also what makes us safely re-inject after session compaction.
     */
    'experimental.chat.messages.transform': async (_input, output) => {
      const bootstrap = loadBootstrap();
      if (!bootstrap || !output.messages.length) return;

      const firstUser = output.messages.find((m) => m.info.role === 'user');
      if (!firstUser || !firstUser.parts.length) return;

      // Guard: skip if bootstrap already present (idempotent for compaction + retries)
      if (firstUser.parts.some(
        (p) => p.type === 'text' && p.text.includes(EXTREMELY_IMPORTANT_MARKER)
      )) {
        return;
      }

      // In-place mutation on firstUser.parts. Reassigning parts would be a no-op
      // (OpenCode retains the original array reference; see issue #25754).
      const ref = firstUser.parts[0];
      firstUser.parts.unshift({ ...ref, type: 'text', text: bootstrap });
    },
  };
};

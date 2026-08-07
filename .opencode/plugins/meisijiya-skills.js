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
 * Skill discovery (T0.1 verified): OpenCode hook input does not expose
 * `availableSkills`, but `client.skill.list({ query: { directory } })` is a
 * working runtime API returning SkillV2Info[] (name/description/slash/location/
 * content). We call it once per process, cache module-level, and fall back to a
 * filesystem scan of ~/.agents/skills when the API call fails or returns empty.
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

// Module-level caches: bootstrap file and skill list do not change during a session.
// See superpowers.js for the same pattern (avoids redundant disk reads per step).
let _bootstrapCache = undefined; // undefined = not yet loaded, null = file missing
let _skillCache = null;          // null = not yet loaded / failed, array = SkillV2Info[] or FS-scan items

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

/**
 * FS fallback: scan ~/.agents/skills for directories containing SKILL.md.
 * Used when the runtime API call fails or returns empty.
 * Returns items shaped like SkillV2Info ({ name, location }).
 */
function scanSkillsDir() {
  const dir = path.join(os.homedir(), '.agents', 'skills');
  try {
    return fs.readdirSync(dir, { withFileTypes: true })
      .filter((e) => e.isDirectory() && fs.existsSync(path.join(dir, e.name, 'SKILL.md')))
      .map((e) => ({ name: e.name, location: path.join(dir, e.name) }));
  } catch (e) {
    return [];
  }
}

/**
 * Load + cache the installed skill list.
 * Primary: OpenCode runtime API `client.skill.list` (T0.1 verified).
 * Fallback: FS scan of ~/.agents/skills (the pre-T1.2 path).
 * Never throws — failures degrade silently to the FS scan.
 */
async function loadSkillCache(client, directory) {
  if (_skillCache !== null) return _skillCache;

  try {
    const skills = await client.skill.list({ query: { directory } });
    if (Array.isArray(skills) && skills.length > 0) {
      _skillCache = skills;
      return _skillCache;
    }
  } catch (e) {
    // silent degrade: fall through to FS scan
  }

  _skillCache = scanSkillsDir();
  return _skillCache;
}

export const MeisijiyaSkillsPlugin = async (ctx) => {
  const { client, directory } = ctx || {};
  const skillsDir = path.join(os.homedir(), '.agents', 'skills');

  // One runtime discovery call per process, cached module-level.
  // Failures (no client / API error / empty result) fall back to the FS scan.
  try {
    await loadSkillCache(client, directory);
  } catch (e) {
    // never throw out of the plugin factory
  }

  return {
    /**
     * Register the meisijiya-skills directories with OpenCode's native skill tool
     * so it can discover + list + invoke installed skills.
     * Equivalent to a global `npx skills add`; doesn't require symlinks.
     */
    config: async (config) => {
      config.skills = config.skills || {};
      config.skills.paths = config.skills.paths || [];

      // Always register the home skills dir (pre-T1.2 behavior), plus any
      // locations discovered via the runtime API / FS scan (deduped).
      const paths = new Set([skillsDir]);
      if (Array.isArray(_skillCache)) {
        for (const s of _skillCache) {
          if (s && typeof s.location === 'string' && s.location) paths.add(s.location);
        }
      }
      for (const p of paths) {
        if (!config.skills.paths.includes(p)) config.skills.paths.push(p);
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
      if (!bootstrap) return;
      if (!output.messages.length) return;

      const firstUser = output.messages.find((m) => m.info.role === 'user');
      if (!firstUser) return;
      if (!firstUser.parts.length) return;

      // Guard: skip if bootstrap already present (idempotent for compaction + retries)
      if (firstUser.parts.some(
        (p) => p.type === 'text' && p.text.includes(EXTREMELY_IMPORTANT_MARKER)
      )) {
        return;
      }

      // In-place mutation on firstUser.parts. Reassigning parts would be a no-op
      // (OpenCode retains the original array reference; see issue #25754).
      firstUser.parts.unshift({ type: 'text', text: bootstrap });
    },
  };
};

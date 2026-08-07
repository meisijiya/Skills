#!/usr/bin/env node
/**
 * meisijiya-dispatch-gate — OpenCode plugin
 *
 * Hard-layer fallback for `task(load_skills=[...])` dispatch. When the controller
 * (Sisyphus) forgets or omits the COMPLETE load_skills list per the Category × Skill
 * Matrix main table (defined in `using-meisijiya-skills/references/category-matrix.md`), this plugin:
 *
 *   1. Empty/undefined load_skills + matching category → inject matrix recommendation
 *      (filtered by installed() so omo resolveSkillContent does not hard-fail on notFound)
 *   2. Non-empty load_skills → respect LLM (do NOT merge); console.warn with matrix hint
 *      so the LLM can fix on next dispatch
 *
 * Sync with: skills/core/using-meisijiya-skills/references/category-matrix.md
 * (formerly SKILL.md §Category × Skill Matrix; SOT — this file mirrors the matrix).
 * When the matrix changes, update RECOMMENDED.
 *
 * Coverage scope: only matrix rows with an unconditional Main bundle are injected
 * (visual-engineering → meisijiya-frontend-taste, deep → incremental-implementation).
 * Rows the matrix maps to `[]` (quick / unspecified-low / artistry) or that are
 * conditional / multi-option (ultrabrain "pick 1 of 3", unspecified-high "bug hunt vs
 * skill creation", writing "verify-chain if fact-checking") are mapped to [] — the
 * plugin no-ops and leaves them LLM-only, matching the matrix's "pick 1" / "if" /
 * "rarely needed" semantics. Injecting a wrong skill is worse than not injecting
 * (per spec D3 + risk matrix row "ultrabrain / unspecified-high 行歧义").
 *
 * Pattern adapted from omo-state-index.js: pure Node stdlib, mutate in place, never
 * throw out of a hook (wrap entire body in try/catch).
 *
 * Spec: docs/meisijiya-dispatch-gate-design-spec.md §4.2
 */
'use strict';

const { existsSync } = require('node:fs');
const { join } = require('node:path');
const { homedir } = require('node:os');

const SKILLS_DIR = join(homedir(), '.agents', 'skills');

// SOT = skills/core/using-meisijiya-skills/references/category-matrix.md §Category × Skill
// Matrix main table. Every matrix row is mirrored here row-by-row:
//   - unconditional Main rows → skill array (plugin injects on empty load_skills)
//   - `[]` rows (quick / unspecified-low / artistry) → [] (plugin no-ops)
//   - conditional / pick-1 rows (ultrabrain / unspecified-high / writing) → [] (LLM-only)
// A [] mapping must stay behaviorally identical to absence: resolver returns null for both.
const RECOMMENDED = Object.freeze({
  'visual-engineering': ['meisijiya-frontend-taste'], // matrix Main; +minimalist-ui / →redesign-ui are brief-conditioned → LLM-only
  'ultrabrain':          [],                           // matrix "pick 1 of 3" — hook cannot disambiguate → LLM-only
  'deep':                ['incremental-implementation'], // matrix Main; +test-driven-development only when TDD-required → LLM-only
  'quick':               [],                           // matrix → [] (no skills)
  'unspecified-low':     [],                           // matrix → [] default; prototype only on [PROTO-RESOLVE] → LLM-only
  'unspecified-high':    [],                           // matrix "bug hunts vs skill creation" — 2-way ambiguity → LLM-only
  'writing':             [],                           // matrix "verify-chain if fact-checking" — conditional → LLM-only
  'artistry':            [],                           // matrix "(rarely needed)"
});

/** Returns true iff `~/.agents/skills/<name>/SKILL.md` exists on disk. */
function installed(name) {
  return existsSync(join(SKILLS_DIR, name, 'SKILL.md'));
}

/**
 * Pure resolver. Returns the recommended `load_skills` set (filtered by installed) for
 * the given tool-args, or null if no recommendation applies (caller should no-op).
 *
 * Exported for unit testing (see tests/plugins/meisijiya-dispatch-gate.test.js).
 */
function resolveDispatchLoadSkills(args) {
  const routing = (typeof args?.category === 'string' && args.category)
    || (typeof args?.subagent_type === 'string' && args.subagent_type);
  if (!routing) return null;
  const rec = RECOMMENDED[routing];
  if (!rec) return null;
  const filtered = rec.filter(installed);
  return filtered.length > 0 ? filtered : null;
}

/**
 * OpenCode plugin entry point. Returns a hooks map.
 *
 * Reference identity contract: when mutation occurs we mutate `output.args.load_skills`
 * in place — we never reassign `output.args` itself (SDK retains the original reference;
 * reassigning is a silent no-op, see OpenCode issue #25754, mirrored in meisijiya-skills.js
 * comment block).
 */
const MeisijiyaDispatchGate = async () => ({
  'tool.execute.before': async (input, output) => {
    try {
      if (String(input?.tool ?? '').toLowerCase() !== 'task') return;
      const args = output?.args;
      if (!args || typeof args !== 'object') return;

      const recommended = resolveDispatchLoadSkills(args);
      const existing = Array.isArray(args.load_skills) ? args.load_skills : null;

      if (existing && existing.length > 0) {
        // Respect LLM: do NOT merge. console.warn so LLM can fix on next dispatch.
        if (recommended && recommended.length > 0) {
          console.warn(
            '[meisijiya-dispatch-gate] load_skills already set; matrix recommends',
            JSON.stringify(recommended),
          );
        }
        return;
      }

      if (recommended && recommended.length > 0) {
        // Inject (user decision: only when fully empty/undefined).
        // cap(0, 4) — accommodates Security 5-lane 4-skill sets without silent drop.
        args.load_skills = recommended.slice(0, 4);
        console.warn('[meisijiya-dispatch-gate] injected', JSON.stringify(recommended));
      }
      // No recommendation / no axis → no-op (natural fallback)
    } catch (_e) {
      // Per omo-state-index.js discipline: never throw out of a tool hook.
    }
  },
});

// Test surface (per omo-state-index.js:344-358 pattern): pure functions + plugin factory.
// Keep this last so all bindings are visible above.
module.exports = { resolveDispatchLoadSkills, RECOMMENDED, installed, MeisijiyaDispatchGate };

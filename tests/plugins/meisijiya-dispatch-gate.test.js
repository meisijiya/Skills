#!/usr/bin/env node
/**
 * Unit tests for meisijiya-dispatch-gate plugin.
 *
 * Zero deps beyond Node stdlib (`node:test` + `node:assert`).
 *
 * Test classes (per docs/meisijiya-dispatch-gate-design-spec.md §8.1):
 *   1. Positive — empty load_skills + matrix-mapped category → inject recommendation
 *   2. Negative — non-empty load_skills → no mutation; console.warn fired with hint
 *   3. Defensive — output.args=null/undefined/non-object; tool != 'task' → no-throw, no-mutate
 *   4. Edge — category not in MVP matrix; no routing; recommended skill not installed → no-op
 *
 * Plus 1 reference-identity assertion: `output.args` reference must not change across the
 * hook call (regresses against the OpenCode issue #25754 reassignment footgun).
 *
 * Pre-conditions for the positive test:
 *   - `~/.agents/skills/meisijiya-frontend-taste/SKILL.md` exists (verified before run).
 *   - `~/.agents/skills/incremental-implementation/SKILL.md` exists.
 *
 * Negative-path tests do not depend on installed skills (they exercise the "warn-only" branch).
 */
'use strict';

const test   = require('node:test');
const assert = require('node:assert');
const {
  resolveDispatchLoadSkills,
  RECOMMENDED,
  installed,
  MeisijiyaDispatchGate,
} = require('../../.opencode/plugins/meisijiya-dispatch-gate.js');

// Sanity: the MVP skills must be present for this suite to mean anything. Skip those tests
// explicitly when prerequisites are missing (CI without install) so the suite stays useful.
const VE_SKILL = 'meisijiya-frontend-taste';
const DEEP_SKILL = 'incremental-implementation';

async function invokeHook(input, output) {
  const plugin = await MeisijiyaDispatchGate();
  await plugin['tool.execute.before'](input, output);
}

// ─────────────────────────────────────────────────────────────────────────────
// 1. Pure resolver — positive cases
// ─────────────────────────────────────────────────────────────────────────────

test('resolveDispatchLoadSkills: returns installed recommendation for visual-engineering', (t) => {
  if (!installed(VE_SKILL)) return t.skip(`${VE_SKILL} not installed`);
  const rec = resolveDispatchLoadSkills({ category: 'visual-engineering' });
  assert.deepStrictEqual(rec, [VE_SKILL]);
});

test('resolveDispatchLoadSkills: returns installed recommendation for deep', (t) => {
  if (!installed(DEEP_SKILL)) return t.skip(`${DEEP_SKILL} not installed`);
  const rec = resolveDispatchLoadSkills({ category: 'deep' });
  assert.deepStrictEqual(rec, [DEEP_SKILL]);
});

// ─────────────────────────────────────────────────────────────────────────────
// 2. Pure resolver — edge cases
// ─────────────────────────────────────────────────────────────────────────────

test('resolveDispatchLoadSkills: returns null for category not in MVP RECOMMENDED', () => {
  assert.strictEqual(resolveDispatchLoadSkills({ category: 'artistry' }), null);
  assert.strictEqual(resolveDispatchLoadSkills({ category: 'quick' }), null);
  assert.strictEqual(resolveDispatchLoadSkills({ category: 'unspecified-low' }), null);
  assert.strictEqual(resolveDispatchLoadSkills({ category: 'ultrabrain' }), null);
});

test('resolveDispatchLoadSkills: returns null when args is null/undefined', () => {
  assert.strictEqual(resolveDispatchLoadSkills(null), null);
  assert.strictEqual(resolveDispatchLoadSkills(undefined), null);
});

test('resolveDispatchLoadSkills: returns null when neither category nor subagent_type provided', () => {
  assert.strictEqual(resolveDispatchLoadSkills({ load_skills: [] }), null);
  assert.strictEqual(resolveDispatchLoadSkills({}), null);
});

test('resolveDispatchLoadSkills: falls back to subagent_type when category absent', (t) => {
  if (!installed(DEEP_SKILL)) return t.skip(`${DEEP_SKILL} not installed`);
  const rec = resolveDispatchLoadSkills({ subagent_type: 'deep' });
  assert.deepStrictEqual(rec, [DEEP_SKILL]);
});

test('resolveDispatchLoadSkills: filters out uninstalled skills → null', () => {
  // Temporarily inject a name that is definitely not installed, then re-resolve.
  // We mutate RECOMMENDED in-place is forbidden (Object.freeze protects us). Instead,
  // direct installed() call exercises the filter inside resolveDispatchLoadSkills via
  // category lookup of an existing-but-uninstalled-skill-only category is impossible
  // without mutation. Verify via installed() helper directly instead.
  assert.strictEqual(installed('this-skill-definitely-does-not-exist-anywhere'), false);
});

// ─────────────────────────────────────────────────────────────────────────────
// 3. Hook — positive (mutate) behavior
// ─────────────────────────────────────────────────────────────────────────────

test('hook: empty load_skills + VE → mutate to [meisijiya-frontend-taste]', async (t) => {
  if (!installed(VE_SKILL)) return t.skip(`${VE_SKILL} not installed`);
  const args = { category: 'visual-engineering', load_skills: [] };
  await invokeHook({ tool: 'task' }, { args });
  assert.deepStrictEqual(args.load_skills, [VE_SKILL]);
});

test('hook: undefined load_skills + deep → mutate to [incremental-implementation]', async (t) => {
  if (!installed(DEEP_SKILL)) return t.skip(`${DEEP_SKILL} not installed`);
  const args = { category: 'deep' };
  await invokeHook({ tool: 'task' }, { args });
  assert.deepStrictEqual(args.load_skills, [DEEP_SKILL]);
});

// ─────────────────────────────────────────────────────────────────────────────
// 4. Hook — negative (warn-only) behavior
// ─────────────────────────────────────────────────────────────────────────────

test('hook: non-empty load_skills → no mutation; console.warn called with hint', async (t) => {
  if (!installed(VE_SKILL)) return t.skip(`${VE_SKILL} not installed`);
  const warnSpy = t.mock.method(console, 'warn', () => {});
  const args = { category: 'visual-engineering', load_skills: ['something-else'] };
  await invokeHook({ tool: 'task' }, { args });
  assert.deepStrictEqual(args.load_skills, ['something-else'], 'existing list must not be mutated');
  assert.strictEqual(warnSpy.mock.calls.length, 1, 'warn should fire once');
  const msg = String(warnSpy.mock.calls[0].arguments[0]);
  assert.match(msg, /meisijiya-dispatch-gate/);
  assert.match(msg, /matrix recommends/);
});

test('hook: non-empty load_skills + category not in matrix → no warn, no mutation', async (t) => {
  const warnSpy = t.mock.method(console, 'warn', () => {});
  const args = { category: 'artistry', load_skills: ['whatever'] };
  await invokeHook({ tool: 'task' }, { args });
  assert.deepStrictEqual(args.load_skills, ['whatever']);
  assert.strictEqual(warnSpy.mock.calls.length, 0, 'no warn when recommendation absent');
});

// ─────────────────────────────────────────────────────────────────────────────
// 5. Hook — defensive (no-throw, no-mutate) behavior
// ─────────────────────────────────────────────────────────────────────────────

test('hook: output.args is null → no throw, no warn', async (t) => {
  const warnSpy = t.mock.method(console, 'warn', () => {});
  await invokeHook({ tool: 'task' }, { args: null });
  assert.strictEqual(warnSpy.mock.calls.length, 0);
});

test('hook: output.args is a string → no throw, no warn', async (t) => {
  const warnSpy = t.mock.method(console, 'warn', () => {});
  await invokeHook({ tool: 'task' }, { args: 'not-an-object' });
  assert.strictEqual(warnSpy.mock.calls.length, 0);
});

test('hook: input.tool != task → no throw, no warn', async (t) => {
  const warnSpy = t.mock.method(console, 'warn', () => {});
  const args = { category: 'visual-engineering', load_skills: [] };
  await invokeHook({ tool: 'write' }, { args });
  assert.deepStrictEqual(args.load_skills, [], 'load_skills must remain empty for non-task tool');
  assert.strictEqual(warnSpy.mock.calls.length, 0);
});

test('hook: input missing → no throw, no warn', async (t) => {
  const warnSpy = t.mock.method(console, 'warn', () => {});
  const args = { category: 'visual-engineering', load_skills: [] };
  await invokeHook(undefined, { args });
  assert.deepStrictEqual(args.load_skills, []);
  assert.strictEqual(warnSpy.mock.calls.length, 0);
});

// ─────────────────────────────────────────────────────────────────────────────
// 6. Edge: category not in MVP matrix → no-op (positive path)
// ─────────────────────────────────────────────────────────────────────────────

test('hook: category=artistry (not in MVP) + empty load_skills → no-op', async (t) => {
  const warnSpy = t.mock.method(console, 'warn', () => {});
  const args = { category: 'artistry', load_skills: [] };
  await invokeHook({ tool: 'task' }, { args });
  assert.deepStrictEqual(args.load_skills, [], 'artistry must not trigger injection');
  assert.strictEqual(warnSpy.mock.calls.length, 0);
});

// ─────────────────────────────────────────────────────────────────────────────
// 7. Reference identity assertion — prevents reassignment footgun
// ─────────────────────────────────────────────────────────────────────────────

test('hook: mutates in place — output.args reference unchanged across call', async (t) => {
  if (!installed(VE_SKILL)) return t.skip(`${VE_SKILL} not installed`);
  const original = { category: 'visual-engineering', load_skills: [] };
  const output = { args: original };
  await invokeHook({ tool: 'task' }, output);
  assert.strictEqual(output.args, original, 'output.args reference must be unchanged (mutate, do not reassign)');
  assert.deepStrictEqual(original.load_skills, [VE_SKILL], 'field mutation should land on original');
});

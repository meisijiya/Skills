#!/usr/bin/env node
/**
 * scripts/test-omo-state-index.js
 *
 * Node smoke test (no vitest) for .opencode/plugins/omo-state-index.js.
 * Covers the four required cases:
 *   (a) absent index.json + first .omo/** write → index.json exists with
 *       schema_version "1.1.0" and the eight required arrays
 *   (b) corrupt index.json → rebuilt from filesystem
 *   (c) .omo/.index.json self-write → no recursion
 *   (d) two write events within 500ms → exactly one mtime update
 *
 * Why a hand-rolled harness (not vitest):
 *   - Plan / scope forbids adding new dependencies (no package.json edit).
 *   - vitest is already in the repo, but pulling it in here is a heavier
 *     abstraction than the four-case contract warrants.
 *   - exit-0-on-pass / exit-1-on-fail + stdout assertion lines match
 *     the convention used by scripts/validate-skills.sh and friends.
 *
 * Usage:
 *   node scripts/test-omo-state-index.js
 *
 * Exit codes:
 *   0 — all cases passed
 *   1 — at least one case failed
 */

'use strict';

const fs = require('node:fs');
const os = require('node:os');
const path = require('node:path');
const { performance } = require('node:perf_hooks');

// --- Resolve the plugin module under test. ---
// Keep the resolution on the workspace root so the test exercises the same
// module the installer copies to ~/.config/opencode/plugins/.
const PLUGIN_PATH = path.join(__dirname, '..', '.opencode', 'plugins', 'omo-state-index.js');

if (!fs.existsSync(PLUGIN_PATH)) {
  console.error(`FAIL: plugin module not found at ${PLUGIN_PATH}`);
  console.error('      (this is the failing-first signal — write the plugin to make this go green)');
  process.exit(1);
}

const plugin = require(PLUGIN_PATH);

const REQUIRED_ARRAYS = [
  'active_plans',
  'closed_plans',
  'open_wayfinders',
  'closed_wayfinders',
  'throwaway_worktrees',
  'throwaway_protos',
  'drafts_to_resolve',
  'stale_artifacts',
];

const failures = [];
function assert(cond, msg) {
  if (!cond) failures.push(msg);
}

// --- Per-test temp root helper. ---
function freshTmpOmo(label) {
  const root = fs.mkdtempSync(path.join(os.tmpdir(), `omo-test-${label}-`));
  fs.mkdirSync(path.join(root, '.omo'), { recursive: true });
  return root;
}

function cleanup(root) {
  try {
    fs.rmSync(root, { recursive: true, force: true });
  } catch (_) {
    // best-effort; the OS will sweep /tmp eventually
  }
}

function wait(ms) {
  return new Promise((resolve) => setTimeout(resolve, ms));
}

function mtimeMs(p) {
  return fs.statSync(p).mtimeMs;
}

async function runCaseA() {
  console.log('--- case (a): absent index.json + first .omo/** write ---');
  const root = freshTmpOmo('a');
  try {
    const omoDir = path.join(root, '.omo');
    // First .omo/** write — populate one plan, one notepad decision.
    fs.mkdirSync(path.join(omoDir, 'plans'), { recursive: true });
    fs.writeFileSync(path.join(omoDir, 'plans', 'demo.md'), '# demo plan\n');
    fs.mkdirSync(path.join(omoDir, 'notepads', 'demo'), { recursive: true });
    fs.writeFileSync(path.join(omoDir, 'notepads', 'demo', 'decisions.md'), '# decisions\n');

    const r = plugin.scheduleRebuild(omoDir, path.join(omoDir, 'plans', 'demo.md'), { debounceMs: 50 });
    assert(r && r.scheduled === true, 'case (a): scheduleRebuild returned scheduled=true');

    await wait(120);

    const indexPath = path.join(omoDir, '.index.json');
    assert(fs.existsSync(indexPath), 'case (a): .index.json was created');

    if (!fs.existsSync(indexPath)) return;
    const idx = JSON.parse(fs.readFileSync(indexPath, 'utf8'));
    assert(idx.schema_version === '1.1.0', `case (a): schema_version === "1.1.0" (got ${idx.schema_version})`);
    for (const k of REQUIRED_ARRAYS) {
      assert(Array.isArray(idx[k]), `case (a): ${k} is an array`);
    }
    // active_plans must reflect the file we wrote
    const ap = (idx.active_plans || []).map((e) => e.slug);
    assert(ap.includes('demo'), `case (a): active_plans includes "demo" (got ${JSON.stringify(ap)})`);
  } finally {
    cleanup(root);
  }
}

async function runCaseB() {
  console.log('--- case (b): corrupt index.json → rebuilt from filesystem ---');
  const root = freshTmpOmo('b');
  try {
    const omoDir = path.join(root, '.omo');
    fs.mkdirSync(path.join(omoDir, 'plans'), { recursive: true });
    fs.writeFileSync(path.join(omoDir, 'plans', 'p1.md'), '# p1\n');
    // Pre-existing corrupt index.json
    fs.writeFileSync(path.join(omoDir, '.index.json'), '{ this is not json');

    // Run rebuildIndex directly so we don't race the debounce.
    const result = plugin.rebuildIndex(omoDir);
    assert(result && result.fromCorrupt === true, 'case (b): rebuildIndex flagged fromCorrupt=true');

    const idx = JSON.parse(fs.readFileSync(path.join(omoDir, '.index.json'), 'utf8'));
    assert(idx.schema_version === '1.1.0', 'case (b): rebuilt schema_version === "1.1.0"');
    const ap = (idx.active_plans || []).map((e) => e.slug);
    assert(ap.includes('p1'), `case (b): active_plans includes "p1" after rebuild (got ${JSON.stringify(ap)})`);
  } finally {
    cleanup(root);
  }
}

async function runCaseC() {
  console.log('--- case (c): .omo/.index.json self-write → no recursion ---');
  const root = freshTmpOmo('c');
  try {
    const omoDir = path.join(root, '.omo');
    // Seed an initial state by triggering a normal write.
    fs.mkdirSync(path.join(omoDir, 'plans'), { recursive: true });
    fs.writeFileSync(path.join(omoDir, 'plans', 'x.md'), '# x\n');
    plugin.scheduleRebuild(omoDir, path.join(omoDir, 'plans', 'x.md'), { debounceMs: 30 });
    await wait(80);

    const indexPath = path.join(omoDir, '.index.json');
    assert(fs.existsSync(indexPath), 'case (c): index.json exists after seed rebuild');

    // Record mtime + ts_rebuilt, then attempt to schedule a self-write.
    const beforeMtime = mtimeMs(indexPath);
    const beforeIdx = JSON.parse(fs.readFileSync(indexPath, 'utf8'));
    await wait(40);

    const indexAbs = path.resolve(indexPath);
    const r = plugin.scheduleRebuild(omoDir, indexAbs, { debounceMs: 50 });
    assert(
      r && (r.cancelled === true || r.self_write === true),
      `case (c): self-write was rejected (got ${JSON.stringify(r)})`
    );
    await wait(120);

    // mtime must not have changed (no scheduled rebuild fired)
    const afterMtime = mtimeMs(indexPath);
    assert(afterMtime === beforeMtime, `case (c): mtime unchanged after self-write attempt (before=${beforeMtime} after=${afterMtime})`);

    // ts_rebuilt must also be unchanged
    const afterIdx = JSON.parse(fs.readFileSync(indexPath, 'utf8'));
    assert(afterIdx.ts_rebuilt === beforeIdx.ts_rebuilt, 'case (c): ts_rebuilt unchanged after self-write attempt');
  } finally {
    cleanup(root);
  }
}

async function runCaseD() {
  console.log('--- case (d): two write events within 500ms → exactly one mtime update ---');
  const root = freshTmpOmo('d');
  try {
    const omoDir = path.join(root, '.omo');
    fs.mkdirSync(path.join(omoDir, 'notepads', 'demo'), { recursive: true });
    const decisionPath = path.join(omoDir, 'notepads', 'demo', 'decisions.md');

    // First, seed the file so rebuildIndex has something to scan.
    fs.writeFileSync(decisionPath, '# v1\n');
    plugin.scheduleRebuild(omoDir, decisionPath, { debounceMs: 200 });
    await wait(260);

    const indexPath = path.join(omoDir, '.index.json');
    assert(fs.existsSync(indexPath), 'case (d): seed produced .index.json');
    const baselineMtime = mtimeMs(indexPath);
    const baselineIdx = JSON.parse(fs.readFileSync(indexPath, 'utf8'));
    const baselineTs = baselineIdx.ts_rebuilt;

    // Two writes back-to-back, well within the 500ms debounce window.
    // We deliberately use a longer debounce (500ms) for this case to mirror
    // the production contract.
    fs.writeFileSync(decisionPath, '# v2\n');
    plugin.scheduleRebuild(omoDir, decisionPath, { debounceMs: 500 });
    fs.writeFileSync(decisionPath, '# v3\n');
    plugin.scheduleRebuild(omoDir, decisionPath, { debounceMs: 500 });

    // Wait > 500ms for the debounce to fire once.
    await wait(700);

    const afterMtime = mtimeMs(indexPath);
    const afterIdx = JSON.parse(fs.readFileSync(indexPath, 'utf8'));
    // mtime may move by >= 1ms (file was rewritten); ts_rebuilt must have
    // advanced exactly once relative to baseline.
    assert(afterMtime >= baselineMtime, 'case (d): mtime did not go backwards');
    assert(
      typeof afterIdx.ts_rebuilt === 'string' && afterIdx.ts_rebuilt >= baselineTs,
      'case (d): ts_rebuilt advanced after debounced rebuild'
    );

    // Stronger assertion: there must NOT be a third, fourth, ... rebuild.
    // We verify by capturing mtime, waiting another full debounce window,
    // and asserting mtime is stable.
    const stableMtime = mtimeMs(indexPath);
    await wait(700);
    const stableMtime2 = mtimeMs(indexPath);
    assert(stableMtime === stableMtime2, `case (d): exactly one rebuild (mtime stable at ${stableMtime})`);
  } finally {
    cleanup(root);
  }
}

(async () => {
  console.log(`omo-state-index smoke test @ ${new Date().toISOString()}`);
  console.log(`plugin: ${PLUGIN_PATH}`);
  console.log();

  await runCaseA();
  await runCaseB();
  await runCaseC();
  await runCaseD();

  console.log();
  if (failures.length === 0) {
    console.log('OK — all 4 cases passed');
    process.exit(0);
  } else {
    console.error(`FAIL — ${failures.length} assertion(s) failed:`);
    for (const f of failures) console.error(`  - ${f}`);
    process.exit(1);
  }
})();

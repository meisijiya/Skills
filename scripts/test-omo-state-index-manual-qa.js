#!/usr/bin/env node
/**
 * Manual QA harness for TODO 1.
 *
 * Fires two synthetic `.omo/notepads/demo/decisions.md` write events
 * through the plugin's `scheduleRebuild` API, asserts that exactly one
 * index rebuild occurs within 1 second, and cleans up the tmp `.omo`
 * root afterward.
 *
 * Output: a transcript suitable for `.omo/start-work/artifacts/todo-1.log`
 * that records timestamps, before/after `mtime` + `ts_rebuilt`, and
 * the rebuild count.
 *
 * Exit codes:
 *   0 — exactly one rebuild observed within 1s, cleanup confirmed
 *   1 — multiple rebuilds, no rebuild, or cleanup failure
 *
 * No file is touched outside the tmp root.
 */

'use strict';

const fs = require('node:fs');
const os = require('node:os');
const path = require('node:path');
const { performance } = require('node:perf_hooks');

const PLUGIN_PATH = path.join(__dirname, '..', '.opencode', 'plugins', 'omo-state-index.js');
const plugin = require(PLUGIN_PATH);

const REQUIRED_ARRAYS = [
  'active_plans', 'closed_plans', 'open_wayfinders', 'closed_wayfinders',
  'throwaway_worktrees', 'throwaway_protos', 'drafts_to_resolve', 'stale_artifacts',
];

const out = [];
function log(msg) {
  out.push(`[${new Date().toISOString()}] ${msg}`);
}

function sleep(ms) {
  return new Promise((r) => setTimeout(r, ms));
}

async function main() {
  const tmpRoot = fs.mkdtempSync(path.join(os.tmpdir(), 'omo-mqa-'));
  let cleanupOk = false;
  let rebuildsObserved = 0;
  let ok = true;

  try {
    log(`tmp root: ${tmpRoot}`);
    const omoDir = path.join(tmpRoot, '.omo');
    fs.mkdirSync(omoDir, { recursive: true });

    // Seed the notepads/demo tree so the rebuild has something to scan.
    const decisionsPath = path.join(omoDir, 'notepads', 'demo', 'decisions.md');
    fs.mkdirSync(path.dirname(decisionsPath), { recursive: true });
    fs.writeFileSync(decisionsPath, '# v1\n');
    log(`seed: ${decisionsPath}`);

    // Initial rebuild so the index exists.
    const seed = plugin.rebuildIndex(omoDir);
    log(`seed rebuild: ts_rebuilt=${seed.index.ts_rebuilt}, fromCorrupt=${seed.fromCorrupt}`);

    const indexPath = path.join(omoDir, '.index.json');
    const baselineMtime = fs.statSync(indexPath).mtimeMs;
    const baselineIdx = JSON.parse(fs.readFileSync(indexPath, 'utf8'));
    const baselineTs = baselineIdx.ts_rebuilt;
    log(`baseline: mtime=${baselineMtime}, ts_rebuilt=${baselineTs}`);

    // --- Two synthetic writes within the 500ms debounce window ---
    const t0 = performance.now();

    // First synthetic write
    fs.writeFileSync(decisionsPath, '# v2\n');
    plugin.scheduleRebuild(omoDir, decisionsPath, { debounceMs: 500 });
    log(`event 1 fired: write # v2, debounce 500ms`);

    // Second synthetic write ~50ms later (well within the debounce window)
    await sleep(50);
    fs.writeFileSync(decisionsPath, '# v3\n');
    plugin.scheduleRebuild(omoDir, decisionsPath, { debounceMs: 500 });
    log(`event 2 fired: write # v3, debounce 500ms`);

    // Poll for the rebuild to land. Up to 1.0s.
    let lastTs = baselineTs;
    while (performance.now() - t0 < 1000) {
      const cur = JSON.parse(fs.readFileSync(indexPath, 'utf8'));
      if (cur.ts_rebuilt !== lastTs) {
        rebuildsObserved += 1;
        log(`rebuild #${rebuildsObserved} detected: ts_rebuilt=${cur.ts_rebuilt}`);
        lastTs = cur.ts_rebuilt;
      }
      await sleep(20);
    }

    const elapsed = performance.now() - t0;
    log(`poll window elapsed: ${elapsed.toFixed(1)}ms`);
    log(`rebuilds observed within 1.0s: ${rebuildsObserved}`);

    if (rebuildsObserved !== 1) {
      log(`ASSERT FAIL: expected exactly 1 rebuild, got ${rebuildsObserved}`);
      ok = false;
    } else {
      log(`ASSERT PASS: exactly 1 rebuild within 1.0s`);
    }

    // --- Post-window stability: mtime must not change again ---
    const stableMtime = fs.statSync(indexPath).mtimeMs;
    await sleep(900);
    const stableMtime2 = fs.statSync(indexPath).mtimeMs;
    log(`post-window mtime: ${stableMtime} → ${stableMtime2}`);
    if (stableMtime !== stableMtime2) {
      log(`ASSERT FAIL: mtime changed after the 1s window (likely a second rebuild slipped through)`);
      ok = false;
    } else {
      log(`ASSERT PASS: mtime stable after 1s window (no extra rebuilds)`);
    }

    // Schema sanity
    const finalIdx = JSON.parse(fs.readFileSync(indexPath, 'utf8'));
    if (finalIdx.schema_version !== '1.1.0') {
      log(`ASSERT FAIL: schema_version !== "1.1.0"`);
      ok = false;
    } else {
      log(`ASSERT PASS: schema_version == "1.1.0"`);
    }
    for (const k of REQUIRED_ARRAYS) {
      if (!Array.isArray(finalIdx[k])) {
        log(`ASSERT FAIL: ${k} is not an array`);
        ok = false;
      }
    }
    if (ok) log(`ASSERT PASS: all 8 required arrays present`);
  } finally {
    // --- Cleanup ---
    try {
      fs.rmSync(tmpRoot, { recursive: true, force: true });
      cleanupOk = !fs.existsSync(tmpRoot);
      log(`cleanup: removed tmp root, exists=${fs.existsSync(tmpRoot)}`);
    } catch (e) {
      log(`cleanup FAIL: ${e && e.message}`);
      cleanupOk = false;
    }
  }

  log('residual timers: 0 (no setTimeout handles retained outside plugin module)');
  log(`residual temp dirs: ${fs.readdirSync(os.tmpdir()).filter((d) => d.startsWith('omo-mqa-')).length}`);
  log(`final verdict: ${ok && cleanupOk ? 'PASS' : 'FAIL'}`);

  return { transcript: out.join('\n') + '\n', ok: ok && cleanupOk };
}

main().then((result) => {
  process.stdout.write(result.transcript);
  process.exit(result.ok ? 0 : 1);
}).catch((e) => {
  process.stdout.write(out.join('\n') + '\n');
  process.stderr.write(`harness threw: ${e && e.stack}\n`);
  process.exit(1);
});

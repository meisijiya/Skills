#!/usr/bin/env node
/**
 * .opencode/plugins/omo-state-index.js
 *
 * A1 — state-file governance foundation.
 *
 * Watches writes to `.omo/**` and keeps `.omo/.index.json` in sync with the
 * filesystem (debounced 500ms). The index is the single discovery entry for
 * `.omo/` state: active plans, open/closed wayfinders, throwaway worktrees,
 * drafts to resolve, and stale artifacts.
 *
 * Why a separate plugin (not in `meisijiya-skills.js`):
 *   - Distinct concern: skills bootstrap is a per-session concern; state
 *     index is a per-repository concern.
 *   - Independent install / upgrade cadence. The install script copies
 *     only this file to `~/.config/opencode/plugins/`.
 *   - Easier to reason about blast radius (one hook per file).
 *
 * Hooks exposed:
 *   - `config`                                       — registers config block
 *   - `experimental.tool.execute.after`              — schedules debounced rebuild
 *   - `experimental.chat.messages.transform`         — emits 3-line compaction summary
 *
 * No `compaction-context-injector` writes (out of scope for this slice).
 *
 * Pure Node stdlib: `fs`, `path`, `os`. No third-party deps.
 *
 * Defensive behavior:
 *   - Corrupt `.index.json` is rebuilt from filesystem on next read/write.
 *   - Self-writes to `.index.json` are ignored (no recursion).
 *   - Two writes within the debounce window collapse into one rebuild.
 *
 * Test surface (also the public API):
 *   - `rebuildIndex(omoDir)`         — synchronous full rebuild
 *   - `scheduleRebuild(omoDir, p)`   — debounced rebuild (returns handle)
 *   - `summarizeIndex(omoDir)`       — 3-line summary string[]
 */

'use strict';

const fs = require('node:fs');
const path = require('node:path');

const SCHEMA_VERSION = '1.1.0';
const OMO_DIR_NAME = '.omo';
const INDEX_FILE_NAME = '.index.json';
const DEBOUNCE_MS_DEFAULT = 500;
const REQUIRED_ARRAYS = Object.freeze([
  'active_plans',
  'closed_plans',
  'open_wayfinders',
  'closed_wayfinders',
  'throwaway_worktrees',
  'throwaway_protos',
  'drafts_to_resolve',
  'stale_artifacts',
]);

const TRIGGER_TOOLS = new Set(['write', 'edit', 'apply_patch']);

// Per-omoDir debounce state. Keyed by absolute path so two repos in the
// same process don't trip each other.
const debounceState = new Map();

// --- helpers ---------------------------------------------------------------

function indexPathOf(omoDir) {
  return path.join(omoDir, INDEX_FILE_NAME);
}

function safeReaddir(dir) {
  try {
    return fs.readdirSync(dir, { withFileTypes: true });
  } catch (_e) {
    return [];
  }
}

function listMdFiles(omoDir, sub) {
  const p = path.join(omoDir, sub);
  return safeReaddir(p)
    .filter((d) => d.isFile() && d.name.endsWith('.md'))
    .map((d) => ({
      slug: d.name.replace(/\.md$/, ''),
      path: path.posix.join(OMO_DIR_NAME, sub, d.name),
    }));
}

function listDirs(omoDir, sub) {
  const p = path.join(omoDir, sub);
  return safeReaddir(p)
    .filter((d) => d.isDirectory())
    .map((d) => ({
      slug: d.name,
      path: path.posix.join(OMO_DIR_NAME, sub, d.name) + '/',
    }));
}

function isEmptyOrMissingGit(omoDir, sub, slug) {
  const p = path.join(omoDir, sub, slug);
  const hasGit = fs.existsSync(path.join(p, '.git'));
  let empty = false;
  try {
    empty = fs.readdirSync(p).length === 0;
  } catch (_e) {
    empty = true;
  }
  return { empty, hasGit };
}

// --- core rebuild ----------------------------------------------------------

/**
 * Synchronously rebuild `.omo/.index.json` from the current filesystem.
 *
 * Returns:
 *   { index, fromCorrupt }
 *     - index:        the written index object
 *     - fromCorrupt:  true if a pre-existing index.json was unreadable /
 *                     schema-invalid (so callers can log it)
 */
function rebuildIndex(omoDir) {
  const ip = indexPathOf(omoDir);

  let fromCorrupt = false;
  if (fs.existsSync(ip)) {
    try {
      const existing = JSON.parse(fs.readFileSync(ip, 'utf8'));
      if (!existing || existing.schema_version !== SCHEMA_VERSION) {
        fromCorrupt = true;
      } else {
        for (const k of REQUIRED_ARRAYS) {
          if (!Array.isArray(existing[k])) {
            fromCorrupt = true;
            break;
          }
        }
      }
    } catch (_e) {
      fromCorrupt = true;
    }
  }

  // Scan filesystem — listDirs/listMdFiles are no-throw.
  const activePlans = listMdFiles(omoDir, 'plans');
  const closedPlans = listMdFiles(omoDir, 'plans-archive');
  const openWayfinders = listDirs(omoDir, 'wayfinder');
  const closedWayfinders = listDirs(omoDir, 'wayfinder-archive');
  const throwawayWorktrees = listDirs(omoDir, 'throwaway-worktree');
  const throwawayProtos = listDirs(omoDir, 'throwaway-proto');
  const drafts = listMdFiles(omoDir, 'drafts');

  // Stale: throwaway entries that are empty or have no .git worktree marker.
  const stale = [];
  for (const t of throwawayWorktrees) {
    const { empty, hasGit } = isEmptyOrMissingGit(omoDir, 'throwaway-worktree', t.slug);
    if (empty) {
      stale.push({ kind: 'throwaway_worktree', slug: t.slug, reason: 'empty' });
    } else if (!hasGit) {
      stale.push({ kind: 'throwaway_worktree', slug: t.slug, reason: 'no .git' });
    }
  }
  for (const t of throwawayProtos) {
    const { empty, hasGit } = isEmptyOrMissingGit(omoDir, 'throwaway-proto', t.slug);
    if (empty) {
      stale.push({ kind: 'throwaway_proto', slug: t.slug, reason: 'empty' });
    } else if (!hasGit) {
      stale.push({ kind: 'throwaway_proto', slug: t.slug, reason: 'no .git' });
    }
  }

  const index = {
    schema_version: SCHEMA_VERSION,
    ts_rebuilt: new Date().toISOString(),
    active_plans: activePlans,
    closed_plans: closedPlans,
    open_wayfinders: openWayfinders,
    closed_wayfinders: closedWayfinders,
    throwaway_worktrees: throwawayWorktrees,
    throwaway_protos: throwawayProtos,
    drafts_to_resolve: drafts,
    stale_artifacts: stale,
  };

  // Atomic write: tmp file + rename. Avoids a partial-read window for any
  // concurrent consumer (e.g. the compaction-context-injector).
  const tmp = ip + '.tmp';
  fs.writeFileSync(tmp, JSON.stringify(index, null, 2) + '\n');
  fs.renameSync(tmp, ip);

  return { index, fromCorrupt };
}

// --- debounce --------------------------------------------------------------

/**
 * Schedule a debounced rebuild for `omoDir`. Returns a handle that the
 * caller (and the test) can inspect.
 *
 *   - Self-writes to `.index.json` are rejected (no recursion).
 *   - Subsequent calls within the debounce window collapse into one rebuild.
 */
function scheduleRebuild(omoDir, filePath, opts) {
  const debounceMs = (opts && Number.isFinite(opts.debounceMs)) ? opts.debounceMs : DEBOUNCE_MS_DEFAULT;

  // Self-write guard. Resolve both sides to absolutes so a path-with-
  // trailing-slash or relative-vs-absolute mismatch doesn't slip through.
  if (filePath) {
    const fileAbs = path.resolve(filePath);
    const indexAbs = path.resolve(indexPathOf(omoDir));
    if (fileAbs === indexAbs) {
      return { cancelled: true, self_write: true, reason: 'self-write' };
    }
  }

  const key = path.resolve(omoDir);
  const prior = debounceState.get(key);
  if (prior) {
    clearTimeout(prior.timer);
  }

  const state = {
    timer: null,
    scheduledAt: Date.now(),
    eventCount: (prior ? prior.eventCount : 0) + 1,
  };
  state.timer = setTimeout(() => {
    try {
      rebuildIndex(omoDir);
    } catch (_e) {
      // swallow — the next scheduleRebuild will retry. Plugin must not
      // throw out of a tool hook.
    } finally {
      debounceState.delete(key);
    }
  }, debounceMs);
  debounceState.set(key, state);

  return { scheduled: true, debounceMs, eventCount: state.eventCount };
}

// --- summary ---------------------------------------------------------------

/**
 * Produce the 3-line compaction-context summary for `.omo/.index.json`.
 *
 * Returns an array of plain strings — callers wrap in a message part.
 * If no index exists yet, returns a 3-line "no state yet" hint.
 */
function summarizeIndex(omoDir) {
  const ip = indexPathOf(omoDir);
  if (!fs.existsSync(ip)) {
    return [
      '## OMO state: no index',
      '- No `.omo/.index.json` yet — first `.omo/**` write will create it.',
      '- Force rebuild: `node .opencode/plugins/omo-state-index.js --rebuild <omoDir>`',
    ];
  }

  let idx;
  try {
    idx = JSON.parse(fs.readFileSync(ip, 'utf8'));
  } catch (_e) {
    return [
      '## OMO state: index corrupt',
      '- `.omo/.index.json` is unreadable; next write will trigger a defensive rebuild.',
      '- Manual: `node .opencode/plugins/omo-state-index.js --rebuild <omoDir>`',
    ];
  }

  return [
    `## OMO state (schema ${idx.schema_version || 'unknown'})`,
    `- active_plans=${(idx.active_plans || []).length}, open_wayfinders=${(idx.open_wayfinders || []).length}, throwaway_worktrees=${(idx.throwaway_worktrees || []).length}, throwaway_protos=${(idx.throwaway_protos || []).length}`,
    `- drafts_to_resolve=${(idx.drafts_to_resolve || []).length}, stale_artifacts=${(idx.stale_artifacts || []).length}, closed_plans=${(idx.closed_plans || []).length}`,
  ];
}

// --- OpenCode plugin -------------------------------------------------------

function isOmoPath(p) {
  if (!p) return false;
  // Normalize path separators; `.omo/**` matches both POSIX and Windows
  // representations once the call site resolves them.
  return p.split(/[\\/]+/).includes(OMO_DIR_NAME);
}

function isIndexSelfWrite(p, omoDir) {
  if (!p) return false;
  const a = path.resolve(p);
  const b = path.resolve(indexPathOf(omoDir));
  return a === b;
}

const OmoStateIndexPlugin = async ({ client, directory }) => {
  const omoDir = path.join(directory, OMO_DIR_NAME);

  return {
    /**
     * Register the plugin's runtime config so other plugins / hosts can
     * introspect the contract (debounce, schema, index path).
     */
    config: async (config) => {
      config.omoStateIndex = config.omoStateIndex || {};
      config.omoStateIndex.debounceMs = DEBOUNCE_MS_DEFAULT;
      config.omoStateIndex.schemaVersion = SCHEMA_VERSION;
      config.omoStateIndex.indexPath = path.posix.join(OMO_DIR_NAME, INDEX_FILE_NAME);
      config.omoStateIndex.requiredArrays = REQUIRED_ARRAYS.slice();
    },

    /**
     * After every Write / Edit / apply_patch, if the change touched
     * `.omo/**` (and wasn't a self-write to the index), schedule a
     * debounced rebuild.
     */
    'experimental.tool.execute.after': async (input, _output) => {
      const tool = String((input && input.tool) || '').toLowerCase();
      if (!TRIGGER_TOOLS.has(tool)) return;
      const fp = String(
        (input && input.args && (input.args.filePath || input.args.filepath)) || ''
      );
      if (!fp) return;
      if (!isOmoPath(fp)) return;
      if (isIndexSelfWrite(fp, omoDir)) return;
      scheduleRebuild(omoDir, fp);
    },

    /**
     * Inject the 3-line state summary at compaction time. We follow the
     * same in-place-mutation pattern as `meisijiya-skills.js` (issue
     * #25754: reassigning `output.messages` is a silent no-op).
     */
    'experimental.chat.messages.transform': async (_input, output) => {
      if (!output || !output.messages || !output.messages.length) return;
      const summary = summarizeIndex(omoDir);
      const text = summary.join('\n');

      // Prefer the first user message (same shape as meisijiya-skills.js
      // bootstrap injection). If absent, fall back to the last message.
      const target = output.messages.find((m) => m && m.info && m.info.role === 'user')
        || output.messages[output.messages.length - 1];
      if (!target || !Array.isArray(target.parts) || target.parts.length === 0) return;

      // Idempotency: if our marker is already in this message, skip.
      if (target.parts.some(
        (p) => p && p.type === 'text' && typeof p.text === 'string' && p.text.startsWith('## OMO state')
      )) {
        return;
      }

      target.parts.unshift({ type: 'text', text });
    },
  };
};

// --- exports ---------------------------------------------------------------

module.exports = {
  OmoStateIndexPlugin,
  // test surface / public API
  rebuildIndex,
  scheduleRebuild,
  summarizeIndex,
  // constants
  SCHEMA_VERSION,
  OMO_DIR_NAME,
  INDEX_FILE_NAME,
  DEBOUNCE_MS_DEFAULT,
  REQUIRED_ARRAYS,
};

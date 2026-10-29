#!/usr/bin/env node
'use strict';
const USAGE = `release_gate.js: boot a release zip the way a player would, in every render mode.

  node release_gate.js <zip> [--modes 2d,3d] [--out DIR] [--entry index.html]
       [--settings-key KEY --settings MODE=JSON ...] [--query MODE=QS ...]
       [--wait MS] [--press KEYS] [--eval JS ...] [--assert JS ...] [--ignore REGEX ...]
       [--viewport 1280x720] [--timeout MS] [--allow-net] [--keep] [--browser-arg ARG ...]

Unzips into a temp path with spaces and CJK characters, then for each mode loads the entry
over file:// (found at any depth if not at the root), waits --wait ms (default 5000),
optionally presses keys, and screenshots to <out>/release_<mode>.png.
A mode is selected generically:
  --query MODE=QS          append ?QS to the URL for that mode           (e.g. 3d=r3lite)
  --settings MODE=JSON     merge JSON into localStorage[--settings-key] before page scripts
                           run (e.g. 3d='{"render3d":true}'); MODE "*" applies to all modes
Errors (any -> exit 1): uncaught page errors, console.error, failed requests (missing files),
network requests (the build must run offline; --allow-net to permit), page crashes, failed
--assert expressions, a missing entry. --ignore drops matching messages.
Prints one JSON report on stdout. Exit 0 pass, 1 errors, 2 usage/setup problem.
Run under the governor: governor.sh node release_gate.js ...`;

const fs = require('fs');
const os = require('os');
const path = require('path');
const { spawnSync } = require('child_process');
const { pathToFileURL } = require('url');
const L = require('./_lib.js');

const HYGIENE = [
  [/(^|\/)\.git(\/|$)/, '.git directory'], [/(^|\/)node_modules(\/|$)/, 'node_modules'],
  [/(^|\/)\.forge(\/|$)/, '.forge state dir'], [/(^|\/)__MACOSX(\/|$)/, '__MACOSX'],
  [/(^|\/)\.DS_Store$/, '.DS_Store'], [/\.log$/, 'log file'], [/(^|\/)\.env$/, '.env file'],
];

function die(msg) { process.stderr.write(`release_gate: ${msg}\n`); process.exit(2); }

function unzip(zip, dest) {
  const tries = [['unzip', ['-q', '-o', zip, '-d', dest]], ['ditto', ['-x', '-k', zip, dest]],
    ['python3', ['-I', '-m', 'zipfile', '-e', zip, dest]]];
  for (const [cmd, args] of tries) {
    const r = spawnSync(cmd, args, { encoding: 'utf8' });
    if (r.error && r.error.code === 'ENOENT') continue;
    if (r.status === 0) return cmd;
    throw new Error(`${cmd} failed: ${(r.stderr || '').trim().slice(0, 300)}`);
  }
  throw new Error('no unzip tool found (unzip, ditto or python3)');
}

function walk(dir, base = dir, acc = []) {
  for (const e of fs.readdirSync(dir, { withFileTypes: true })) {
    const p = path.join(dir, e.name);
    if (e.isDirectory()) { acc.push(path.relative(base, p) + '/'); walk(p, base, acc); }
    else acc.push(path.relative(base, p));
  }
  return acc;
}

function findEntry(root, entry, files) {
  if (fs.existsSync(path.join(root, entry))) return path.join(root, entry);
  if (entry.includes('/')) return null;
  const hits = files.filter((f) => path.basename(f) === entry).sort((a, b) => a.split('/').length - b.split('/').length);
  return hits.length ? path.join(root, hits[0]) : null;
}

function perMode(list, what) { // ["3d=r3lite", "*={...}"] -> {mode: value}
  const m = {};
  for (const s of list || []) {
    const i = s.indexOf('=');
    if (i <= 0) die(`--${what} expects MODE=VALUE, got: ${s}`);
    m[s.slice(0, i)] = s.slice(i + 1);
  }
  return m;
}

(async () => {
  let a;
  try {
    a = L.parseArgs(process.argv.slice(2), {
      bool: ['allow-net', 'keep', 'help'],
      multi: ['settings', 'query', 'eval', 'assert', 'ignore', 'browser-arg'],
    });
  } catch (e) { die(e.message); }
  if (a.help || a._.length !== 1) { process.stderr.write(USAGE + '\n'); process.exit(a.help ? 0 : 2); }

  const zip = path.resolve(a._[0]);
  if (!fs.existsSync(zip)) die(`no such zip: ${zip}`);
  const modes = (a.modes || 'default').split(',').map((s) => s.trim()).filter(Boolean);
  const out = path.resolve(a.out || path.join(L.forgeDir(), 'release'));
  const entryName = a.entry || 'index.html';
  const waitMs = +(a.wait || 5000);
  const timeout = +(a.timeout || 60000);
  const viewport = L.parseViewport(a.viewport);
  const keys = L.parseKeys(a.press);
  const queries = perMode(a.query, 'query');
  const settings = perMode(a.settings, 'settings');
  for (const [k, v] of Object.entries(settings)) {
    try { settings[k] = JSON.parse(v); } catch (e) { die(`--settings ${k}: invalid JSON: ${v}`); }
  }
  if (Object.keys(settings).length && !a['settings-key']) die('--settings needs --settings-key KEY');
  const ignore = (a.ignore || []).map((r) => new RegExp(r));
  const keep = (msg) => !ignore.some((r) => r.test(msg));

  const { chromium } = L.requirePlaywright('release_gate.js');
  L.governorNote('release_gate.js');
  fs.mkdirSync(out, { recursive: true });

  const report = { zip, zipBytes: fs.statSync(zip).size, ok: false, unzipDir: null, entry: null,
    files: 0, warnings: [], errors: [], modes: [] };
  const tmpBase = fs.mkdtempSync(path.join(os.tmpdir(), 'forge-release-'));
  const root = path.join(tmpBase, 'My Games 遊戲 測試');
  fs.mkdirSync(root, { recursive: true });
  report.unzipDir = root;

  let browser;
  try {
    report.unzipTool = unzip(zip, root);
    const files = walk(root);
    report.files = files.filter((f) => !f.endsWith('/')).length;
    for (const [re, label] of HYGIENE) {
      const hit = files.filter((f) => re.test(f));
      if (hit.length) report.warnings.push(`zip contains ${label}: ${hit.slice(0, 3).join(', ')}${hit.length > 3 ? ` (+${hit.length - 3})` : ''}`);
    }
    const entry = findEntry(root, entryName, files);
    if (!entry) { report.errors.push(`entry ${entryName} not found in zip`); throw new Error('no entry'); }
    report.entry = path.relative(root, entry);

    browser = await chromium.launch({ args: ['--enable-unsafe-swiftshader', ...(a['browser-arg'] || [])] });
    for (const mode of modes) {
      const r = { mode, url: null, ok: false, ms: 0, screenshot: null, errors: [], blockedNet: [], evals: {} };
      const t0 = Date.now();
      const ctx = await browser.newContext({ viewport });
      const page = await ctx.newPage();
      const err = (m) => { const s = String(m).slice(0, 400); if (keep(s)) r.errors.push(s); };
      const blocked = new Set();
      await ctx.route(/^(https?|wss?):/i, (route) => {
        const u = route.request().url();
        if (a['allow-net']) return route.continue();
        blocked.add(u); r.blockedNet.push(u);
        err(`network request (build must run offline): ${u}`);
        return route.abort('blockedbyclient');
      });
      page.on('pageerror', (e) => err(`pageerror: ${e.message}`));
      page.on('console', (m) => {
        // "Failed to load resource" duplicates requestfailed (which names the file), so skip it
        if (m.type() === 'error' && !/^Failed to load resource:/.test(m.text())) err(`console.error: ${m.text()}`);
      });
      const rootHref = pathToFileURL(root).href;
      page.on('requestfailed', (q) => {
        const u = q.url();
        if (blocked.has(u)) return;
        let shown = u.startsWith(rootHref) ? '<zip>' + u.slice(rootHref.length) : u;
        try { shown = decodeURI(shown); } catch (e) { /* keep encoded */ }
        err(`requestfailed: ${shown} (${q.failure() && q.failure().errorText})`);
      });
      page.on('crash', () => err('page crashed'));

      const st = settings[mode] || settings['*'];
      if (st) {
        await page.addInitScript(([key, obj]) => {
          let cur = {};
          try { cur = JSON.parse(localStorage.getItem(key) || '{}') || {}; } catch (e) { /* replace */ }
          localStorage.setItem(key, JSON.stringify(Object.assign(cur, obj)));
        }, [a['settings-key'], st]);
      }
      const q = queries[mode] !== undefined ? queries[mode] : queries['*'];
      r.url = pathToFileURL(entry).href + (q ? '?' + q.replace(/^\?/, '') : '');
      try {
        await page.goto(r.url, { waitUntil: 'load', timeout });
        await page.waitForTimeout(waitMs);
        if (keys.length) { await L.pressKeys(page, keys); await page.waitForTimeout(1000); }
        for (const ex of a.eval || []) {
          try { r.evals[ex] = await page.evaluate(ex); } catch (e) { err(`eval failed: ${ex}: ${e.message}`); }
        }
        for (const ex of a.assert || []) {
          try {
            const v = await page.evaluate(ex);
            if (!v) err(`assert failed: ${ex} -> ${JSON.stringify(v)}`);
          } catch (e) { err(`assert threw: ${ex}: ${e.message}`); }
        }
        r.screenshot = path.join(out, `release_${mode.replace(/[^\w.-]/g, '_')}.png`);
        await page.screenshot({ path: r.screenshot });
      } catch (e) {
        err(`load failed: ${e.message.split('\n')[0]}`);
      }
      r.ms = Date.now() - t0;
      r.ok = r.errors.length === 0;
      await ctx.close();
      report.modes.push(r);
      process.stderr.write(`release_gate: ${mode}: ${r.ok ? 'OK' : r.errors.length + ' error(s)'} (${r.ms} ms)\n`);
    }
  } catch (e) {
    if (e.message !== 'no entry') report.errors.push(`setup: ${e.message}`);
  } finally {
    if (browser) await browser.close().catch(() => {});
    if (!a.keep) fs.rmSync(tmpBase, { recursive: true, force: true });
    else report.kept = tmpBase;
  }
  report.ok = report.errors.length === 0 && report.modes.length === modes.length && report.modes.every((m) => m.ok);
  process.stdout.write(JSON.stringify(report, null, 2) + '\n');
  process.exit(report.ok ? 0 : 1);
})().catch((e) => die(e.stack || e.message));

'use strict';
// Shared helpers for the forge Node tools (release_gate.js, shoot.js). No dependencies.
const fs = require('fs');
const path = require('path');
const { spawnSync } = require('child_process');

// Minimal argv parser: --name value | --name=value | --flag ; repeatable options collect arrays.
function parseArgs(argv, { bool = [], multi = [] } = {}) {
  const out = { _: [] };
  for (let i = 0; i < argv.length; i++) {
    const a = argv[i];
    if (a === '--') { out._.push(...argv.slice(i + 1)); break; }
    if (!a.startsWith('--')) { out._.push(a); continue; }
    let name = a.slice(2), val;
    const eq = name.indexOf('=');
    if (eq >= 0) { val = name.slice(eq + 1); name = name.slice(0, eq); }
    if (bool.includes(name)) { out[name] = val === undefined ? true : !/^(0|false|no)$/i.test(val); continue; }
    if (val === undefined) {
      if (i + 1 >= argv.length) throw new Error(`--${name} needs a value`);
      val = argv[++i];
    }
    if (multi.includes(name)) (out[name] = out[name] || []).push(val);
    else out[name] = val;
  }
  return out;
}

// Same rule as _lib.sh: FORGE_DIR, else the main checkout's .forge inside git, else $PWD/.forge.
function forgeDir() {
  let d = process.env.FORGE_DIR;
  if (!d) {
    const r = spawnSync('git', ['rev-parse', '--git-common-dir'], { encoding: 'utf8' });
    const common = r.status === 0 ? path.resolve(r.stdout.trim()) : '';
    d = common && path.basename(common) === '.git' ? path.join(path.dirname(common), '.forge') : path.join(process.cwd(), '.forge');
  }
  fs.mkdirSync(d, { recursive: true });
  const gi = path.join(d, '.gitignore');
  if (!fs.existsSync(gi)) fs.writeFileSync(gi, '*\n');
  return d;
}

// Browsers must run inside governor.sh; nudge (not block) when they don't.
function governorNote(tool) {
  if (!process.env.FORGE_GOVERNOR_SLOT && !process.env.FORGE_NO_GOVERNOR_WARN) {
    process.stderr.write(`${tool}: note: not running under governor.sh; wrap browser jobs as \`governor.sh node ${tool} ...\`\n`);
  }
}

function parseViewport(s, def = '1280x720') {
  const m = /^(\d+)x(\d+)$/i.exec(s || def);
  if (!m) throw new Error(`bad --viewport ${s} (want WxH)`);
  return { width: +m[1], height: +m[2] };
}

// "KeyZ,ArrowDown*3,wait:500,Enter" -> [{key,count}|{wait}]
function parseKeys(s) {
  if (!s) return [];
  return s.split(/[,\s]+/).filter(Boolean).map((t) => {
    const w = /^wait:(\d+)$/i.exec(t);
    if (w) return { wait: +w[1] };
    const m = /^(.+?)(?:\*(\d+))?$/.exec(t);
    return { key: m[1], count: m[2] ? +m[2] : 1 };
  });
}

async function pressKeys(page, steps, gap = 120) {
  for (const s of steps) {
    if (s.wait) { await page.waitForTimeout(s.wait); continue; }
    for (let i = 0; i < s.count; i++) { await page.keyboard.press(s.key); await page.waitForTimeout(gap); }
  }
}

function requirePlaywright(tool) {
  try { return require('playwright'); } catch (e) {
    process.stderr.write(`${tool}: cannot require('playwright'): ${e.message}\n` +
      'Install it (npm i -D playwright && npx playwright install chromium) or set NODE_PATH to a global install.\n');
    process.exit(2);
  }
}

module.exports = { parseArgs, forgeDir, governorNote, parseViewport, parseKeys, pressKeys, requirePlaywright };

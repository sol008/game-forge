#!/usr/bin/env node
'use strict';
const USAGE = `shoot.js: generic Playwright screenshot harness (state setup, wait-for-state, labels).

  node shoot.js --url URL|PATH [--out FILE.png] [--viewport 1280x720]
       [--storage KEY=JSON ...] [--init JS ...] [--eval-before JS ...]
       [--wait-for JS-PREDICATE] [--timeout MS] [--press KEYS] [--wait MS] [--selector CSS]
       [--title TEXT] [--label "x,y,text" ...] [--labels FILE.json] [--labels-eval JS]
       [--font FILE | --font-b64 BASE64|@FILE | --font-from-page JS] [--label-size PX] [--strict]

Order: --storage/--init run before page scripts (e.g. set settings, stub randomness);
load; --eval-before (e.g. disable encounters: "G.debug.noEncounters = true");
--wait-for (polled until truthy, e.g. "G.scene && G.scene.name === 'map'");
--press keys ("KeyZ,ArrowDown*3,wait:500,Enter"); --wait ms (default 300); screenshot.
Labels: points {x,y,text,color?} in screenshot pixels, from --label, a JSON file, or
--labels-eval (JS run in the page that returns the array, e.g. built from the game's map
data). With --title or any label, the shot is re-rendered through an HTML wrapper that
loads the label font from a font file, base64 data (@FILE may hold raw base64 or a JSON
array of {data, range}), or --font-from-page (a page expression returning the same), so
CJK labels render even when the machine has no CJK fonts.
Prints a JSON summary. Exit 1 if loading or --wait-for fails (or page errors with --strict).
Run under the governor: governor.sh node shoot.js ...`;

const fs = require('fs');
const path = require('path');
const { pathToFileURL } = require('url');
const L = require('./_lib.js');

function die(msg) { process.stderr.write(`shoot: ${msg}\n`); process.exit(2); }
const esc = (s) => String(s).replace(/[&<>"']/g, (c) => ({ '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;' }[c]));

function pngSize(buf) { return { width: buf.readUInt32BE(16), height: buf.readUInt32BE(20) }; }

function fontMime(p) {
  return { '.otf': 'font/otf', '.woff': 'font/woff', '.woff2': 'font/woff2' }[path.extname(p).toLowerCase()] || 'font/ttf';
}

// -> [{data(base64), mime, range?}]
function normFontParts(v, mime = 'font/ttf') {
  if (!v) return [];
  if (typeof v === 'string') {
    const t = v.trim();
    if (t.startsWith('[') || t.startsWith('{')) return normFontParts(JSON.parse(t), mime);
    return [{ data: t.replace(/^data:[^,]*,/, ''), mime }];
  }
  if (Array.isArray(v)) return v.flatMap((p) => normFontParts(p, mime));
  if (typeof v === 'object' && v.data) return [{ data: String(v.data).replace(/^data:[^,]*,/, ''), mime, range: v.range }];
  throw new Error('font data must be base64 text, {data, range} or an array of those');
}

function wrapperHtml({ png, size, title, labels, fontParts, labelSize }) {
  const faces = fontParts.map((p) =>
    `@font-face{font-family:"ForgeLabel";src:url(data:${p.mime};base64,${p.data});${p.range ? `unicode-range:${p.range};` : ''}}`).join('\n');
  const fam = fontParts.length ? '"ForgeLabel",' : '';
  const labs = labels.map((l) => {
    const c = esc(l.color || '#ffd54a');
    return `<div class="dot" style="left:${+l.x}px;top:${+l.y}px;background:${c}"></div>` +
      `<div class="lab" style="left:${+l.x}px;top:${+l.y - 7}px;border-color:${c}">${esc(l.text)}</div>`;
  }).join('\n');
  return `<!doctype html><html><head><meta charset="utf-8"><style>
${faces}
html,body{margin:0;background:#111}
.title{font:600 ${Math.round(labelSize * 1.35)}px ${fam}sans-serif;color:#fff;background:#000;padding:8px 12px;width:${size.width - 24}px}
.wrap{position:relative;width:${size.width}px;height:${size.height}px;overflow:hidden}
.wrap img{display:block}
.dot{position:absolute;width:8px;height:8px;margin:-4px 0 0 -4px;border-radius:50%;box-shadow:0 0 0 2px #000}
.lab{position:absolute;transform:translate(-50%,-100%);font:${labelSize}px/1.25 ${fam}sans-serif;color:#fff;
 background:rgba(0,0,0,.75);border:1px solid;border-radius:4px;padding:2px 6px;white-space:nowrap}
</style></head><body>
${title ? `<div class="title">${esc(title)}</div>` : ''}
<div class="wrap"><img src="data:image/png;base64,${png.toString('base64')}">
${labs}
</div>
<script>
// keep labels inside the image
for (const el of document.querySelectorAll('.lab')) {
  const r = el.getBoundingClientRect(), W = ${size.width};
  if (r.left < 2) el.style.left = (parseFloat(el.style.left) + 2 - r.left) + 'px';
  else if (r.right > W - 2) el.style.left = (parseFloat(el.style.left) - (r.right - W + 2)) + 'px';
  if (r.top < 0) el.style.top = (parseFloat(el.style.top) - r.top + 2) + 'px';
}
</script></body></html>`;
}

(async () => {
  let a;
  try {
    a = L.parseArgs(process.argv.slice(2), { bool: ['strict', 'help'], multi: ['storage', 'init', 'eval-before', 'label'] });
  } catch (e) { die(e.message); }
  if (a.help || !a.url) { process.stderr.write(USAGE + '\n'); process.exit(a.help ? 0 : 2); }

  let url = a.url;
  if (!/^[a-z][a-z0-9+.-]*:/i.test(url)) {
    const [p, q] = url.split(/\?(.*)/s);
    if (!fs.existsSync(p)) die(`no such file: ${p}`);
    url = pathToFileURL(path.resolve(p)).href + (q ? '?' + q : '');
  }
  const viewport = L.parseViewport(a.viewport);
  const out = path.resolve(a.out || path.join(L.forgeDir(), 'shots', `shot-${new Date().toISOString().replace(/[:.]/g, '-')}.png`));
  fs.mkdirSync(path.dirname(out), { recursive: true });
  const timeout = +(a.timeout || 30000);
  const labelSize = +(a['label-size'] || 16);

  // labels given up front
  let labels = [];
  for (const s of a.label || []) {
    const m = /^\s*(-?[\d.]+)\s*,\s*(-?[\d.]+)\s*,(.*)$/s.exec(s);
    if (!m) die(`--label wants "x,y,text", got: ${s}`);
    labels.push({ x: +m[1], y: +m[2], text: m[3] });
  }
  if (a.labels) labels = labels.concat(JSON.parse(fs.readFileSync(a.labels, 'utf8')));

  let fontParts = [];
  let fontSource = null;
  try {
    if (a.font) { fontParts = [{ data: fs.readFileSync(a.font).toString('base64'), mime: fontMime(a.font) }]; fontSource = a.font; }
    else if (a['font-b64']) {
      const v = a['font-b64'].startsWith('@') ? fs.readFileSync(a['font-b64'].slice(1), 'utf8') : a['font-b64'];
      fontParts = normFontParts(v); fontSource = a['font-b64'].startsWith('@') ? a['font-b64'] : 'base64 arg';
    }
  } catch (e) { die(`font: ${e.message}`); }

  const { chromium } = L.requirePlaywright('shoot.js');
  L.governorNote('shoot.js');
  const report = { out, url, ok: false, ms: 0, waitFor: null, errors: [], labels: 0, font: null };
  const t0 = Date.now();
  const browser = await chromium.launch({ args: ['--enable-unsafe-swiftshader'] });
  let code = 0;
  try {
    const ctx = await browser.newContext({ viewport });
    const page = await ctx.newPage();
    page.on('pageerror', (e) => report.errors.push(`pageerror: ${e.message}`.slice(0, 300)));
    page.on('console', (m) => { if (m.type() === 'error') report.errors.push(`console.error: ${m.text()}`.slice(0, 300)); });
    for (const s of a.storage || []) {
      const i = s.indexOf('=');
      if (i <= 0) die(`--storage wants KEY=VALUE, got: ${s}`);
      await page.addInitScript(([k, v]) => localStorage.setItem(k, v), [s.slice(0, i), s.slice(i + 1)]);
    }
    for (const js of a.init || []) await page.addInitScript({ content: js });

    await page.goto(url, { waitUntil: 'load', timeout });
    for (const js of a['eval-before'] || []) await page.evaluate(js);
    if (a['wait-for']) {
      try {
        await page.waitForFunction(a['wait-for'], null, { timeout, polling: 100 });
        report.waitFor = 'ok';
      } catch (e) { report.waitFor = `timeout after ${timeout} ms`; code = 1; }
    }
    await L.pressKeys(page, L.parseKeys(a.press));
    await page.waitForTimeout(+(a.wait || 300));
    if (a['labels-eval']) {
      const extra = await page.evaluate(a['labels-eval']);
      if (!Array.isArray(extra)) throw new Error('--labels-eval must return an array of {x,y,text}');
      labels = labels.concat(extra);
    }
    if (a['font-from-page']) {
      fontParts = normFontParts(await page.evaluate(a['font-from-page']));
      fontSource = `page: ${a['font-from-page']}`;
    }
    const target = a.selector ? page.locator(a.selector).first() : page;
    const png = await target.screenshot();
    await ctx.close();

    if (labels.length || a.title) {
      const size = pngSize(png);
      const wctx = await browser.newContext({ viewport: size });
      const wp = await wctx.newPage();
      await wp.setContent(wrapperHtml({ png, size, title: a.title, labels, fontParts, labelSize }), { waitUntil: 'load' });
      await wp.evaluate(() => document.fonts.ready);
      const sample = [a.title || '', ...labels.map((l) => l.text)].join('').slice(0, 200) || 'A';
      report.font = { source: fontSource, parts: fontParts.length,
        loaded: fontParts.length ? await wp.evaluate((s) => document.fonts.check('16px "ForgeLabel"', s) &&
          [...document.fonts].some((f) => f.family.replace(/"/g, '') === 'ForgeLabel' && f.status === 'loaded'), sample) : false };
      await wp.screenshot({ path: out, fullPage: true });
      await wctx.close();
    } else {
      fs.writeFileSync(out, png);
    }
    report.labels = labels.length;
  } catch (e) {
    report.errors.push(`failed: ${e.message.split('\n')[0]}`);
    code = 1;
  } finally {
    await browser.close().catch(() => {});
  }
  if (a.strict && report.errors.length) code = 1;
  report.ms = Date.now() - t0;
  report.ok = code === 0;
  process.stdout.write(JSON.stringify(report, null, 2) + '\n');
  process.exit(code);
})().catch((e) => die(e.stack || e.message));

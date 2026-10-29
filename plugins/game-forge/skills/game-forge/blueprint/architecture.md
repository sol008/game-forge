# Engine architecture

The layer map for a fresh engine. It is distilled from Shorelight (vanilla-JS HTML5 RPG, optional Three.js layer, ~150k lines, runs from `file://`) and keeps what worked, minus the coupling the survey found (`research/repo_survey.md` in the source repo `sol008/game-forge` §4).

Tags used below:
- **[G]** genre-neutral: every game has it.
- **[RPG]** RPG-specific: swap or drop it for other genres.
- **[3D]** only when the render mode is 3D.

Pointers of the form `see shorelight:path` are for games rated **similar** under the reference policy (PLAN §9). Clean-room games ignore them.

---

## 1. Ground rules (offline from `file://`)

The shipped game is a folder the player double-clicks. No server, no install, no network. That forces:

| Rule | Why | Consequence |
|---|---|---|
| **Classic `<script>` tags only, no ES modules** | Chrome blocks module imports over `file://` (CORS) | Every file is an IIFE that attaches to one global, `window.G` |
| **No `fetch`/XHR, no JSON files** | Same CORS block | Data, maps, dictionaries and fonts are `.js` files that call a register function (`G.Maps.define`, `G.I18N.add`) |
| **No CDN, no web fonts at runtime** | Offline | The font is base64 woff2 inside a JS file (`fontdata.js`), registered with the `FontFace` API at boot |
| **Vendored three.js as an IIFE** | three ships as ES modules | `tools/build/` bundles three plus the addons you use (composer, passes, `BufferGeometryUtils`, `SkeletonUtils`…) with esbuild into `js/vendor/three.bundle.js` → `window.THREE`. Commit the bundle; rebuild only on upgrade. See shorelight:tools/build/ |
| **No `ctx.filter`** | Safari ignores it | Pre-render effects into cached canvases |
| **`'use strict'` everywhere** | Catches typos in a 100k-line global namespace | — |
| **Saves in `localStorage`** under a `CONFIG.id` prefix | Only storage available offline | The launcher pins a dedicated browser profile so saves survive browser updates |
| **Paths with spaces and CJK must work** | Players unzip anywhere | The launcher percent-encodes the path; the release gate unzips into such a path |

## 2. Layers

```
content   game/config.js · data/* · maps/chN_*.js · story/* · i18n/<lang>_*.js · art specs · songs
   ▲  registers into
engine    scene · dialog · script(S API) · map · battle[RPG] · menu · shop[RPG] · minigames · worldmap · playstats · debug · title
   ▲
gfx       registry (Tiles/Objects/Monsters/Sprites) · ui toolkit · fx · art kits
   ▲
r3d [3D]  core · materials · models · batch · mapview · env · chars · battleview · vfx
   ▲
core      util · render · input · audio · music engine · i18n · font · state/save
```

Lower layers never name anything from higher ones. The engine reaches content only through registries and `G.CONFIG` (see `config_first.md`).

### 2.1 Core [G]

| Module | Owns | Contract notes |
|---|---|---|
| `util` | `G` itself (`W`, `H`, `TILE`, `S` scale, `time`, `debug`), math, easing, deterministic `hash`/`seeded` noise, colour helpers, `makeCanvas` (HiDPI offscreen), game-time `Timers` and `Tweens` (both promise-based), `warnOnce` | Timers run on game time so pause and test fast-forward work. See shorelight:js/core/util.js |
| `render` | Main canvas, backing-store scale `G.S` = DPR × fit (clamped 1–2), letterbox resize, fullscreen; text helpers; fade/flash/shake overlays; `snapshot` | Text helpers are the **layout-safety layer**: `text`, `wrap` (CJK no-line-start punctuation + Latin word wrap), `fit`/`textClip` (shrink to a min size, then ellipsis), inline colour markup `{y}…{/}`. All UI calls them, so every language fits. See shorelight:js/core/render.js |
| `input` | Key/pad/mouse → **actions** (`ok`, `cancel`, `menu`, `up`…); `pressed` (consumed), `held`, `repeat`, `clear` | Real DOM events only feed a table; tests must drive real `keydown` too. `_press` exists but is not the only path (PLAN §7) |
| `audio` | WebAudio synth, buses (music/sfx/reverb), named SFX, `unlock()` on first input | No audio files needed |
| `music` | **Sequencer only**: parse song data, schedule notes, loop seams, crossfade, `play(id)`/`stop()`, `play(null)` = silence | Songs live in content (`content/songs.js`) |
| `i18n` | `G.T(s)`: exact dictionary → `%s`/`%d` templates → fallback to source; shared table plus per-chapter tables that only fill gaps | Source language is a CONFIG value, not hard-coded CJK detection |
| `font` | Registers the bundled face, then a system fallback stack; `G.font(size,bold)` picks a per-language stack | Face name and probe string come from CONFIG |
| `state` | `settings` (own key), `newState()`, party/inventory/flags/quests/collectibles, `Save` (slots, autosave slot 0, meta + thumbnail, quota retry) | Keys are `CONFIG.id + '_save_' + slot`. Migrations on load |

### 2.2 Engine

| Module | Tag | Responsibility |
|---|---|---|
| `scene` | G | Stack of `{update, draw, opaque, enter, exit, resume, bgUpdate, statKind, sceneName}`. Only the top updates; drawing starts at the highest opaque scene; `base()` tells the loop which scene decides 2D vs 3D. See shorelight:js/engine/scene.js |
| `dialog` | G | Portrait box, typewriter, choices, narration, backlog, auto/skip. Speaker names come from a generated name table |
| `script` | G | `G.Script.run(async S => …)`: the cutscene/event API (§4). A `busy` counter blocks re-entry |
| `map` | G (top-down) | `MapScene`: tiles, actors, NPCs, events (`auto`/`action`/`touch`), warps, chests, roaming enemies, lighting, camera. The 2D map is the **source of truth** for gameplay even in 3D |
| `mapmech` | G | Guards, wind, push blocks: optional mechanics plugged into `MapScene` |
| `battle` | RPG | Turn/CTB battle scene, formulas, statuses, phases. Calls `view3d` hooks when present. Other genres replace this with their core-loop scene |
| `autobattle` | RPG | The player-facing AI; also the test bot. Per-fight tactics come from a registry |
| `menu`, `shop` | RPG (menu shape is G) | Pause menu panels, save/load, settings, shop |
| `minigames` | G | Timing / mash / rhythm scenes; resolve with a result; succeed instantly under autoplay |
| `worldmap` | G engine + content | Travel animation engine; places and coastline are content |
| `playstats` | G | Idle-aware play clock and the Play Stats page (`debug_hooks.md` §7) |
| `debug` | G | URL jump surface, test helpers, F2 menu (`debug_hooks.md`) |
| `title`, `story` | G | Title scene, new game, chapter chaining (`G.Story.next(S, n)`), point-of-no-return prompt |

### 2.3 gfx registry [G]

Art modules **register**; the engine only calls the registry's draw APIs. One registry per kind: `Tiles`, `Objects`, `Monsters`, `Sprites`, `Portraits`, `Backdrops`. Rules:
- `define(id, def)` merges defaults (solid, w/h…). `get(id)` falls back to a `void`/placeholder so a missing art id never throws.
- **Draw isolation**: the registry saves and restores the full context (transform included) around every art draw. One art function that leaves a transform behind must not corrupt the frame. This is a conformance test.
- Static art is pre-rendered into cached canvases keyed by id + variant + state; variation comes from `U.hash`, never `Math.random`.
- Live instance params may be getters (`picked: () => flag('x')`), read through one helper.

See shorelight:js/gfx/registry.js.

### 2.4 3D layer [3D]

| Module | Responsibility |
|---|---|
| `r3d/core` | WebGL canvas inserted **under** the 2D canvas; both canvases resized in lockstep. Quality presets; composer chain (render → bloom → grade/vignette → output → SMAA); `setView(view)`, `render(dt)`, `project()` world→UI coords; `mergeStatic`; `dispose`. `lite` mode: half resolution, no shadows, no post. Units: 1 unit = 1 tile |
| `materials` | Shared toon/env materials, cached by params so few shader programs compile |
| `models` | `Models.define(id, {build(o,K), variants, key, update, lights, occluder, batch})`; a build kit (cached materials, box/cyl/merge helpers). **Billboard fallback**: an id with no 3D model renders its 2D registry art on a camera-facing card, so 3D never blocks on missing assets |
| `chars` | Procedural or rigged characters built from the same spec as the 2D sprite; sprite billboard fallback |
| `batch` | Instanced batching of repeated static objects per 16×16 chunk (§6). On by default; `?nobatch` turns it off |
| `mapview` | `Map3D(mapScene)`: ground, walls with camera-side cutaway, water, objects, actors, lights, particles, diorama camera; mirrors the 2D map every frame |
| `env` | Sky, fog, sun/moon, weather, water; per-map presets |
| `battleview` | `Battle3D(battleScene)`: arena + camera choreography, behind hooks (`onAction`, `onDamage`, `onKill`, `beforeFinish`, `outro`) |
| `vfx` | Skill/impact effects by id; returns the impact time so the battle waits on it |
| asset libraries | Content: one file per team (cast, animals, architecture, nature, props, monsters) |

See shorelight:js/r3d/{core,models,batch,mapview}.js.

## 3. Script load order (a parsed contract)

`index.html` is the **only** manifest. The test loader, packager, validator, font builder and i18n extractor all read its `<script src>` list. Keep it machine-readable:

```html
<!-- order: config → core → vendor/r3d → gfx → i18n → data → engine → story → maps → main -->
<script src="js/game/config.js"></script>
<script src="js/core/util.js"></script>
<script src="js/core/fontdata.js" onerror="void 0"></script>   <!-- optional, generated -->
<!-- … -->
<!-- MAPS-BEGIN -->
<script src="js/maps/sandbox.js"></script>
<script src="js/maps/ch1_harbour.js"></script>
<!-- MAPS-END -->
<script src="js/main.js"></script>
```

Rules:
- One tag per line, plain `src="…"`, no inline scripts, no dynamic loading.
- `config.js` loads first; nothing in core may read CONFIG at parse time without it.
- Chapter files sit between `MAPS-BEGIN`/`MAPS-END`, so tools can load "engine + chapter N only".
- A new file is not live until it is listed. The validator fails on a `.js` under `js/` that is not listed, and the packager fails on a listed file that is missing.

## 4. Boot and main loop

```js
window.addEventListener('load', async () => {
  G.Render.init();
  try { G.R3 && G.R3.init(); } catch (e) { G.R3.ok = false; }   // 3D failure → 2D, never a crash
  await G.loadFonts();                                            // capped wait; system font fallback
  G.Title.start();
  if (G.debug) G.Debug.init();                                    // URL jumps run after boot
  requestAnimationFrame(frame);
});
function frame(now) {
  requestAnimationFrame(frame);
  const raw = G.clockDelta(now), dt = Math.min(0.05, raw);       // clamp long frames
  try {
    G.Input.update(dt); G.Timers.update(dt); G.Tweens.update(dt);
    G.Scenes.update(dt); G.PlayStats.tick(raw);                   // stats use the unclamped time
    const base = G.Scenes.base(), use3d = G.R3?.enabled() && base?.view3d;
    G.R3?.show(use3d); G.Render.clear(use3d);                     // transparent 2D over 3D, else black
    G.Scenes.draw(G.ctx); G.Render.drawOverlays();
  } catch (e) { console.error(e); G.lastError = e; }              // tests fail on G.lastError
  G.Input.endFrame();
}
```

The test harness replicates `update` + `draw` with a fixed `dt` (fast-forward), so keep the per-frame step in one function both can call.

**Script runner invariants.** When the last running script ends, the runner must: close the dialog, clear `scripted` on all actors, release the camera to the player (unless `cameraHold`), refresh the map and clear input. These are conformance tests. See shorelight:js/engine/script.js.

## 5. 2D vs 3D strategy

- **One gameplay model, two views.** `MapScene` and `BattleScene` own all state, collision and timing. `Map3D`/`Battle3D` read them and draw. Deleting the 3D layer must leave a complete game.
- **Stacked canvases.** WebGL below, 2D above. In 3D the 2D canvas is cleared to transparent and carries only UI (dialog, HUD, menus, toasts, fades). Fades stay on the 2D overlay so they cover both.
- **Every visual hook has both paths.** A scene or map that draws anything must say what happens in 3D:

| Hook | 2D path | 3D path |
|---|---|---|
| Map `drawGround` / `drawOver` | Canvas drawing | Routed to a ground decal / screen overlay through a split context; upright things need an `update3d` mirror |
| Map `build3d(view, THREE)` | — | Extra set dressing |
| Object/actor art | Registry draw | `Models` id, else billboard |
| Battle action/damage/kill/finish | 2D fx list | `view3d.on…` hooks; `vfx` returns impact time |
| Emotes, damage numbers, prompts | Drawn at tile coords | Drawn on the 2D canvas at `R3.project()` coords |

- The validator lists hooks with only one path. The 3D sweep renders every map in `?r3lite` and reports billboard fallbacks and `warnOnce` counts.
- Test every chapter in the player's **default** render mode (PLAN §7).
- The `render3d` setting applies after a reload; a WebGL failure falls back to 2D automatically.

## 6. Performance budgets

Shorelight's 175-map sweep: median 79 draw calls, 187k triangles; the worst map had 494 calls (one node per bamboo). Batching cut the maximum across all maps to 204 and the heavy maps by 22–87 %. See shorelight:docs/qa/sweep3d.md.

| Budget | Target | Checked by |
|---|---|---|
| Draw calls per map (r3lite) | median ≤ 100, max ≤ 250 | 3D sweep |
| Static prop model | ≤ 6 draw calls after `merge` | model contract test |
| Character | ≤ 3 calls (+1 halo); boss ≤ 8 | lineup render |
| Map build time (SwiftShader) | ≤ 8 s | 3D sweep |
| 2D frame | ≤ 8 ms CPU at 1280×720 | e2e fps probe |
| Zip size | ≤ 20 MB (font subset included) | release gate |

**Batching is on by default.** Repeated static objects (no `if`, no spirit/illusion, no alpha, no per-object update) of the same model variant become one `InstancedMesh` per mesh per chunk. Blended decals sort back to front like separate meshes. `?nobatch` exists only to A/B-compare pixels and draw calls.

## 7. Packaging

`tools/package.sh` builds `dist/<Title>-<ver>-<date>.zip` with a single top folder:
1. Copy exactly the files `index.html` references (fail on a missing one), plus `index.html`.
2. **Rebuild the font subset** from every character in `js/**` (all languages) so shipped glyphs match shipped text. A rebuild failure fails the build.
3. Add the launcher, PLAYING.md, licences (font OFL), the guide, and `electron-main.js` + `package.json`.
4. Normalise permissions (launcher stays executable), drop OS junk, zip with unix modes.

- **Launcher** (macOS `.command`): opens `index.html` in Chrome/Edge/Brave app mode with a dedicated profile under `~/Library/Application Support/<Title>/`, `--autoplay-policy=no-user-gesture-required` and `--ignore-gpu-blocklist`; falls back to Safari or the default browser; a `lite` argument adds `?r3lite`.
- **Electron option**: loads the same `index.html` over `file://`. Sandboxed, no node integration, a fixed `userData` path, single-instance lock, storage flushed on quit. Not required to play.
- **Font subsetting**: `tools/build_font.py` scans sources, fetches the font's unicode-range slices, subsets them with fontTools, and writes base64 parts. Face name and source URL are parameters. Run it at package time, never by hand only.

See shorelight:tools/package.sh, shorelight:tools/build_font.py, shorelight:electron-main.js.

## 8. Swapping RPG modules for other genres

| RPG module | Replace with (examples) | Keep |
|---|---|---|
| `battle`, `autobattle` | Real-time combat scene, puzzle board, race | Scene contract, `view3d` hook pattern, a player-facing AI that doubles as the test bot |
| `menu` panels, `shop`, party/equip in `state` | Inventory-lite, upgrade tree | Save/settings/Play Stats panels |
| `map` (top-down tiles) | Side-scroller level, board | Event/warp/script model, the 2D-truth/3D-view split |
| `data/enemies` helpers | Level/wave tables | The curve-plus-roster split (`config_first.md` §5) |

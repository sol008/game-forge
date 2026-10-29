# Config first: keep game vocabulary out of the engine

Shorelight's engine was written for one game, so its vocabulary leaked into ~10 engine files. A starter extracted from it would need edits across core, engine, gfx and r3d. A fresh engine avoids that by obeying four rules from the first commit:

1. All game vocabulary goes in **one `G.CONFIG`**.
2. Cast and NPC names are **generated from data**.
3. Content extends the engine through **hook registries**, never by reassigning engine functions.
4. **Kit** (reusable machinery) and **content** (this game's data) live in separate files.

## 1. What leaked, and where (evidence)

From `research/repo_survey.md` §1 "Leaks". Line numbers refer to the Shorelight tree.

| Leak | Evidence | Rule it breaks |
|---|---|---|
| Save, settings and ledger keys `shorelight_*` | state.js:11,16,279; playstats.js:19 | 1 |
| Currency `文` hard-coded | script.js (gold toast, inn), battle.js:1267, menu.js:108,238, shop.js:16,23,77,126 | 1 |
| Stat names 生命/真氣/武力… | menu.js:8, battle.js:1276–1279 | 1 |
| Gauge name 劍意 | battle.js:1138–1141, menu.js:329,453 | 1 |
| 五行 element names, cycle, colours | battle.js:6–7, 805, 1366 | 1 |
| Collectible 心燈 + threshold 14 welded into core | state.js:264, script.js `S.lantern`, fx.js:346–386, menu.js:50,543 | 1 |
| Vision mechanic text 靈視 | map.js:334,987 | 1 |
| Game-over text and art | battle.js:1752–1758 | 1 |
| Report title, font face, probe string | playstats.js:307,354; font.js:22; util.js:120 | 1 |
| Whole cast in an engine table | dialog.js:3–9 | 2 |
| Cast id `xinghe` as a fallback | title.js:141, debug.js:15, map.js:813, mapview.js:495, story.js:8 | 2 |
| Chapter hacks in debug (`n >= 7` join/leave) | debug.js:18 | 2, 3 |
| Chapters wrapping `G.Battle.start` / `sc.startTurn` | ch1:484, ch4:341, ch7:734, ch5:2553 | 3 |
| Boss tactics keyed to enemy and cast ids inside the AI | autobattle.js:86– | 3 |
| Per-character ultimate VFX switch; arena presets in the view | vfx.js:1544–1547; battleview.js:1149+ | 3 |
| Sequencer and 1,270 lines of songs in one file | music.js:1–110 vs 111–end | 4 |
| Sprite/portrait kit mixed with cast specs | gfx/sprites.js, gfx/portraits.js | 4 |
| World-map engine mixed with a Formosa coastline | worldmap.js:34 | 4 |

None of these broke the game; all of them made reuse, translation and testing harder. The chapter monkey-patches also made battle behaviour depend on which chapter file loaded last.

## 2. `G.CONFIG`

`js/game/config.js` is the first script in `index.html`. Engine code reads vocabulary only from here, so the i18n layer translates every string through the same path.

```js
// js/game/config.js: loaded first; the only file a reskin must touch for vocabulary
G.CONFIG = {
  id: 'emberroad', version: '0.1.0',             // id → save/settings/ledger keys, launcher profile dir
  title: { src: '燼路', en: 'Ember Road' },
  sourceLang: 'zh', langs: ['zh', 'en'],
  currency: { name: '銖', fmt: (n) => `${n} 銖` },
  stats: { mhp: '氣血', mmp: '靈力', atk: '攻', def: '守', mag: '術', spd: '速', luk: '運' },
  levelCap: 50, equipSlots: ['weapon', 'armor', 'head', 'feet', 'acc'],
  gauge: { id: 'resolve', name: '決意', max: 100 },          // null = no gauge
  elements: { order: ['fire', 'water', 'wood'], beats: { fire: 'wood', wood: 'water', water: 'fire' },
              names: { fire: '火', water: '水', wood: '木' }, colors: { fire: '#ff7a4a', water: '#5ab0ff', wood: '#6ad07a' } },
  collectible: { id: 'ember', name: '餘燼', icon: 'ember', threshold: 9, endings: { met: 'true', unmet: 'normal' } },
  vision: { id: 'insight', name: '洞見', defaultSec: 60 },  // null = no vision mechanic
  defaultParty: ['lead'], startMap: 'ember_quay',
  font: { face: 'GameSerif', probe: '燼路', srcCss: '<google-fonts-css-url>' },
  text: { gameOver: '火光熄滅了……', retry: '重新挑戰', objective: '目標：%s' },
};
```

Derived helpers live in core, next to their users, never in content:

```js
G.key = (k) => `${G.CONFIG.id}_${k}`;               // G.key('save_3'), G.key('settings'), G.key('playstats')
G.money = (n) => G.CONFIG.currency.fmt(n);
G.statName = (k) => G.CONFIG.stats[k] || k;
G.elemBeats = (a, b) => G.CONFIG.elements.beats[a] === b;
```

Rules:
- A field that a genre doesn't use is `null`, and the engine hides the UI for it (no gauge bar, no vision HUD).
- The **collectible** is a generic counter (`G.Collect.add(id)`, `count()`, `meetsThreshold()`). Its pickup cutscene is a registered FX, not core code.
- `CONFIG` holds **no** cast ids except `defaultParty`, and holds no map ids except `startMap`.
- The intake's requirements fields map 1:1 onto this object. `docs/REQUIREMENTS.md` → `config.js` is a mechanical step in phase 2.

## 3. Names from data

```js
// engine/names.js: built once after data loads; dialog, menus and toasts use only these
G.Names = {
  full: (id) => (G.Data.chars[id] || G.Data.npcs[id] || {}).name || id,
  short: (id) => (G.Data.chars[id] || G.Data.npcs[id] || {}).short || G.Names.full(id),
  known: (id) => !!(G.Data.chars[id] || G.Data.npcs[id]),
};
```

- Party members come from `data/characters.js`, and story NPCs from `data/npcs.js` (`{name, short, portrait, sprite}`).
- **No cast id appears under `js/core`, `js/engine`, `js/gfx/registry.js` or `js/r3d/{core,models,mapview,batch,env}`.** Every fallback sprite is `CONFIG.defaultParty[0]` or a generic placeholder. A lint enforces it (§7).
- Debug and story read party composition from `G.Data.progression[ch].party`, never from literals.

## 4. Hook registries instead of monkey-patching

Content must **register**, never reassign `G.Battle.start`, `scene.startTurn` or any other engine function. Every registry has the same shape: an id, an optional `when(ctx)` guard, a handler, and errors caught per hook and reported through `warnOnce` plus `G.lastError`.

### 4.1 Battle hooks [RPG]

```js
// engine side: battle.js
G.Battle.hooks = [];   // {id, when(sc), intro?(sc), onTurn?(sc,u), onDamage?(sc,tg,dmg), onEnd?(sc,r)}
G.Battle.addHook = (h) => { if (!G.Battle.hooks.some((x) => x.id === h.id)) G.Battle.hooks.push(h); };
async function runHooks(sc, name, ...args) {
  for (const h of G.Battle.hooks) {
    if (!h[name] || (h.when && !h.when(sc))) continue;
    try { const r = await h[name](sc, ...args); if (r === 'skip') return 'skip'; }
    catch (e) { G.warnOnce('battle hook ' + h.id + '.' + name, e); G.lastError = e; }
  }
}
// content side: maps/ch2_mill.js
G.Battle.addHook({ id: 'c2_millwheel', when: (sc) => sc.troopId === 't_c2_miller',
  onTurn: async (sc, u) => { if (u.boss && sc.turn % 3 === 0) await sc.say('水車加速了！'); } });
```

Per-battle options (`S.battle(troop, {intro, onTurn, turnLimit, loseOk})`) stay for one-off fights. The registry is for anything that applies to a group of fights (a chapter's shared intro, a boss rule).

### 4.2 Auto-battle tactics [RPG]

```js
G.AutoBattle.tactics = {};                          // keyed by enemy id; read only what the screen shows
G.AutoBattle.registerFight = (enemyIds, t) => { for (const id of enemyIds) G.AutoBattle.tactics[id] = t; };
// content: maps/ch5_shrine.js, next to the boss it explains
G.AutoBattle.registerFight(['c5_bell_ward'], {
  focus: ['c5_bell_ward'],                                    // break this first
  pick: (sc, u, h) => (sc.c5?.window ? { kind: 'defend' } : null),  // null = default policy
});
```

The player-facing AI and the test bot are the same code, so a boss whose rule needs a tactic must register one. The boss simulator fails a boss with an on-screen rule and no tactic.

### 4.3 3D arenas and VFX [3D]

```js
G.Battle3D.arenas = {};    // backdrop id → {sky, fog, light, ground, kit, post}
G.Battle3D.defineArena = (id, def) => { G.Battle3D.arenas[id] = def; };
G.VFX3D.ultimates = {};    // char id → (vfx, user, targets, skill) => impactTimeSec
G.VFX3D.defineUltimate = (charId, fn) => { G.VFX3D.ultimates[charId] = fn; };
// engine fallback, never a switch on cast ids:
const ult = G.VFX3D.ultimates[u.id] || ((v, u2, t, s) => v.play(elemOf(u2) + '_big', u2, t, s));
```

The arena presets go in `r3d/arenas_<region>.js` (content) and the ultimates go in `r3d/vfx_cast.js` (content). A backdrop with no arena uses a neutral default plus `warnOnce`, so the 3D sweep reports it.

### 4.4 Other registries worth having from day 1

| Registry | Replaces |
|---|---|
| `G.FX.define(id, SceneClass)` (collectible-get, title cards) | `LanternGet` in fx core |
| `G.Story.chapters[n] = {title, run}` | `G.Chapters` titles in title.js |
| `G.Minigames.define(id, Scene)` | Cultural minigames inside the engine file |
| `G.Env3D.terrains[id]` | Special terrain ids in env.js |
| `G.PointOfNoReturn` messages from CONFIG | Prompt text naming the collectible |

## 5. Kit vs content files

| Kit (engine, reusable) | Content (this game) |
|---|---|
| `core/music_engine.js`: sequencer, instruments, loop/crossfade | `content/songs.js`: `G.Music.define(id, song)` |
| `gfx/sprite_kit.js`, `gfx/portrait_kit.js`: body/face builders | `content/cast_specs.js`: one spec per character (palette, hair, outfit, props) |
| `data/enemy_kit.js`: `base`, `variant`, `troop`, `boss`, `area`, `enemyCurve(L)` | `data/enemies_chN.js` rosters, `progression` table |
| `engine/worldmap.js`: travel animation, node graph | `content/world.js`: places, coastline/geometry, routes |
| `r3d/models.js` + build kit | `r3d/<team>_*.js` asset libraries |
| `engine/minigames.js`: timing, mash, rhythm | Culture-specific minigames as registered scenes |

A rule of thumb: if the file would survive into a game with a different setting, it is kit, and it may not contain a single content id or source-language literal except through CONFIG.

## 6. Id namespacing

Ids are ASCII `snake_case`. Prefixes make ownership greppable and let several builders work in parallel without collisions.

| Kind | Pattern | Example |
|---|---|---|
| Flags | `chN_<what>` | `ch3_bridge_fixed` |
| Quests | `q_cN_<name>` | `q_c3_lost_net` |
| Collectibles | **derived**: `<collectible.id>_<quest suffix>`, never typed | `ember_c3_lost_net` |
| Chapter-local items/skills/enemies | `cN_<name>` | `c3_net_charm` |
| Troops | `t_cN_<name>` | `t_c3_eels` |
| Maps | `<place>[_<sub>]`, unique game-wide, no chapter prefix | `tamsui_fort`, `pier_b1` |
| Events/NPCs | unique within their map; global if a test refers to them | `intro`, `ferryman` |
| Shared data | no prefix, defined only in `js/data` | `herb`, `fire_1` |

- Each builder brief grants an **exclusive new-file namespace** (`maps/ch3_*`, `i18n/en_ch3*.js`, `r3d/props_ch3.js`), the `ch3_` flag prefix and the `c3_` data prefix. File names may carry the chapter; map ids do not.
- `docs/canon/collectibles.json` is the **plan list** (name, chapter, quest id). The validator derives each collectible id from its quest and checks the list against the code both ways.
- Dynamic ids (`'ch3_bell_' + i`) must be declared as a pattern in `content/flags.json` so the flag set/read check can match them.
- Names (display strings) are unique across characters, items and skills (PLAN §7).

## 7. Enforcement (validator / lint checks)

| Check | Fails when |
|---|---|
| `no-cast-in-engine` | Any id from `G.Data.chars`/`npcs` appears in a kit file |
| `no-vocab-in-engine` | A source-language literal in a kit file is not in an allowlisted UI string table (UI strings go through `G.T` from `i18n/ui_*.js`) |
| `no-monkey-patch` | Content assigns to `G.<Engine>.<fn> =` or `<scene>.<method> =` |
| `config-keys` | `localStorage` key not built by `G.key()` |
| `registry-ids` | Hook/tactic/arena/ultimate registered for an id that doesn't exist |
| `prefix` | A chapter file defines data outside its `cN_` prefix, or a flag outside its `chN_` prefix |
| `map-ids` | Two maps share an id, or a map id is not snake_case |

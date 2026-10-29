# Shorelight repo survey: plan for extracting a starter template

Repo: `/home/user/shorelight` (437 commits, v1.0.0). It has no build step: about 85 classic scripts load in `index.html` order onto `window.G` (util.js line 3). `js/main.js` (74 lines) runs boot and the rAF loop. The vendored `js/vendor/three.bundle.js` (6,049 lines) is rebuilt by `tools/build/`.

Classifications: **E** = engine, **E/L** = engine with content leaks, **C** = content.

## 1. Inventory

| Dir | Files / lines | What it does | Class |
|---|---|---|---|
| js/core | 9 / 2,972 | util (G, U, ease, noise, makeCanvas), render (HiDPI, text, fades), input (kbd/pad/mouse), audio (WebAudio synth + SFX), music (sequencer + SONGS), i18n, font + fontdata (1.6 MB base64 woff2), state (settings/Party/Inv/Flags/Lanterns/Quests/Save) | E/L |
| js/engine | 14 / 6,398 | scene stack, dialog, script (S API), map (MapScene, actors, events, lighting), mapmech (guards/winds/push), battle (CTB), autobattle, menu, shop, playstats, worldmap, minigames, title, debug | E/L |
| js/gfx | 18 / 34,715 | registry (Tiles/Objects/Monsters), ui toolkit, fx, plus procedural art: tiles, nature, objects(2), interior, sprites, portraits(+4 baked), monsters 1-3, backdrops | registry/ui/fx: E/L. Sprite kit `sprites.js` 1–2670 and portrait kit `portraits.js` 1–1289: E. Their specs and all other art: C |
| js/r3d | 19 / 37,548 | core (WebGL under the 2D canvas, post chain), materials, models registry, batch (instancing), mapview (Map3D), env (water/sky/weather), battleview, vfx, chars (procedural humanoid from sprite specs). Asset libraries: chars_cast, animals, arch_han, arch_coast, nature, props, props_interior, props_chapter, monsters, monsters_boss | core/materials/models/batch/mapview/env/chars: E/L. battleview/vfx: E/L (content tables). The rest: C |
| js/story | 2 / 216 | story.js: newGame, `Story.next`, `pointOfNoReturn`, `ensureLevel`. ending.js: endings and credits | story.js E/L, ending.js C |
| js/maps | 13 / 44,537 | one IIFE per chapter (ch0–ch11; 175 maps), plus `test.js` (the `sandbox` map) | C (`test.js` = template seed) |
| js/data | 5 / 1,566 | characters, skills, items, enemies (+troops/areas/progression/enemyCurve), quests (5-line stub) | C (the formats are the contract) |
| js/i18n | 15 / 16,632 | en_ui, en_data, en_ch0…ch11, ch11b (`G.I18N.add({...})`) | C |
| css | 1 / 52 | letterbox and boot screen | E |
| root | index.html 131, main.js 74, electron-main.js 87, package.json, `Play Shorelight.command` (macOS app-mode launcher, dedicated browser profile), README 76, PLAYING 231, LICENSES, fonts/OFL.txt, screenshots/ | shell. Every file has naming leaks |
| tools | ~200 files | see §2. Also 13 `preview_*.html` art/music previews; `design/`, `design2/` (82 files, 22k lines, per-character portrait design sheets and bakers); `r3d/<team>/` probes and viewer | mixed |
| docs | ~60 md + images | see §5. Also CONTRACTS.md (2D art/data/formula contract), CONTRACTS_3D.md, MAP_AUTHORING.md, BUILDER_BRIEF.md, WRITERS_GUIDE.md, ART_NOTES.md, docs/story/ screenplays, r3d_reports/, design/ | process (reusable) + C |

### Leaks with examples (file:line)
- **state.js**:
  - Save keys: `shorelight_settings` (11, 16) and `'shorelight_save_'+slot` (279).
  - `Lanterns.THRESHOLD: 14` (264). Level cap 50 (178). Equip slots hard-coded (220, and `create()`).
  - The comment "HP and 真氣" (186).
- **playstats.js**: `LEDGER_KEY='shorelight_playstats'` (19). Report title `'彼岸燈'` (307). File name `shorelight-playstats-…` (354).
- **script.js**:
  - Toasts hard-code wording: `'目標：'`, `獲得 … 文錢`, `加入了隊伍`, `領悟了`, `新任務/完成`.
  - The inn dialogue uses `文`. `S.lantern` is a 心燈-specific primitive.
- **dialog.js:3–9**: `G.Names` and `G.ShortNames` list the whole cast.
- **title.js**: `G.Chapters` chapter titles (3). The fallback `Party.join('xinghe')` (141). The title background (moon, sea, lanterns) is themed art.
- **debug.js**:
  - `startch` falls back to `['xinghe']` (15). It has a `n >= 7` 白芷 join/leave hack (18) and `gold = 300*(n+1)`.
  - The default party is `xinghe,baizhi,hongying,yungui`.
- **battle.js**:
  - Elements: `ELEM_NAMES` / `BEATS` 五行 (6–7). Element colours (805, 1366).
  - `special==='cats'||'tuanzi'` (487). The 劍意 gauge label (1138–1141).
  - `' 文'` (1267). `生命/真氣` (1276–1279). Game-over text `'燈火將熄'` and a lantern (1752–1758).
- **autobattle.js:86–**: `A.FIGHTS` holds per-boss tactics keyed to enemy ids (`c7_dark_seal`, `c6_linto`…) and cast ids. A healer priority list sits at 176.
- **menu.js**:
  - `STAT_NAMES` 生命/真氣/武力… (8). The 心燈 panel (50, 543).
  - `錢財 … 文` (108, 238). 劍意 (329, 453). The render3d setting (716).
- **shop.js**: `' 文'` (16, 23, 77, 126).
- **map.js**: the LEGEND/DECO tables name Taiwan-flavoured art (10–28). Vision text `'靈視…'` (334, 987). Sprite fallback `'xinghe'` (813).
- **worldmap.js**: the whole file is a Formosa coastline plus `PLACES` (34). **minigames.js**: `jiaobei` (擲筊) is cultural; timing/mash/song are generic.
- **story.js**: `newGame` joins `'xinghe'` (8). The pointOfNoReturn strings mention 心燈.
- **music.js**: the sequencer is lines 1–110 (E). `SONGS` runs from line 111 to the end (about 1,270 lines, C).
- **font.js**: the face `QDKai` and the probe string `'彼岸燈'` (22). **util.js**: `'[shorelight]'` (120).
- **gfx/fx.js**: `LanternGet` 心燈 sequence (346–386). **gfx/ui.js**: `lanternIcon` used as a UI glyph (117).
- **r3d**:
  - `vfx.js:1544–1547` has a per-character ultimate VFX switch. `battleview.js:1149+` has arena presets keyed to backdrop ids.
  - `env.js:22–23` has special terrain (`black_sea`, `breath`, `vision`). `mapview.js:495` falls back to sprite `'xinghe'`.
- **Monkey-patching from content**: chapter files wrap `G.Battle.start` (ch1:484, ch4:341, ch7:734) and `sc.startTurn` (ch5:2553). It works, but the engine has no first-class hook registry.

## 2. Tooling

| Tool | Invocation | Inputs | Generic? |
|---|---|---|---|
| `test/load.js` | `require('./load').load({storage,search,only,skip,extra})` | index.html script order; DOM/canvas/localStorage stubs (Proxy ctx) | **Generic.** Note: no `document.currentScript`, so i18n chapter scoping is off in Node |
| `test/validate.js` (759) | `node tools/test/validate.js [-v --json --strict]` | all data, maps (real MapScene), script regex scan, flood-fill reachability, flag set/read, art/sfx/bgm/fx ids | **Mostly generic.** Hard-coded: `xinghe` (394, 430), `sandbox` (676). The S-API regexes assume this API |
| `test/unit.js` (969) | `node tools/test/unit.js [filter]` | its own `qa_*` fixtures injected into G.Data; validator self-test against `fixtures/bad_map.js` | **Generic** (3 cast refs) |
| `test/e2e.js` (1,174) | `node tools/test/e2e.js [--only --maps --troops --workers --3d --r3lite]` | Playwright `file://`; scenario tests and sweeps of every map and every troop; `ff`/`drive`/soft-lock detector | **Generic engine QA** (7 refs to xinghe/sandbox) |
| `test/run.sh` | `bash tools/test/run.sh [--quick]` | validate → unit → e2e, summary table | Generic |
| `test/lib/srcscan.js` | library | literal-key/line scanning | Generic |
| `test/lib/battlebot.js` (287) | `addInitScript`, or loaded by sims | a "sensible player" policy; names specific opener skills (迷魂扇, 天罡破法…) | Policy core generic; skill lists are C |
| `test/chapters/chN.test.js` (12 files, ~5.5k lines) | `node …/ch1.test.js [--shots --3d]` | `?debug&startch=N` + `G.Debug.autoplay`/`stepOn`/`talk`/`trigger` | C (pattern reusable) |
| `test/sidequests/chN.side.js` + `lib.js`/`lib68.js`/`spot3d.js` | `node …/ch1.side.js [filter] [--shots]` | BFS walking over real collision; real Z key via `findInteract`; never writes flags | lib.js/lib68.js generic (two divergent copies: merge them); chN files are C |
| `test/full_chain.js` (1,074) | `node tools/test/full_chain.js [--from chN --to --assist --encounters --reload-at]` | reuses the chapter drivers by cutting their runner; carries state title→endings | Tied to C; the architecture is reusable |
| `sim_battle.js` (607) | `node tools/sim_battle.js [--area --boss --prog --check]` | re-implements the formulas over `js/data/*` only | Semi-generic (needs `areas`/`progression`) |
| `sim_story.js` + `sim_story_fights.js` | `node tools/sim_story.js [--only --ch --lv -2 --ai auto --model normal]` | real G.Battle headless; injects `G.__X.chN={ev}` into each chapter IIFE; FIGHTS table (shops, kits, tactics) | Engine generic, FIGHTS is C |
| `sim_economy.js` (539) | `node tools/sim_economy.js [--maps --json --schedule --diff easy]` | STORY battle list, critical-path BFS, roaming enemies met, chests | Model generic, STORY table is C |
| `guide/build_guide.js` (1,332) | `node tools/guide/build_guide.js [--no-inline --dump --check-items]` | `docs/guide/parts/*.md`, `chapters/chNN.md` with `<!-- chart:… -->`/`<!-- table:… -->` placeholders; live data via load.js; BALANCE.md tables | Placeholder engine generic. Charts (wuxing, lanterns, cats) and Chinese headings are C |
| `guide/shoot_maps.js` | `node tools/guide/shoot_maps.js [ids] [--force]` | whole-map 2D renders, numbered chests; `maps.txt` | Generic |
| `package.sh` | `bash tools/package.sh [-o DIR] [--offline]` | copies only what index.html references; rebuilds font; adds launcher, PLAYING, guide → `dist/Shorelight-<ver>-<date>.zip` | Generic apart from naming |
| `build_font.py` | `python3 tools/build_font.py [--out]` | scans js/** for used glyphs; Google Fonts LXGW WenKai TC slices; fontTools subset → `fontdata.js` | Generic for CJK; the font URL and face name are parameters |
| `i18n/extract.js` (+GLOSSARY.md) | `node tools/i18n/extract.js [--missing]` | tokenises strings; buckets ui/data/chN; `${}` → `%s` keys; coverage report | Generic (zh→en direction assumed) |
| `r3d/sweep/sweep.js` (+probe, summary, batch_ab, contact.py) | `node tools/r3d/sweep/sweep.js --out=DIR [--resume --nobatch map:x,y]` | every map with 3D on (SwiftShader `?r3lite`): build time, draw calls, warnOnce, billboard fallbacks, JPEG | Generic (query string names the cast) |
| `r3d/viewer.html` + `shot.js` | `node tools/r3d/shot.js "kind=models&ids=…" out.png` | asset viewer | Generic |
| `render_music.js` + `.html` | `node tools/render_music.js [--ids --loops --wav --preview N]` | headless Chromium offline render: dBFS/LUFS-ish, polyphony, loop-seam checks, wav/mp3 | Generic |
| `build/build_three.js` | `node tools/build/build_three.js` (esbuild, three 0.186.1) | three-entry.js with addons → IIFE `window.THREE` | Generic |
| `preview_*.html`, `design*/` | open in a browser | art previews and character-design sheets/bakers | previews generic in shape; design/ is C |

## 3. Content authoring conventions

**Map** (`G.Maps.define(id, def)` in `js/maps/chN_<place>.js`, one IIFE per chapter):
```js
G.Maps.define('town', { name:'鎮', place:'town', bgm:'town', start:[10,20],
  light:{ambient:0.6,color:'#0a1030',playerR:220}, particles:['mist'], psychedelic:0, noSave:false,
  tiles:['XXXX','X..X'], deco:['  t '], decoLegend:{Q:'mushroom_glow'},
  objects:[{t:'house',x:4,y:3,w:4,h:3,door:1},{t:'crate',x:9,y:9,push:true},
           {t:'mushroom_harvest',x:5,y:5,picked:()=>F('x')},             // live getter (Objects.flag)
           {t:'footprint',x:3,y:3,if:st=>…,live:true,spirit:true}],     // live: re-check `if` every frame
  chests:[{id:'c1',x:5,y:6,item:'herb',n:2},{id:'c2',x:9,y:9,gold:120,spirit:true}],
  npcs:[{id:'agan',sprite:'shopkeeper_f',portrait:'agan',name:'…',x:12,y:8,wander:2,
         if:st=>!st.flags.ch1_x, pos:st=>[3,4], spirit:true, talk:['line',['xinghe:smile','reply']] | async(S,npc)=>{}}],
  enemies:[{id:'m1',troop:'mine_1',x:10,y:12,art:'mine_bat',radius:3,chase:4,respawn:true,lv:3,onWin:async S=>{}}],
  events:[{id:'intro',trigger:'auto',once:true,if:st=>…,run:async S=>{}},
          {id:'spot',trigger:'action',x:3,y:23,label:'石縫',hint:st=>bool,hintR:4,run:…},  // hint tag
          {trigger:'touch',x:4,y:9,w:3,h:1,run:…}],
  warps:[{x:0,y:10,h:3,to:'mine_b1',tx:18,ty:5,tdir:'left',door:false,if,run}],
  guards:[…], hides:[…], checkpoint:[x,y,dir], winds:[…], lights:[…], pass:[…],
  onEnter, onUpdate(dt,ms,busy), drawGround/drawOver/drawScreen, onPush, autosave:true });
```
- **Spirit/vision:** `S.vision(sec)` or an item `use.vision` sets `vars.vision`; the `def.psychedelic` constant does the same job. Things marked `spirit:true` appear only with vision; `illusion:true` objects disappear with it.
- Walls are authored two cells thick.
- The destination of a warp must be walkable and must not be a warp itself.

**Story scripts**:
- An event is `async (S) => …`, run by `G.Script.run` (the `busy` counter blocks re-entry). See `MAP_AUTHORING.md` "Script API":
  - Dialogue: `say('id:expr','…')`, `lines`, `choice([...],{cancel})`, `narrate`.
  - Screen: `fadeOut/In`, `flash`, `shake`, `wait`, `sfx`, `bgm`, `titleCard`, `particles`, `light`, `toast`, `objective`.
  - Actors: `move(id,'UULL')`, `walkTo`, `face`, `setPos`, `emote`, `spawn`/`remove`, `camera`/`cameraHold`, `gather`.
  - State: `flag`/`has`, `give`/`take`/`hasItem`, `gold`, `join`/`leave`/`learn`, `healParty`, `lantern`, `quest`, `chapter`, `vision`.
  - Flow: `warp` (autosaves), `battle(troop,{loseOk,mode,guests,turnLimit,onTurn,hpFloor,finishers,onFloor})`, `shop`, `inn(price)`, `travel`, `saveMenu`, `ending`, `scene(mini)`, `pointOfNoReturn`.
- Inline markup: `{y}…{/}`.
- Chapters chain through `G.Story.chN = async S => {S.chapter(N); titleCard; join; warp}` and end with `await G.Story.next(S, N+1)`.

**Quests and 心燈**:
- Define a quest in the chapter file: `G.Data.quests.q_x = {name, desc, stages:[…], doneText, main?, lantern?}`.
- Advance it with `S.quest('q_x', 1)`, and finish with `S.quest('q_x','done')` followed by `await S.lantern('xd_x','名')` as the last beat.
- The ids are inconsistent: the docs say `lantern_*`, but ch1/ch2 use `xd_*`.
- `G.Lanterns.count() >= THRESHOLD (14)` selects `S.ending('true'|'normal')`.

**Data**:
- Characters: `{name, title, elem, weapon, base{hp,mp,atk,def,mag,spd,luk}, growth{…}, learn:[{lv,skill,story?,flag?}], ultimate, equip, joinLv}`.
- Skills: `{name, desc, mp, type:'phys|mag|heal|buff|debuff|revive|cure|special', elem, target, power, hits, status{id,chance,turns}, buffs, delay, fx, sfx, ultimate?, combo?[ids], special?, summon?}`.
- Items: `{name, desc, type:'use|weapon|armor|head|feet|acc|key|material', price, ch, icon, use{target,heal,mp,revive,cure,status,damage,vision,field,battle}, stats, elem, who, resist, immune, special, pair, noSource}`.
- Enemies and troops use helpers in `enemies.js`: `base(id,{name,art|sprite,lv,elem,weak,m:{hp,atk…},skills:[[id,w,'hp<50']],drops:[[item,rate]],phases,endAt,boss})`, `variant()`, `troop(id,[ids],bg,bgm)`, `boss()`, `area()`. Stats come from `G.Data.enemyCurve(L)` and the `progression` table.
- Chapter-local data is added in the chapter file with a prefix (`cN_*`, `t_cN_*`). Builders never edit `js/data`.

**i18n**:
- Chinese is the source language. Write whole static literals, never concatenated fragments.
- The dictionary file `en_chN[a-z]?.js` is attributed to chapter N through `document.currentScript` (`i18n.js:28`).
- At runtime the current `G.state.chapter`'s map wins. Chapter entries only fill gaps in the shared table; they never override UI or data text.
- `%s`/`%d` templates are global and ordered (the first match wins). Multi-line text is split; punctuation-only lines are auto-converted.

**Points of no return**:
- Declare one with `if (!(await S.pointOfNoReturn({chapter, quests:['q_a',{id,open}], lanterns:{xd_a:'q_a', xd_c:{quest,can}}, intro, back:'D', event:e}))) return;`
- Catalogue each one in `docs/qa/points_of_no_return.md`.

**Debug URLs** (the e2e and chapter tests depend on them):
`?debug&map=&x=&y=&lv=&party=&flags=&chapter=`, `?debug&startch=N[&autoplay]`, `?debug&battle=troop&auto=1`, `?r3lite`, `?nobatch`. F2 opens the debug menu.

## 4. Coupling hotspots and extraction plan

**Blockers**:
- **Script order lives in index.html.** load.js, package.sh and validate all parse it, so the starter must keep the `MAPS-BEGIN/END` markers.
- **Game vocabulary is baked into UI code.** Currency 文, stats 生命/真氣/武力…, gauge 劍意, 心燈, 靈視 and the 五行 cycle appear in about 10 files.
- **Cast ids sit in the engine**: G.Names, debug, title, story, map, mapview, vfx, autobattle.
- **Saves and settings are keyed `shorelight_*`.** The launcher and electron profile paths use `Shorelight`.
- **The theme-specific mechanic is welded into the core.** That mechanic is 心燈/Lanterns (state, script, fx, menu, playstats, save meta).
- **music.js and the art files mix kit and content in one file.**
- **Chapters hook battles by monkey-patching** instead of using an engine hook API.
- **i18n assumes zh source → en target**, and the CJK regex gates translation.

**Copy as-is** (E):
- Core: `util`, `render`, `input`, `i18n`, `scene`.
- Engine: `dialog` (minus Names), `script`, `map`, `mapmech`, `battle`, `shop`, `menu`, `playstats`, `minigames` (timing/mash/song).
- Graphics: `gfx/registry`, `ui`, `fx`.
- 3D: `r3d/core`, `materials`, `models`, `batch`, `mapview`, `env`, `chars`, `battleview` (engine half), `vfx` (generic half).
- Also `css`, `main.js`, `three.bundle` + `tools/build`.

**Parametrize** with a new `js/game/config.js` loaded first:
```js
G.CONFIG = { id:'shorelight', title:'彼岸燈', titleEn:'Shorelight', currency:'文',
  stats:{mhp:'生命',mmp:'真氣',atk:'武力',def:'防禦力',mag:'法力',spd:'身法',luk:'運氣'},
  gauge:'劍意', elements:{names:{…}, beats:{…}, colors:{…}}, equipSlots:[…], levelCap:50,
  collectible:{name:'心燈', threshold:14, icon:'lantern'}, vision:{name:'靈視'}, chapters:[…],
  defaultParty:['xinghe'], fontFace:'QDKai', fontProbe:'彼岸燈', gameOverText:'燈火將熄' };
```
- Change the save, settings and ledger keys to `CONFIG.id + '_save_'`.
- Move `G.Names`/`ShortNames` to content: generate them from `G.Data.chars`, plus an NPC name table.
- `A.FIGHTS`, the battleview arena presets and the vfx ultimates should each become a registry (`G.AutoBattle.registerFight`, `G.Battle3D.arenas[id]=`, `G.VFX3D.ultimates[charId]=`).
- Add `G.Battle.hooks.push({intro,onTurn})` so chapters stop wrapping `start`.

**Split files**:
- `music.js` → `music_engine.js` + `content/songs.js`.
- `sprites.js` / `portraits.js` → kit + `content/cast_specs.js`.
- `worldmap.js` → engine + `PLACES`/`COAST` data.
- `enemies.js` → keep the `base/troop/area/enemyCurve` helpers in an engine file and leave the rosters as content.

**Stub out**: the Formosa world map, `jiaobei`, `Lanterns` (make it a generic "collectibles" counter), the title-screen art, `ending.js` credits, `autobattle` FIGHTS, all `gfx/*` art packs (keep a minimal tile/object/monster/sprite set for the sandbox), and the r3d asset libraries (the billboard fallback already exists in `models.js`).

**Template skeleton**:
- Engine plus `js/maps/test.js` (sandbox), a 1-chapter sample with a quest, collectible, point of no return, shop, boss and `G.Story.ch0`.
- Data with 2 characters, about 10 skills/items and 3 enemies.
- `en_ui.js` with the engine strings only.
- `tools/test/{load,validate,unit,e2e,run.sh,lib/*}`, `sidequests/lib.js`, a chapter-test template, the sims with empty FIGHTS/STORY, the guide builder with generic placeholders, `package.sh`, `build_font.py`, `extract.js`, `r3d/sweep`, `render_music`.
- Docs: CONTRACTS*, MAP_AUTHORING, BUILDER_BRIEF, WRITERS_GUIDE, and the QA templates.

## 5. Process docs

- **STORY_BIBLE.md (322) / _zh (149)**:
  - Canon covers world lore, the cast with voices, the chapter journey and beats, and endings decided by the 心燈 count (about 20 lanterns, threshold about 14).
  - It has a binding cultural-accuracy and respect guide, and treats psychedelic visions as sacred, never as drugs.
  - It ends with an enemy roster by area.
  - Template takeaway: a bible gives a canon, voices, a beat sheet, an ending rule and a respect guide.
- **WRITERS_GUIDE / BUILDER_BRIEF**:
  - The pipeline runs screenplay → builder → validator → chapter test.
  - Screenplay format: maps, NPCs, numbered beats `角色(表情): 台詞`, side quests, shops/puzzles, enemies. Lines are ≤ 60 characters.
  - Builders own only their chapter file and test. Ids are namespaced, data stays local, text is i18n-safe. A screenshot and look pass is mandatory.
- **BALANCE.md (530)**:
  - Method: the real engine headless (`sim_story`) with a sensible-player bot at the real level and shop gear, 400 trials, fixed seed.
  - Targets: 70–90 % first-try boss wins, with outlier rules.
  - It documents per-boss tuning and the economy model (normal, minimal and thorough players). The levers are listed in order of preference.
  - It covers porting the auto-battle and lists what still needs a human playtest.
- **qa/full_chain.md**: one continuous run from title to both endings with carried state. It records findings by severity and the run history. It is the end-to-end acceptance bar (0 errors).
- **qa/sidequests_ch*.md**:
  - Play every side quest "like a player" and never write flags.
  - **Discoverability is a bug class**: every step needs a clue (NPC line, glint, hint tag, log text).
  - Includes per-quest PASS notes and windows/points of no return.
- **qa/points_of_no_return.md**: defines what counts as a point of no return, the shared warning, a full table, choice hints, and how to add one.
- **qa/item_placement.md**: every item must have a source. `--check-items` enforces it, and `noSource` marks the deliberate exceptions.
- **qa/english_layout.md**: fix overflow in the UI code, never in the strings. Gives the helpers in render.js and a Chinese regression check.
- **qa/sweep3d.md**: all 175 maps in 3D, with metrics, fixes and the batching results.
- **MUSIC.md (269)**:
  - Jianpu conventions and a leitmotif (燈 motif) shared across four themes.
  - The instrument palette, mix and loop-seam rules, where each theme plays, and how to audition and render (`render_music.js`).
- **RELEASE_NOTES.md**: release format (how to play, contents, quality work, bugs fixed, "please check in playtest", known issues). It asks playtesters to paste the 遊玩統計 report.
- **PLAYING.md**: bilingual player manual (launcher and Gatekeeper, controls, auto-battle styles, language, 3D/low-spec, save locations, building the Electron app).
- **Guide** (`docs/guide`):
  - 《彼岸燈 完全攻略》 is generated from `parts/` and `chapters/` fragments plus live data. Nothing in a table is typed by hand.
  - Output is `guide_zh.html` (5.4 MB, self-contained) and an 8,453-line `.md`, shipped in the release zip.
- **CONTRACTS.md / CONTRACTS_3D.md / ART_NOTES.md**: the art API contracts, battle formulas, 3D units/ownership/testing, and placement rules.
- **tools/test/README.md**: test architecture, plus "how to add a check / test / scenario".
- **tools/i18n/GLOSSARY.md**: how the dictionaries work, style rules, terminology and canonical lines.

## 6. README / CLAUDE.md conventions

- There is **no CLAUDE.md** anywhere in the repo.
- **README.md** gives the bilingual pitch, play instructions (launcher, `index.html`, `npm start`/`dist`), controls, features and credits.
- Its developer section points to the design docs, debug URLs, `bash tools/test/run.sh`, `node tools/i18n/extract.js`, `python3 tools/build_font.py` (re-run after text changes and commit `fontdata.js`) and `bash tools/package.sh`.
- **tools/test/README.md** describes the test stages and their helpers.
- Conventions stated across the docs:
  - `'use strict'` classic scripts; no modules, network or `ctx.filter`.
  - Static art is pre-rendered and cached; deterministic `U.hash` variation.
  - Ids are ascii snake_case: flags `chN_*`, quests `q_*`, chapter-prefixed data.
  - Never edit `js/data` or the engine from a chapter.
  - Validator-clean before done; tests must fail on any console error or `G.lastError`.
  - Commit messages are imperative and describe the player-facing effect.

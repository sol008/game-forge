# Content formats

The authoring surface a chapter builder writes against. It is RPG-centric, with genre notes in §10. The formats come from what worked in Shorelight (`docs/MAP_AUTHORING.md`, `js/engine/script.js`, `js/story/story.js`, `js/data/*.js`). Each place where Shorelight's format let a bug through has been tightened. `G` stands for the game's single global (see `architecture.md`); vocabulary such as currency, stat names and the collectible's name comes from `CONFIG` (see `config_first.md`). The sketches are illustrative, not code to copy.

Binding rules for builders:
- Write only your chapter file, your chapter's i18n file and your tests.
- Never edit the engine or the shared data. Report engine bugs in the fixed format and do not patch around them.
- Every id you reference must exist. The validator fails the build on dangling ids.

## 0. Id grammar (one table, enforced by the validator)

| Kind | Pattern | Example | Notes |
|---|---|---|---|
| map | `<place>[_<sub>]` | `harbor_inn_2f`, `tamsui_fort` | globally unique, ascii snake_case, no chapter prefix; the validator checks uniqueness game-wide |
| flag | `chN_<what>` | `ch3_met_ferryman` | one meaning per flag; no dynamic names unless the pattern is declared in `content/flags.json` |
| quest | `q_cN_<name>` | `q_c3_lost_bell` | main-story quests set `main:true` |
| collectible | `CONFIG.collectible.id` + `_` + quest suffix (the quest id without `q_`) | `ember_c3_lost_bell` | **derived, never hand-typed** (§4); planned in `docs/canon/collectibles.json` |
| item / skill / enemy | `cN_<name>` | `c3_bronze_bell`, `c3_rat` | only for chapter-local data (one registry each); shared data has no prefix |
| troop | `t_cN_<name>` | `t_c3_dock_rats` | |
| event / npc | `<name>`, unique within the map | `bell_spot`, `ferryman` | the engine key is `map:id` |
| point of no return | `pnr_cN_<name>` | `pnr_c3_set_sail` | catalogued (§7) |
| i18n scope | `ui`, `data`, `cN` | | §6 |

Shorelight lesson: the docs said `lantern_*`, ch1/ch2 wrote `xd_*`, and the finale read the wrong ids for 4 stories. Deriving the collectible id from the quest id removes that whole class of bug.

## 1. Map definition

```js
G.Maps.define('harbor', {
  name: '…', place: 'harbor', chapter: 3,
  bgm: 'harbor_day',            // id | null (explicit silence) | st => id. Omitted means "keep what is playing"
  ambience: 'gulls',            // a separate layer from bgm; a screenplay "no music" scene still names its ambience
  start: [12, 18], light: { ambient: 0.2 }, particles: ['mist'],
  tiles: ['CCCCCCCC', 'CC....CC', /* … */], legend: { A: 'sand_wet' },
  deco: ['  t  r  '], decoLegend: { Q: 'kelp' },
  objects: [/* §1.2 */], npcs: [/* §1.3 */], events: [/* §1.4 */],
  chests: [/* §1.6 */], warps: [/* §1.6 */], enemies: [/* §1.6 */], lights: [{ x: 4, y: 3, r: 160, color: '#ffb060' }],
  hooks: { onEnter, onUpdate, drawGround, drawOver, drawScreen }, // each one needs a 3D path (§1.7)
  noSave: st => st.flags.ch3_in_storm, autosave: true,
});
```
- **Tiles**: one string per row, all rows the same width. The legend maps a char to a terrain id. Walls are authored **2 cells thick** (ceiling row plus face row). Water is solid unless bridged.
- **Deco**: single-char objects on a second grid. Multi-tile deco anchors at its top-left cell.

### 1.1 Objects
```js
{ t: 'cart', x: 9, y: 6 }                                     // footprint w×h comes from the art registry def
{ t: 'gate', x: 3, y: 1, if: st => !st.flags.ch3_gate_open }   // checked at map build and on rebuild (§1.8)
{ t: 'tracks', x: 5, y: 7, live: true, if: st => st.vars.leg === 2 }  // re-checked every frame
{ t: 'crate', x: 4, y: 4, push: true }
{ t: 'oar_rack', x: 11, y: 2, w: 2, h: 1, marker: 'glint',
  interact: async (S, o) => { /* … */ }, label: '…' }         // inspectable across its WHOLE footprint
{ t: 'herb_patch', x: 6, y: 9, marker: 'glint', picked: st => st.flags.ch3_herb_1 }  // live getter, art dims when true
```
- **Footprint rule.** Interaction, collision and the hint tag all use the full footprint: instance `w/h` if given, else the registry def's `w/h`, else 1. Shorelight's `findInteract` used `o.w || 1` and ignored the def size, so ch9 carts and ch10 oars worked from only one half.
- `if` vs `live`. Without `live`, `if` is evaluated when the map is built and again on every rebuild trigger (§1.8). With `live:true`, it is evaluated every frame. Use `live` for anything that changes while the player stays on the map.
- `spirit:true` exists only while vision is on. `illusion:true` exists only while it is off. `over:true` draws above actors. `solid` overrides the def.

### 1.2 NPCs
```js
{ id: 'ferryman', sprite: 'boatman', portrait: 'ferryman', x: 14, y: 5, dir: 'left', wander: 0,
  if: st => !st.flags.ch3_ferry_gone, pos: st => st.flags.ch3_storm ? [3, 4] : [14, 5],
  talk: ['line', ['hero:smile', 'reply']] /* or */ talk: async (S, npc) => { /* … */ },
  hints: { q_c3_lost_bell: 0 } }   // this NPC carries the pointer for step 0 of that quest (§8)
```
A plain string in a `talk` array is spoken by the NPC. The speaker id must be on the speaker whitelist (`docs/canon/speakers.json`); silent characters (pets, mute cast) are rejected by lint.

### 1.3 Events
```js
{ id: 'arrive', trigger: 'auto',   once: true, if: st => !st.flags.ch3_arrived, run: async S => {} }
{ id: 'bell',   trigger: 'action', x: 7, y: 2, w: 2, h: 1, label: '…', marker: 'tag', run: async S => {} }
{ id: 'surf',   trigger: 'touch',  x: 0, y: 9, w: 1, h: 3, run: async S => {} }
```
- `auto` fires when the map is idle and `if` holds. It must be guarded by `once` or a flag; a loop is a validator error.
- `action` fires on Z while facing any cell of the rect. `touch` fires on stepping onto any cell of the rect.
- `once:true` writes `ev_<map>_<id>`. `S.pointOfNoReturn` can re-arm it (§7).

### 1.4 Discoverability fields (required, §8)
Every `action` event, every `interact` object and every chest has a `marker`:
- `'object'`: the art itself reads as interactable (a chest, a door, a lever);
- `'glint'`: a sparkle on the object;
- `'tag'`: a floating label within `hintR` tiles, default 4;
- `'npc'`: no visual marker, but an NPC line points at it (name the NPC in `pointer`).

A bare tile with no marker is a validator error. Shorelight's 扇貝殼 shell and 懷錶 pocket watch sat on bare grass.

### 1.5 Spirit / vision-only content
Vision comes from `S.vision(sec)`, from an item's `use.vision`, or from a map's constant `vision:` level. Hidden content uses `spirit:true` and **also** needs a `pointer` (an NPC line or a journal line). Where it makes sense, add a fallback hint for players without vision. Turning vision on or off recomputes solidity at once.

### 1.6 Chests, warps, enemies
```js
chests:  [{ id: 'c1', x: 5, y: 6, item: 'tonic', n: 2 }, { id: 'c2', x: 9, y: 9, gold: 120, spirit: true, pointer: 'ferryman' }]
warps:   [{ x: 0, y: 10, h: 3, to: 'harbor_east', tx: 18, ty: 11, tdir: 'left', door: false, if, run }]
warps:   [{ x: 6, y: 0, to: 'open_sea', tx: 4, ty: 4, oneWay: 'pnr_c3_set_sail', sets: { flags: ['c3_sailed'] } }]   // one-way: needs a pnr (§7)
enemies: [{ id: 'rat1', troop: 't_c3_dock_rats', x: 10, y: 12, art: 'rat', radius: 3, chase: 4, respawn: true, lv: 11 }]
```
- A map-edge exit that ends a quest early (e.g. walking out of an escort) is one-way too: it gets `oneWay` and `sets`.
- A warp's landing cell must be walkable, must not be a warp cell, and should sit one step inside the map. A warp `run` that returns `false` cancels the warp.
- Enemies: touching one starts a battle, and Z next to one gives a pre-emptive strike. `respawn:false` writes `dead_<map>_<id>`. An unknown troop id is a validator error, and at runtime it ends the encounter once with `'error'` (no restart loop).

### 1.7 Map hooks
`onEnter(S)` runs after every entry. `onUpdate(dt, scene, busy)` runs every frame. `drawGround` and `drawOver` take world coordinates, and `drawScreen` takes screen coordinates.
- Each hook must render correctly in **both** 2D and 3D: world-space draws become ground decals or a screen overlay through the engine's split context.
- Hooks are registered, never monkey-patched. Battle hooks are added with `G.Battle.addHook({ id, when, intro, onTurn })` (`config_first.md` §4.1), never by wrapping `G.Battle.start`.

### 1.8 Rebuild triggers
NPCs, followers, `if` objects and solidity are rebuilt at script end, on vision change, on join/leave, **and on a same-map warp**. The maze re-entered its own map without a reload, and footprints built only on entry vanished.

## 2. Script API (`S`, every event is `async S => …`)

| Group | Calls (sketch) | Contract |
|---|---|---|
| Dialogue | `say(who, text, o)`, `lines(list, npc)`, `narrate(lines, {veil})`, `choice(opts, {cancel})` → index | `who` is `'id:expr'`, a plain name, or `''` for narration. Lines ≤ 60 chars; markup `{y}…{/}`. `choice` returns the same index for real keys and for autoplay |
| Screen | `fadeOut/fadeIn(sec)`, `flash`, `shake`, `wait(sec)`, `titleCard(t, sub)`, `particles`, `light(cfg)`, `toast`, `objective(text)` | no `wait` > 1.5 s without text on screen; `titleCard` and `narrate` stay visible after a `fadeOut` (they are `overFade` scenes, `architecture.md` §5) |
| Audio | `bgm(id \| null, {fade})`, `ambience(id \| null)`, `sfx(id)` | `null` means silence, on purpose; `undefined` is a lint error in scripts |
| Camera | `camera.pan(x, y, sec)`, `camera.follow(id)`, `camera.hold()` | **auto-release**: at the end of the outermost script the camera returns to the player unless `hold()` was called or an auto event is pending |
| Actors | `move(id, 'UULD', {speed, wait, ghost})`, `walkTo(id, x, y)`, `face(id, dirOrId)`, `setPos`, `emote`, `show`, `jump`, `fadeActor`, `spawn(def)`, `remove(id)`, `gather()`, `hideFollowers(v)`, `pose(id, 'lie_back' \| 'lie_side' \| 'sit' \| 'kneel' \| 'slump' \| null, {on: objId})` | every awaited move resolves (including followers, zero steps and blocked steps); `speed` and `ghost` apply to that call only; a pose is drawn by **both** the 2D sprite and the 3D figure (lying along the bed, head on the pillow, when `on` is furniture) and clears when the actor walks |
| State | `flag(k, v)`, `has(k)`, `give(item, n)`, `take`, `hasItem`, `gold(n)`, `join(id, lv)`, `leave(id)`, `learn(id, skill)`, `healParty()`, `quest(id, step \| 'done')`, `collect(questId)`, `chapter(n)`, `vision(sec)` | toasts come from i18n templates built on `CONFIG` names; nothing hard-codes currency or cast |
| Flow | `warp(map, x, y, dir, {fade, reload})`, `battle(troop, opts)`, `shop(goods, {title})`, `inn(price, {who})`, `travel(from, to, {label})`, `saveMenu()`, `scene(minigame)`, `ending(kind)`, `gameOver()`, `pointOfNoReturn(o)` | `warp` autosaves unless `noSave` |

**Battle options:**
- `loseOk`: a defeat continues the story instead of a game over.
- `mode`: `'normal' | 'advantage' | 'ambush'`.
- `guests: [ids]`, `turnLimit` and `turnLimitResult`.
- `hpFloor: { enemyId: 0.2 }` with `finishers: [skillIds]` and `onFloor(b, unit)`. The floor applies to enemy units only; an ally at 0 HP never counts as a win.
- `onTurn(b, unit)` can use `b.say2`, `b.addPartyMember` and `b.removePartyMember`.
- `bgmAfter`: `undefined` returns to the map's track; `null` is silence.
- The call returns `'win' | 'lose' | 'flee' | 'error'`.

**Restored at the end of every script** (engine invariant, not author discipline):
- the camera (rule above);
- input is cleared, and keys pressed during the cutscene are dropped;
- the HUD and letterbox are visible;
- `scripted` is cleared on all non-spawned actors;
- followers are shown;
- the dialogue box is closed;
- the busy counter is ≥ 0.

All of this also happens when the script throws.

## 3. Story chaining
```js
G.Story.define(3, {
  title: '…', entry: 'harbor', progression: { lv: [9, 13], party: ['hero', 'scout'] },
  start: async S => { S.chapter(3); await S.titleCard(G.T('…'), '…'); S.join('scout'); S.objective('…');
                      await S.warp('harbor', 12, 18, 'up'); },
});
// last beat of chapter 3:
if (!(await S.pointOfNoReturn({ id: 'pnr_c3_set_sail', sets: { flags: ['c3_sailed'], chapter: 4 } }))) return;
await G.Story.next(S, 4);
```
`G.Story.next` sets the chapter and runs the next `start`; if there is none, it shows a "to be continued" card. `progression` feeds the canonical `chapterStart(N)` test fixture (level, party, gear, items) and the simulators. Tests may not boost beyond it.

## 4. Quests and collectibles
```js
G.Quests.define('q_c3_lost_bell', {
  name: '…', kind: 'side', collectible: true, closes: 'pnr_c3_set_sail',   // closes: display only (closes-at)
  closedIf: s => s.chapter > 3 || s.flags.c3_sailed,                        // the test the pnr check runs (§7)
  guide: {                                   // the guidance record (rules/discoverability.md D9–D11)
    where: { map: 'harbor', npc: 'ferryman' }, when: 'night',   // 'any' | 'day' | 'night' | a story phase
    rumour: '…',                             // shown once the player has entered the area
    hints: ['riddle…', 'region + NPC…', 'area…', 'exact spot…'],   // 4 tiers, each adds new information
    area: 'harbor_district',                 // per-area tally key
    venue: 'harbor_teahouse',                // optional; default: the area's hint venue. Reachable while open (D11)
  },                                         // closes-at comes from `closes` above
  steps: [
    { text: '…', hint: { npc: 'ferryman' } },
    { text: '…', hint: { map: 'harbor', at: [7, 2], marker: 'tag' } },
    { text: '…', hint: { journal: '…' } },
  ],
  doneText: '…',
});
// in a script: S.quest('q_c3_lost_bell', 1) … S.quest('q_c3_lost_bell', 'done'); await S.collect('q_c3_lost_bell');
```
- `S.collect(questId)` lights `ember_c3_lost_bell` (prefix `CONFIG.collectible.id`, see `config_first.md`) with its animation. It is the **last** beat of the resolution. Collectibles never come from a bare `flag`: Shorelight's ch7/ch8 builders set flags that the ending count never saw.
- Ending thresholds read `G.Collect.count()` against `CONFIG.collectible.threshold`.
- `docs/canon/collectibles.json` is the **plan list** (name, chapter, quest id), written in phase 1. It plans at least the threshold plus a slack of 25 % of the threshold (minimum 2). The validator derives each id from its quest and checks the list against the code both ways: every planned collectible has a quest with exactly one `S.collect`, and every `S.collect` is planned.
- Every guidance UI (collectible panel, quest log, rumours, quest-giver marks, area tallies, party talk, hint vendors, load recap, stuck offer, presets) reads `guide`; none keeps its own text. Build the registry and these readers in phase 2, with the sample chapter, never as a late retrofit.
- Before the start, talk may voice the `rumour`; after it, only the current step's hints, and each new step is a new talk topic (D10).
- Every collectible gets the same in-world cue (e.g. a floating name tag) from the engine, not per placement (D1).
- The validator checks that:
  - every quest has a complete `guide` (where, when, rumour, 4 distinct hint tiers, area), and its map, NPC and area exist;
  - every quest that can be missed has a `closedIf`, and every quest with hints has a venue in its area that is reachable while it is open;
  - every quest step has a `hint`;
  - every `collectible:true` quest has exactly one `S.collect`;
  - every `q_` id used in scripts is defined, and the reverse;
  - every collection quest's N items exist and can be reached.

## 5. Data formats
```js
G.Data.chars.hero  = { name, title, elem, weapon, base: { hp, mp, atk, def, mag, spd, luk }, growth: { /* per level */ },
                       learn: [{ lv: 3, skill: 'cut' }, { story: true, flag: 'ch5_vow', skill: 'vow' }], ultimate, equip, joinLv, sprite, portrait };
G.Data.skills.cut  = { name, desc, mp, type: 'phys', elem: null, target: 'enemy', power: 1.4, hits: 1, status: { id: 'bleed', chance: 0.3, turns: 3 },
                       buffs: [], delay: 1.0, fx, sfx, ultimate: false, combo: null };
G.Data.items.tonic = { name, desc, type: 'use', price: 40, ch: 1, icon: 'potion', use: { target: 'ally', heal: 120, field: true, battle: true } };
//   equipment: type 'weapon|armor|head|feet|acc' + stats, elem, who, resist, immune, special; `noSource: 'reason'` exempts the item-source check
G.Enemies.base('c3_rat', { name, art: 'rat', lv: 11, elem: 'water', weak: ['earth'], m: { hp: 0.9, atk: 1.1 },
                skills: [['bite', 3], ['screech', 1, 'hp<50']], drops: [['tonic', 0.2]], phases: [], endAt: null, boss: false });
G.Enemies.troop('t_c3_dock_rats', ['c3_rat', 'c3_rat'], 'docks', 'battle');
G.Enemies.boss('t_c3_tide_king', ['c3_tide_king'], 'sea', 'boss');
```
- Enemy stats are derived from `enemyCurve(lv) × m`. Hand-typed HP/ATK is allowed only with a `// tuned:` note that cites the simulator run.
- Chapter-local data lives in the chapter file under its prefix. Builders never edit shared data; corrections to shared entries go through an engine-owned `fixes` table.
- Names are unique across characters, items and skills. Shorelight had 芋圓 as both a cat and a dessert.

## 6. i18n
- **Whole literals only.** Every display string is a complete phrase in the source language. When a line needs a value, write a template literal whose static parts are whole phrases (`` `${n} 位客人到了。` ``) and register the key as `'%d 位客人到了。'`. Never concatenate fragments.
- **Scopes:** `G.I18N.add('ui' | 'data' | 'c3', dict)`. The scope is an explicit argument, never inferred from `document.currentScript`, which is absent in Node, so Shorelight's chapter scoping silently switched off in headless tests.
- **Lookup order:**
  1. shared (`ui`, `data`) exact match;
  2. current chapter exact match;
  3. `%s`/`%d` templates, in order (first match wins, `%s` captures are translated recursively);
  4. multi-line text split into lines;
  5. punctuation-only lines converted automatically;
  6. the source text.

  A chapter entry **only fills gaps**: it never shadows a shared key, in any chapter. Shorelight's cat "Taro" would otherwise have renamed the "Taro Ball Soup" item everywhere.
- **Glossary:** `docs/i18n/GLOSSARY.md` holds cast, place, item and term names in every language. The validator checks that every glossary term in a source line maps to its glossary rendering in the target line.
- **Puzzles:** the screenplay tags a line whose answer depends on glyphs, puns or rhymes `[PUZZLE-LANG]`; in code its key carries `// i18n:puzzle` beside it. The translator applies the requirements' puzzle policy (re-author by default) rather than translating literally.
- **Units:** dictionary files are split at about 1,200 lines (`c11`, `c11b`, both in scope `c11`).

## 7. Points of no return
```js
if (!(await S.pointOfNoReturn({ id: 'pnr_c3_set_sail', sets: { flags: ['c3_sailed'], vars: { tide: 2 }, chapter: 4 },
                                intro: [['captain', '…']], back: 'D', event: ctx }))) return;
```
- **`sets` is required** at every call site: the flags it sets, the vars it changes, and `chapter` when a chapter ends. Without it the check sees no change and goes silent, so the validator rejects a call without `sets`.
- The engine derives what closes by **simulation**, not by a list: apply `sets` to a copy of the state (or temporarily, then restore), and take every entry whose `closedIf` turns from false to true and that is available now. Builders never pass the list. "Everything open in this area" over-warns (things still doable later, or not yet open); "only what the call site names" under-warns. Over-warning trains players to click past the prompt.
- **Open** quests are named, each with **where** it is (from `guide.where`). Available collectibles whose quest was never started are **counted**, not named. The prompt lists exactly what the point closes, never a bare "no way back".
- Nothing open: return `true` silently. Otherwise ask, with "continue" as option 0, then "not yet" and "save first" (opens the save menu, then asks again). If the player chooses to wait, re-arm `event` and step the player `back`.
- Every `oneWay` warp (map-edge exits included), chapter end, and boss whose win moves the story on must call a pnr. Every choice that permanently loses a collectible gets a confirmation through the same check. Every pnr is catalogued in `docs/qa/points_of_no_return.md` (id, map, `sets`, what closes); the validator diffs that catalogue against the code.

## 8. Discoverability metadata (validator rules)
1. Every quest step has a `hint` (npc, map+at, or journal), and the hinted npc or map exists.
2. Every interactable (action event, `interact` object, chest, `spirit` find) has a `marker`, and its hit area is ≥ 2 tiles or it uses `marker:'object'`.
3. Every `spirit` find has a `pointer` that is not itself vision-only.
4. Every missable item or collectible is closed by a catalogued pnr.
5. BFS reachability over real collision reaches every warp, chest, NPC and quest target from each entry.
6. Harvestables look different from their decorative twins (a different art id or a `marker:'glint'`).
7. Every quest and collectible has a complete `guide` record (§4), and every pnr's prompt can name where each quest it closes is.
8. Every pnr call site and `oneWay` warp declares `sets`; every missable entry has a `closedIf`.
9. Every entry with hints has a hint venue in its area; one-way areas have their own (D11). The hint currency has a source in chapter 1.
10. Every collectible has the shared in-world cue (D1).

## 9. Screenplay → code mapping

| Screenplay element | Code | Test assertion it becomes |
|---|---|---|
| Scene header: map, time, light, particles | `G.Maps.define` fields, `light`, `particles` | map exists; light within ±0.05 |
| Cue line `bgm=x` / `bgm=none` / `ambience=ritual_fire` | `bgm:'x'` / `bgm:null` / `ambience:'ritual_fire'` | `G.Music.current === 'x'`, or `null` **and** `G.Ambience.current === 'ritual_fire'` |
| "Must not imitate the sacred chant" | ambience only; no song id | the track has no melody voice (music lint) |
| Numbered beat `角色(表情): 台詞` | `S.say('id:expr', '台詞')` | the beat's line is reached in the chapter test |
| Movement or camera beat | `S.move`, `S.camera.pan` | after the scene: camera on the player, player on screen |
| Stage direction "lies", "collapses", "asleep", "kneels", "sits" | `S.pose(id, …)` | the pose holds in 2D **and** 3D (screenshot both); without it the 2D sprite lies in bed while the 3D figure stands in it |
| Encounters: area, density | `enemies:` plus troops | troop ids exist; roaming count is within the band |
| Choice with consequences | `S.choice` + flags | each branch is run once (real keys for at least one) |
| Side quest and its clues | `G.Quests.define` with `hint`s | side-quest walkthrough PASS with no flag writes |
| Shops, inn price | `S.shop`, `S.inn` | stock ids exist; the price is within the chapter's band |
| "One-way from here" | `pointOfNoReturn` | listed in the catalogue; the warning appears when content is open |

- Each screenplay scene carries one machine-readable cue line, the only cue mechanism:

  `<!-- cue: 4-10 bgm=none ambience=ritual_fire sfx=drum_far -->`

  `tools/lint/screenplay.js` extracts every cue line to `docs/story/cues.json`, and `tools/test/spec_conformance.js` asserts each one in game. The other rows of the table (map, light, encounters) are asserted by the chapter test.
- Tests encode the spec, never current behaviour. Shorelight's ch4 test asserted "festival night: no BGM", which locked in a missing ambience the screenplay required.
- The screenplay is frozen with a version hash before the build. The builder brief carries that hash.

## 10. Genre notes
- **Action / adventure:** keep maps, events, the script API and quests. Replace `battle()` with real-time encounters, roaming `enemies` gain `ai` and `hp` instead of `troop`, and points of no return are unchanged.
- **Platformer / puzzle:** `tiles` gain layers (solid, one-way, hazard). Events become trigger volumes. Collectibles keep the derived-id rule. Each level is a "chapter" for the fixtures. `pointOfNoReturn` guards level exits that lock collectibles.
- **No combat (`CONFIG.battle` absent):** the boss and economy simulators are replaced by `tools/sim/solver.js`: every puzzle is solvable from `chapterStart` and every step is hinted. The full-chain test still applies; conformance cases that need battles (C15, C19) are skipped; builders press through "one battle, if any"; the guide charts only what has data.
- **Visual novel:** maps shrink to backgrounds. `say`, `choice`, flags, the i18n rules and the screenplay mapping carry over unchanged; choice parity (real keys vs autoplay) matters most.
- **Tactics / strategy:** troops become unit placements on a map grid. `battle(opts)` gains `objective` (`rout`, `survive N`, `reach`) and `deploy`. Everything else stays as above.
- **Every genre:** id grammar, discoverability markers and hints, whole-literal i18n with scopes, and cue lines in the screenplay.

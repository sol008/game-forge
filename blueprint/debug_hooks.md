# Debug hooks and Play Stats

Every automated test and every playtest report goes through this surface, so it is designed in with the engine in phase 2. Retrofitting it later produced Shorelight's worst testing failures (PLAN §1 class 2).

## 1. Principles

- **Jump to a start state, never across the critical path.** URL jumps exist to set up the *beginning* of a chapter, map or fight from the canonical `chapterStart(ch)` fixture (level, party, gear, gold, flags). Within a chapter, tests walk, talk and press keys. Shorelight's ch11 lighthouse soft-lock (stairs on walls) went unseen because a test teleported past it.
- **Debug only behind `?debug`.** Without it, `G.Debug.init` does nothing and the F2 menu is unbound. The code ships, the surface is inert.
- **Real input is the default.** `autoplay` is a fast-forward for long scripted stretches. Every flow also has a real key-press test, and the harness asserts autoplay is off in those tests.
- **Tests never write flags mid-run.** `flags=` is only for the start state. Side-quest walkthroughs must reach every flag through play.
- **One terminal-state check.** Any game over, title screen or frozen state ends the test fast with a diagnostic, instead of a 10-minute timeout.

## 2. URL surface

All parameters require `?debug`, except the feature flags in §5.

| Param | Effect |
|---|---|
| `map=<id>&x=&y=&dir=` | New state, skip title, warp to the map cell (default: `def.start`) |
| `lv=<n>` | Party level (default: the progression table for the chapter) |
| `party=a,b,c` | Party ids (default: `G.Data.progression[ch].party`, never a literal) |
| `flags=f1,f2` | Flags set before the first frame |
| `chapter=<n>` | `G.state.chapter` (i18n scope, progression row) |
| `fixture=chN` | Apply `chapterStart(N)`: level, gear, items, gold, collectibles so far. **Tests use this instead of ad-hoc `lv`/gold** |
| `startch=<n>` | Fixture for N, then run `G.Story.chapters[N].run` from its first beat, exactly as the previous chapter's `G.Story.next` would |
| `battle=<troop>` | Start that fight on a neutral map; result goes to `window.__battleResult` |
| `auto=1` | Auto-battle on, at the fastest battle speed |
| `autoplay=1` | Dialogue auto-advances, choices come from the queue, minigames succeed, cards/travel/shops skip |
| `choices=0,2,"Yes"` | Seed the autoplay choice queue (index or substring) |
| `noenemies=1` | Remove roaming enemies and encounters on every map entered (screenshots, side-quest walks) |
| `seed=<n>` | Seed the game RNG (battles, drops, minigames) for reproducible runs |
| `lang=en` | Override the language setting for this session only |

Shorelight's set (`map/x/y/lv/party/flags/chapter`, `startch`, `battle`+`auto`, `autoplay`, `r3lite`, `nobatch`) worked and every chapter test depended on it. See shorelight:js/engine/debug.js. Its gaps:
- no fixture param, so tests boosted levels ad hoc;
- no `noenemies`, so tests cleared `mapScene.enemies` by hand (shorelight:tools/test/chapters/ch1.test.js:85);
- a hard-coded default party and a chapter-7 join/leave hack.

```js
// debug.js: startup jump (sketch)
G.Debug.init = function () {
  const q = new URLSearchParams(location.search), num = (k, d) => (q.has(k) ? +q.get(k) : d);
  if (!q.has('map') && !q.has('startch') && !q.has('battle')) return;
  G.Audio.unlock(); G.state = G.newState(); G.inGame = true;
  const ch = num('startch', num('chapter', 0));
  G.Fixtures.chapterStart(q.get('fixture') ? +q.get('fixture').slice(2) : ch, { lv: num('lv') });
  if (q.has('party')) G.Party.set(q.get('party').split(','));
  for (const f of (q.get('flags') || '').split(',').filter(Boolean)) G.state.flags[f] = true;
  G.Debug.choices = (q.get('choices') || '').split(',').filter(Boolean);
  G.Debug.setAutoplay(q.has('autoplay')); G.state.vars.autoBattle = q.has('auto');
  if (q.has('startch')) return G.Script.run((S) => G.Story.next(S, ch));
  const id = q.get('map') || G.CONFIG.startMap, d = G.Maps.get(id);
  G.Mapx.goto(id, num('x', d.start[0]), num('y', d.start[1]), q.get('dir') || 'down');
  if (q.has('battle')) G.Script.run(async (S) => { window.__battleResult = await S.battle(q.get('battle')); });
};
```

`G.Fixtures.chapterStart` is the **same function** the boss simulator, economy simulator and chain test use. The validator checks that it exists for every chapter.

## 3. Runtime API (`G.Debug`)

| Call | Contract |
|---|---|
| `setAutoplay(on)` | Sets `G.Debug.autoplay`; raises text and battle speed. Modules consult the flag in one place each: dialog advance, choice pick, minigame resolve, title card/travel/collectible FX skip, shop skip (logging unknown goods), battle auto |
| `choices` (array) | Each autoplay choice shifts one entry: a number is an index, a string matches an option by substring. An empty queue picks 0, and the pick is logged |
| `log` (array) | Autoplay decisions and anomalies (unknown shop item, missing choice match) for the test report |
| `trigger(eventId, mapId?)` | Runs a map event's script; resolves when it ends. For **unit-style** checks of one event, never to skip a gate |
| `talk(npcId)` | Runs an NPC's talk on the current map as if Z was pressed facing them |
| `stepOn(x, y, dir?)` | Puts the player on a cell, sets facing from the step, and fires arrival logic (touch events, warps). For adjacent cells or BFS-verified walks only |
| `pendingAuto()` | The `auto` event whose condition holds right now (it will start on the next update) |
| `idleNow()` | No script running, the map is the top scene, no fade, and no pending auto event |
| `idle(timeoutMs, {frames})` | Resolves `true` once idle has held across N scene updates; `'gameover'`/`'title'` on a terminal state; `false` on timeout |
| `terminal()` | `null`, `'gameover'`, `'title'` or `'frozen'` (§4) |
| `snapshot()` | `{map, x, y, chapter, party, flags, quests, scenes: G.Scenes.names(), lastError}` for failure reports |

Requirements on the engine so these work:
- Scenes carry a readable name (`sceneName` or class name), so diagnostics print `MapScene > DialogScene`, not `Object`.
- `G.Scenes.frame` counts updates, so "idle across 2 frames" means the same thing in rAF and in fast-forward.
- `G.Input._press/_hold` exist for unit tests, but e2e tests send real `keydown` events through the browser.
- Every frame error lands in `G.lastError`, and the harness fails on it or on any `console.error`.

### 3.1 Script-idle detection

Two chained scripts (one auto event ends, the next starts on the following update) look idle for one frame. Tests that send input then lose keys or read "soft-locks" that aren't real. Idle must be **stable**:

```js
G.Debug.idle = (timeoutMs = 60000, { frames = 2 } = {}) => new Promise((done) => {
  const t0 = Date.now(); let since = null;
  const iv = setInterval(() => {
    const term = G.Debug.terminal();
    if (term && term !== 'frozen') { clearInterval(iv); return done(term); }
    if (!G.Debug.idleNow()) since = null;
    else since = since || { f: G.Scenes.frame, t: Date.now() };
    const stable = since && (G.Scenes.frame - since.f >= frames || Date.now() - since.t > 1000);
    if (stable || Date.now() - t0 > timeoutMs) { clearInterval(iv); done(!!stable); }
  }, 25);
});
```

The 1 s real-time escape covers a paused loop (no frames advancing). See shorelight:js/engine/debug.js (`idleNow`, `idle`, `pendingAuto`).

## 4. Terminal-state detection

A harness that only waits for "the next expected thing" mistakes a loss for a stall. Shorelight's "final boss stall" was the dumb AI losing. Every wait loop checks:

```js
// Every terminal scene class registers itself: G.Engine.terminalScenes.set(MyGameOver, 'gameover').
// Never match on one class name: Shorelight missed a chapter's custom game-over subclass exactly that way.
G.Debug.terminal = function () {
  const top = G.Scenes.top();
  for (const [Cls, kind] of G.Engine.terminalScenes)
    if (top instanceof Cls && (kind !== 'title' || G.Debug._wasInGame)) return kind;  // 'gameover' | 'title' | 'ending'
  const sig = G.Debug.progressSig();     // map, player cell, script busy, top scene, dialog line, battle turn
  if (sig !== this._sig) { this._sig = sig; this._sigAt = G.time; return null; }
  return G.time - this._sigAt > G.Debug.FROZEN_SEC ? 'frozen' : null;  // default 15 game-seconds
};
```

- **`frozen`** = a script is busy, nothing on screen awaits input (no dialog, choice, battle, fade or tween), and no actor is moving. The harness then dumps actor move queues and `snapshot()`. Shorelight's version lives in the e2e driver (shorelight:tools/test/e2e.js, soft-lock detector). Put it in the engine so every tool shares it.
- A test that *expects* a game over (a scripted loss) passes `{allowGameOver: true}`; otherwise `gameover` fails the run immediately with the troop, the party levels and the fixture used.

## 5. Feature flags (no `?debug` needed)

Players and tools may use these:

| Flag | Effect | Used by |
|---|---|---|
| `r3lite` | 3D at half resolution, no shadows, no post-processing | 3D sweep in SwiftShader, CI, the launcher's `lite` mode |
| `nobatch` | Disable instanced batching | A/B draw-call and pixel comparison only |
| `render=2d` / `render=3d` | Force a render mode for this session | Chapter tests in the player's default mode, plus the other mode once |
| `nofx` | Disable screen warp/flash effects | Photosensitivity checks, screenshots |

Flags are read once at boot into `G.flags` (`G.flags.nobatch`…). Modules read `G.flags`, never `location.search`. Unknown flags log a warning, so a typo cannot silently test the wrong thing.

## 6. Debug menu (F2, `?debug` only)

A choice list built with the game's own dialog (so it works in 2D and 3D and needs no extra UI):
- warp to a map (paged list, start cell);
- start a troop by id;
- party +5 levels, full heal;
- give item; set flag; start vision for 60 s (if `CONFIG.vision`);
- toggle autoplay;
- toggle `noenemies`;
- dump `snapshot()` to the console and the clipboard.

Every entry calls the same functions as the URL surface. There is no second implementation. Show the fps counter only under `?debug`.

## 7. Play Stats page (the playtest feedback channel)

The page is in the pause menu, ships in release builds, and is what the G4 playtest report pastes back (PLAN §2, §8). It worked well in Shorelight (shorelight:js/engine/playstats.js). Port the design, with keys and titles from CONFIG.

### 7.1 Idle-aware clock

- `tick(rawDt)` is called by the main loop with the **unclamped** frame time. It counts only when all hold:
  - a game is running (`G.inGame`);
  - the tab is visible and the window focused;
  - `PlayStats.paused` is false.
- Time since the last real input is held as **pending**. The next input commits it.
- After `AFK_SEC` (180 s) with no input, the pending time is dropped. The clock winds back to the last input and stays stopped until a key is pressed.
- Frame gaps over 2 s (sleep, debugger, suspended tab) never count.
- Every input source (keys, held keys, mouse, wheel, touch, pad) calls `PlayStats.input()`.
- `stopReason()` returns `'' | 'title' | 'hidden' | 'blur' | 'paused' | 'afk'`. Show it on the page so testers trust the clock.

### 7.2 What is recorded (`G.state.stats`)

- `runId`: one id per new game, kept across saves.
- `chapters[ch]`: `{time, act:{dialogue, battle, explore, menu, minigame}, battles, wins, losses, gameOvers, flees, retries}`.
- `bosses[troopId]`: `{enemy, ch, attempts, wins, losses, retries, time, firstWin}`. `firstWin` = the attempt number of the first win, the number balance tuning cares about.
- `afk: {count, lost}`.

How each activity is classified:
- A scene's `statKind` (`battle`/`minigame`/`menu`) wins.
- Otherwise a dialogue scene on top, or a running script, counts as `dialogue`.
- Otherwise the time counts as `explore`.

New scene types declare `statKind`, so the classifier never needs editing.

Battle and retry hooks:
- `battleStart(sc)` and `battleEnd(sc, result)` are called by the battle scene.
- "Retry" on the game-over screen restores the pre-fight state but **keeps** the stats (`keep()` → `retry()`).

### 7.3 Persistence

Stats live in the save, plus a small **ledger** under `G.key('playstats')`:
- It is written every 15 s and keyed by `runId`.
- It keeps the 6 most recent runs.

Time played after the last save survives a quit. Loading an older save of the same run adopts the more complete stats instead of erasing them.

### 7.4 Page and copy-report key

- The page shows total time, a per-activity bar, a per-chapter table and a boss table (attempts, wins, first-win attempt, time).
- **Z (ok) copies a plain-text report.** It tries `navigator.clipboard`, then `execCommand('copy')`, then downloads `<CONFIG.id>-playstats-<date>.txt`, and it says which one worked.
- The report header carries the title, version, date, language, render mode, quality, `G.fps` median and `stopReason`, so a pasted report is self-describing. It also carries:
  - `sha:` the build's git sha (stamped by the packager);
  - `difficulty:` the current difficulty setting;
  - `autobattle:` the auto-battle style and items on/off (`off` when unused or the game has no battles);
  - `where: ch<N> <mapId> <x>,<y>`: the chapter, map id and tile at the moment of the copy.

  Phase 12 parses these, so it never asks the player what the report already answers.
- The report format is stable and machine-parsable (one `key: value` per line plus fixed-column tables). The forge's triage step (phase 12) parses it into balance and pacing notes. Example rows:

```
title: Ember Road 0.3.0   lang: en   render: 3d/high   fps: 58
sha: 4f2c9e1   difficulty: normal   autobattle: standard/items-on
where: ch2 mill_yard 14,9
total: 4:12:09   explore 41%  dialogue 27%  battle 24%  menu 6%  minigame 2%
ch  time     battles  W/L/F      gameovers  retries
2   0:48:10  31       29/1/1     1          1
boss            ch  attempts  wins  firstWin  time
t_c2_miller     2   2         1     2         0:06:40
```

### 7.5 Tests for the page itself

- Clock: replace `PlayStats.clock` with a fake. Then input → 10 s → input adds 10 s; 200 s of silence adds 0; a hidden tab adds 0.
- Classification per scene type.
- Retry keeps attempts.
- Ledger adoption on load.
- The copy path falls back to download when the clipboard is blocked.

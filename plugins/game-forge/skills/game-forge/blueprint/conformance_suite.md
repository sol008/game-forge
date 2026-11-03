# Engine conformance suite

These engine tests must be green **before content fan-out** (PLAN §5, phase 2). They run in both render modes. Each one encodes an engine bug that Shorelight's chapter builders hit, worked around separately and reported late (mined slices 01–04).
- The engine owner writes the suite from this spec, not from the engine's current behaviour.
- When a content agent reports a new engine bug later, it becomes a new numbered test here before the fix merges.
- **Battles.** C15 and C19 apply only when the game has battles (`CONFIG.battle` present); otherwise they are skipped and reported as `SKIP (no battles)`. The same goes for the battle bullets of C04 and C11.

## Harness

Two runners share one fixture set, `tools/test/conformance/fixtures.js`. That file defines maps `__conf_*`, troops `t___conf_*` and so on, and **only the tests load it**; it is never shipped content.

**N = headless Node.**
- A loader evaluates the game's scripts in `index.html` order inside a `vm` context. It provides a recording 2D context stub (a Proxy that logs calls and tracks a save/restore stack, transform, alpha and composite), plus `localStorage` and `performance`.
- There is no rAF. The test drives the loop with `step(n, dt = 1/60)`, which is deterministic.
- Input is injected at the `G.Input` key-state layer (`keyDown('ok')`, `step(1)`, `keyUp('ok')`), not through debug helpers.
- It is fast and runs on every commit.

**P = Playwright on `file://`.**
- Real keys come from `page.keyboard.press('z')` and `down`/`up`, with **autoplay off** unless the test says otherwise.
- It runs once in 2D and once in default 3D (`?r3lite` allowed for speed).
- It launches through the governor's browser slot (`tools/forge/governor.sh -- <cmd>`), with a 90 s no-output watchdog.

**Shared helpers** (the same ones the chapter tests use):

| Helper | Behaviour |
|---|---|
| `boot(q)` | load `index.html?debug&…` and wait for the title or the map |
| `idle({frames:2})` | resolves `true`, a terminal kind (`'gameover' \| 'title' \| 'ending' \| 'frozen'`, see `debug_hooks.md` §4), or `false` on timeout. Idle means: no script running, the map is the top scene, the fade is < 0.05, no auto event pending, and all of that holds for ≥ 2 consecutive updates |
| `run(fn)` | run a script on the current map and await it |
| `pressUntil(pred, key, max)` | press a key until `pred()` holds, at most `max` times |
| `onScreen(id)` | the actor's screen box (projected in 3D) lies inside the viewport with a 32 px margin |

**Failure conditions for every test:**
- a page error or console error (ignore `ERR_FILE_NOT_FOUND`);
- `G.lastError` set;
- a new `warnOnce` key not listed in the test's `allowWarn`.

**Exit gate:** all tests pass in N, plus the P subset in 2D and in 3D, with 0 warnings. Results go to `$SCRATCH/conformance.log`, ending in one `CONFORMANCE PASS n/n` or `FAIL` line. `tools/test/run.sh --quick` runs the suite with the validator and unit tests and exits non-zero on any FAIL; that exit code is what the merge gate's `FORGE_TEST_CMD` checks.

---

### C01 Awaited moves resolve
- **Asserts:** `await S.move(id, path)` resolves within `steps × stepTime + 0.5 s`. This must hold for:
  - the player;
  - each follower;
  - an NPC;
  - a spawned actor;
  - an empty path;
  - a path whose next cell is blocked (the actor stays put, one warning, and the promise still resolves);
  - `{wait:false}` (resolves at once, and the move still completes).
- **Why:** an awaited follower move never fired its arrival callback, which froze cutscenes in ch5, 6, 7 and 8 (mined_01 #9). Each builder patched around it separately.
- **How (N):** fixture map with 3 followers and 2 NPCs. Race `run(S => S.move(...))` against `step()` up to the bound, for each actor kind × the 4 path shapes. Also check `S.walkTo` around an obstacle.

### C02 Speed and state restored after scripted moves
- **Asserts:** after `S.move(id, p, {speed: 9, ghost: true})`:
  - `speed` is back to its base value;
  - `ghost` is cleared;
  - `scripted` is false once the script ends;
  - a following unscripted walk takes the base step time.

  This holds when two overlapping moves on the same actor use different speeds, when the script throws mid-move, and when `wait:false` outlives the script.
- **Why:** the `S.move` speed leak left NPCs and followers sprinting for the rest of the map (mined_01 #9).
- **How (N):** snapshot each actor's `{speed, ghost, scripted, visible}` before the script and compare after `idle()`. Time 4 player steps with the movement key held, against the base step time ±1 frame.

### C03 Draw-state isolation
- **Asserts:** every registry draw (tile, object, sprite, monster, portrait, backdrop) and every map hook runs inside `save()`/`try`/`finally restore()`. After a draw that leaks a translate, alpha, composite or clip, or that throws, the context state equals the state before it. Later draws in the same frame land at the right place. A thrower draws a placeholder and logs `warnOnce` once, not every frame.
- **Why:** a monster draw that skipped save/restore corrupted the transform of every later draw (mined_01 #9), and one art function's exception blanked the whole frame (mined_00 #8).
- **How (N):** register `__conf_leaky` (translate + alpha 0.2, no restore) and `__conf_throws`, then place both before a sentinel object on the fixture map. Render one frame with the recording context. Assert the save/restore stack depth is 0 at frame end and the sentinel's `drawImage` coordinates match a clean-run baseline. **(P)** a pixel check of the sentinel in 2D and 3D.

### C04 Null and absent BGM
- **Asserts:**
  - map `bgm:null` stops the music (`G.Music.current === null`);
  - `bgm` omitted keeps the current track;
  - an unknown id raises one warning and keeps the current track;
  - `S.bgm(null)` fades to silence;
  - after a battle, `bgmAfter: undefined` restores the map track and `bgmAfter: null` stays silent;
  - `ambience` plays independently of `bgm` and survives `bgm(null)`.

  No case throws or logs a console error.
- **Why:** `bgmAfter:null` raised a warning, and `bgm:null` after a battle misbehaved (mined_01 #9). Separately, a test asserted "no BGM" at the festival and locked in missing ambience (mined_04 P4).
- **How (N):** stub `G.Audio` as a recorder. Walk the 3 fixture maps with `bgm` = id, null and omitted; win a `t___conf_1hp` battle with each `bgmAfter`; read `G.Music.current` and `G.Ambience.current` after each step.

### C05 Camera, input and HUD restored at script end
- **Asserts:** after the outermost script ends, normally or by throwing:
  - the camera follows the player (`cam.follow === 'player'`, no target override), unless `S.camera.hold()` was called;
  - the input buffer is empty;
  - the HUD and letterbox are visible;
  - `hideFollowers` is false;
  - the dialogue box is closed;
  - the busy counter is 0, never negative.

  When auto event A ends and auto event B is pending, the camera is released after B, not between A and B.
- **Why:** `S.camera(15,8)` was never released after the ch2 mushroom scene, and 3 ch3 scenes had the same bug. The user found it by playing (mined_03 P8). Separately, the busy counter went negative (mined_00 #7).
- **How (N):** scripts that pan then end, pan then throw, `follow('npc')` then end, use `hold()`, and chain two auto events. After `idle()`, assert each field.

### C06 Player on screen after every cutscene
- **Asserts:** whenever a script ends and `idle()` resolves, `onScreen('player')` holds, unless the map declares `cameraHold`. The check runs as a harness hook (`afterScript`) that every chapter test and the chain test inherit.
- **Why:** this is the generic form of C05. The user saw the player walk out of frame in 3D, which every 2D-only test had missed (mined_01 #11, mined_03 P5/P8).
- **How (P):** register `afterScript` in the fixture runner, play the fixture cutscenes (pan away, warp mid-scene, setPos off-camera), and assert in 2D and 3D. In 3D, compute the box by projecting the player's world position through the 3D camera.

### C07 Map re-entry without reload rebuilds dynamic objects
- **Asserts:** after `S.warp(sameMap, x, y)` with no `reload`, these equal what a fresh load of that map with the same state builds:
  - the active object set (including `if` objects whose condition changed);
  - NPC presence and position (`pos`);
  - followers;
  - solidity.

  `live` objects track their condition frame by frame in both 2D and 3D.
- **Why:** the ch2 maze re-enters its own map. Footprints built only on entry vanished on later legs (mined_03 P9).
- **How (N):** fixture maze map with `leg` var-gated footprints. Advance `leg` and warp to the same map 3 times; after each warp, diff `{objects, npcs, solid}` against `fresh = new MapScene(id)`. **(P)** screenshot-diff the footprint cells in 3D.

### C08 Real key-press dialogue advance
- **Asserts:** with autoplay off:
  - a press while a page is still typing completes that page;
  - the next press advances exactly one page;
  - after the last page, a press resolves `say` exactly once;
  - the same press does not also trigger an interaction on the map;
  - holding the skip key advances; a mouse click behaves like Z.

  A 3-page × 2-line script needs exactly 6 presses (or 3 at max text speed).
- **Why:** the dialogue consumed `pressed('ok')` twice per frame, so real Z presses did nothing. Every autoplay test still passed (mined_00 #4).
- **How (P):** `boot('?debug&map=__conf_talk')`, walk to the NPC with the arrow keys, press `z`, then `pressUntil(() => !dialogOpen(), 'z', 20)`, and assert the press count and the final flag. Never call `G.Debug.talk`.

### C09 Full-footprint interaction
- **Asserts:**
  - For every multi-tile interactable (instance `w/h`, **or** registry def `w/h` with no instance size), facing any footprint cell from any adjacent walkable cell finds it.
  - Chests and `action` events with `w/h` follow the same rule.
  - The hint tag and glint centre on the footprint, not the anchor cell.
- **Why:** carts (ch9) and oars (ch10) were interactable from one half only, because the engine used the anchor or `o.w || 1` and ignored the def footprint (mined_04 P23).
- **How (N):** fixture objects of 2×1, 1×2 and 3×2, some sized only by their def. For every adjacent cell × facing direction, `setPos` and `face`, then call `findInteract()` and expect that object. **(P)** one real `z` press per object from its far half.

### C10 Choice parity: autoplay queue vs real input
- **Asserts:**
  - A script with 3 nested choices reaches the same flags and returns the same indices when driven by (a) `G.Debug.choices = [2, 'refuse', 0]` with autoplay on, and (b) real `ArrowDown`/`ArrowUp`/`z`/`Escape` presses.
  - `Escape` returns the `cancel` index.
  - A substring entry in the queue matches the translated label in both languages.
  - The pnr prompt defaults to "continue" (index 0) in both drivers.
- **Why:** autoplay was the only path many tests took (mined_00 #4, PLAN §7 row 1). The pnr "continue first" convention exists for autoplay; it must not diverge from what a player sees.
- **How (P):** run the fixture twice in fresh pages, serialise `G.state.flags`, and deep-equal the two. Repeat with `lang=en`.

### C11 Terminal-state detection
- **Asserts:** every terminal scene is registered in `G.Engine.terminalScenes` with a kind in `{'gameover', 'title', 'ending'}`, so detection never relies on `instanceof` one class or on one scene name. `idle()` resolves with that kind within 1 s for each of:
  - a battle loss without `loseOk`;
  - `S.gameOver()`;
  - a **chapter-registered custom game-over variant**;
  - returning to the title;
  - `S.ending('…')`.

  The frozen watchdog resolves `'frozen'` when the progress signature (scene stack, map, player cell, dialog line, battle turn) is unchanged for N s while a script is busy.
- **Why:** the "final boss stall" was the test's auto-battle losing and sitting on ch7's custom Game Over subclass, which the harness's `instanceof` check didn't recognise. That cost 15 min plus a cloud session (mined_03 P6). The ch11 test also hung 8 min with no watchdog (mined_02 P1).
- **How (P):** trigger each terminal from the fixtures, including a variant registered via `G.Engine.terminalScenes`. Assert `await idle()` returns the kind. For the frozen case, block a scripted await forever and expect `'frozen'` at N = 5 s.

### C12 Script-idle wait before input
- **Asserts:**
  - `idle()` never resolves `true` in the gap between two chained auto events, during a fade, or while a warp's `run` is pending.
  - Keys sent while busy are dropped at script end; they don't start an interaction afterwards.
  - Two scripts never run interleaved from player input.
- **Why:** 4 maps reported "soft-locks" that were really the test firing events during the opening cutscene, so 2 scripts ran at once (mined_03 P7).
- **How (N):** fixture with auto A → flag → auto B. Poll `idleNow()` every frame and assert no `true` before B ends. **(P)** hold `z` facing an NPC during a cutscene, then assert no talk starts after it ends.

### C13 Save/load round-trip mid-chapter
- **Asserts:** a save written mid-map (after a quest step, a chest opened, a `respawn:false` enemy killed, vision active, a member joined, a collectible lit) and loaded in a **fresh page** gives:
  - a deep-equal `G.state`, except `playtime` (which must not decrease);
  - the same active objects, NPCs and solidity as before saving;
  - an empty script stack, with the busy counter at 0.

  Loading while a script is running resets that script. Save keys use `CONFIG.id`.
- **Why:** this is the playtest path (G4) and the chain test's `--reload-at`. Script reset on load has been fragile (`Script.reset`), and stale state after reload hides the same bugs as C07.
- **How (P):** play the fixture to step 2, `S.saveMenu` → slot 1 with real keys, open a new context with the same storage, load via the title menu with keys, and diff. **(N)** `Save.write`/`read` JSON round-trip on 50 random fixture states.

### C14 i18n scope never overrides shared strings
- **Asserts**, in English mode:
  - **shared wins:** with `add('data', {X: 'A'})` and `add('c3', {X: 'B'})`, `t('X') === 'A'` at chapter 3;
  - **gap fill:** with `add('c3', {Y: 'C'})`, `t('Y') === 'C'` at chapter 3; at chapter 4, `Y` falls back to the source text, or to its gap-fill value if the design keeps global fills (pick one and assert it);
  - **templates:** the first registered match wins, and `%s` captures are translated;
  - **no inference:** scope never comes from `document.currentScript`; with no scope given, `add` throws.
- **Why:** short lines collided across chapters, and then chapter entries overrode shared item names (mined_01 #13). Separately, Node tests ran with chapter scoping silently off because `currentScript` doesn't exist there (repo_survey §2).
- **How (N):** pure unit tests on `G.I18N`. Also run over the real dictionaries: for every chapter key that equals a shared key, `t()` must return the shared value.

### C15 Level-up refill (QoL default) — only when battles exist
- **Asserts:**
  - When exp crosses a level, **that** member's HP and MP become the new maximums; the others are unchanged.
  - Status ailments are not cured.
  - The victory screen shows the refill line.
  - The HUD and menu show the new level on the next frame.
  - This holds after a multi-level jump and with `CONFIG.qol.levelUpRefill = false` (the switch is off: no refill).
- **Why:** the player ran dry of MP after a level-up (mined_04 P5), and the HUD showed a stale level (P6).
- **How (N):** a party at 1 HP / 0 MP gets exp for +1 and for +3 levels; assert the stats. **(P)** win `t___conf_1hp` with the battle UI on, read the victory text, and read the HUD level via the HUD's text recorder.

### C16 2D and 3D both render every chapter hook
- **Asserts:** for each map hook kind (`drawGround`, `drawOver`, `drawScreen`, `onUpdate`, spirit lights, decals, custom HUD meters) and each engine overlay (vision, fades, the HUD):
  - in **both** modes, the hook is invoked;
  - the frame differs from a hook-disabled frame in the expected region;
  - no errors;
  - the HUD is drawn exactly once per frame.

  After fan-out, the same check runs over every chapter's maps (the 3D sweep), not just the fixtures.
- **Why:** every test ran with 3D off while 3D was the default. Chapter decals, overlays and spirit lights broke, and ch9's HUD was drawn twice (mined_01 #11, mined_03 P5).
- **How (P):** fixture map `__conf_hooks` registers one hook of each kind drawing a marker colour. Screenshot it in 2D and `?r3lite`, sample the marker pixels, and count HUD draw calls via an instrumented `G.HUD.draw`.

### C17 Busy counter and re-entry
- **Asserts:** the busy counter is ≥ 0 after any sequence of run, throw and reset. `Script.reset()` (load, title) zeroes it and clears timers and tweens. Nested `G.Script.run` from inside a script (warp `run`, chest `run`) keeps the camera release (C05) for the outermost script only.
- **Why:** `running--` went negative (mined_00 #7), and nested scripts released the camera mid-scene.
- **How (N):** fuzz 200 random sequences of nested runs, throws and resets; assert the invariant after each.

### C18 Bad content id fails once, not every frame
- **Asserts:**
  - A roaming enemy with an unknown troop id ends its encounter once with `'error'`, one warning and no restart loop.
  - An unknown map, sprite, sfx or song id raises one warning and draws or plays a placeholder.
  - The validator flags every one of these statically.
- **Why:** a bad troop id restarted a failing battle every frame (mined_00 #9).
- **How (N):** fixture with a bad troop. Step 600 frames; assert `Battle.start` was called once and `warnOnce` fired once.

### C19 Battle result integrity — only when battles exist
- **Asserts:**
  - With `hpFloor` and `finishers`, the battle ends as a win only when every enemy is defeated or floored and finished. An ally reaching 0 HP never reads as a win.
  - `turnLimitResult` is honoured.
  - `endAt` ends at the threshold with no death animation.
  - `loseOk` returns `'lose'` and the story continues.
- **Why:** `hpFloor[tg.id]` returned `false` for allies, and `false != null` counted a falling ally as a boss win (mined_02 P8). Also, a floor set just above the win threshold hung the ch11 boss (mined_02 P1).
- **How (N):** run headless battles with a scripted policy against fixture bosses; assert the result and `party.some(alive)` at win.

### C20 Vision toggles
- **Asserts:**
  - `S.vision(sec)` makes `spirit` objects, chests and NPCs active and solid, and `illusion` objects inactive and passable, in the same frame.
  - On expiry, the reverse happens with one toast.
  - A map-constant vision level overrides expiry.
  - 3D shows and hides the same set.
- **Why:** spirit content and solidity drifted between modes and on expiry (mined_02 P4 shared-core fixes; mined_03 P9 3D brightness).
- **How (N):** toggle vision, diff the `solid` grid and `objActive` set. **(P)** sample spirit-object pixels in 3D.

### C21 Title cards and narration show over a fade
- **Asserts:**
  - after `S.fadeOut()`, a following `S.titleCard(…)` and `S.narrate(…)` are visible: their text pixels differ from black;
  - the fade still covers the map and every scene below the first `overFade` scene;
  - `G.Story.next` at a chapter end shows the next chapter's card.
- **Why:** the global fade was drawn over every scene, so a chapter ended on a black screen and its chapter card never showed. Every test passed because none looked at the frame.
- **How (P):** fixture script `fadeOut(0.2)` → `titleCard('T', 'S')`; sample frames during the card and assert non-black pixels in the card's text box, in 2D and 3D. The chain test (`qa_tools.md` §6) samples the same at every chapter boundary.

### C22 Poses and look-at hold steady
- **Asserts** (the 3D bullets apply only when the render mode is 3D):
  - `S.pose(id, 'lie_back', {on: bed})` lays the 3D figure along the bed with the head on the pillow end; the 2D sprite shows the same pose; walking clears it in both.
  - With look-at on and a held pose for 10 s, the head's world rotation stays within the clamp (e.g. yaw ±60°, pitch ±20°) and doesn't drift frame to frame; look-at is off while lying.
- **Why:** additive look-at rotations accumulated on bones three.js didn't rewrite in held poses, so heads spun. A sprite lay in bed while the 3D figure stood in it.
- **How (P):** fixture with a bed and an NPC; set each pose, read the rig's bone transforms and the figure's bounding box against the bed's; hold for 600 frames and assert the head-bone delta stays under 1° per frame.

---

## Run order and ownership

1. N tests on every engine commit: about 30 s.
2. P tests (C05, C06, C08–C13, C15 if battles exist, C16, C20, C21, C22 if 3D) in 2D and 3D, before every merge that touches the engine: about 5 min on 1 browser slot.
3. The `afterScript` hook (C06) and the terminal-state `idle()` (C11) ship inside the shared test library, so chapter, side-quest and chain tests inherit them.
4. Only the engine owner edits `tools/test/conformance/`. Content agents file engine bugs in this format: test id (new or existing), minimal repro, expected result, observed result.

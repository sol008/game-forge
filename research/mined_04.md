# Mined: tl_part_04 (2026-10-27 21:21 to 2026-10-29 02:25 UTC)

Slice covers late polish, cloud side-quest QA, repo migration, the post-release playtest fix loop, and the start of the game-forge request. Note: lines 222-504 and 505-787 are the same span replayed after a context compaction at 22:38. The repo moved from `/home/user/testProject/shorelight` (public testProject, branch `claude/magical-davinci-kp4fhq`) to `/home/user/shorelight` (private `sol008/Shorelight`, `main`).

## 1. Phases and outputs

| Time (UTC) | Output | Who | Duration |
|---|---|---|---|
| 21:21-21:27 | Answer: exact grove mushroom tiles (6,6) (23,8) (8,18), with annotated images | main | ~5 min |
| ...-21:39 | Point-of-no-return warnings: 20 one-way moments, 「繼續/再等等」, counts unstarted 心燈; guide 「不可錯過」 box | local subagent | (started earlier) |
| 21:56-22:01 | 扇貝殼 fix: NPC hint line, wider search area, mushroom offer always shown, brighter glint, guide corrected, annotated fort map via `shoot_maps.js` + PIL; ch3 soldiers test 19/19 | main | 5 min |
| ...-22:06 | Harvest markers: gold glow + floating 「採集」 tag (ch2 ingredients, ch7 雲芝); not on secret 靈視 finds | local subagent | |
| ...-22:30 | Smart F-key auto-battle: avg boss first-try win 37% to 94.5% (36 bosses x 300 sims); 夜玄→無相 8% to 94%; 0 items used in 173 normal encounters; settings 保守/標準/積極 + item toggle; PLAYING.md updated | local subagent | |
| ...-22:36 | Unobtainable items: strict scan found 37 (guide said 39); 498 items all have a source; 20 new chests on walkable tiles; balance check ≤ +2 vs shop gear | local subagent | |
| ...-22:38 | 3D batching (`perf-batch3d`): draw calls 494 to 64 on sugarcane_night; worst over 175 maps 494 to 204; +25-70% triangles; `?nobatch` flag | cloud session | merged 22:38 |
| 22:12-00:04 | Side-quest QA, 4 cloud sessions (`qa-side-ch0-2/3-5/6-8/9-11`): play each quest as a player, check completion, discoverability, missable windows; write PASS/FAIL scripts + report table; ch9-11 also checks 七仙蕈 chain and ending thresholds | cloud x4 | ch3-5 47 min, ch0-2 61, ch6-8 65, ch9-11 ~108 |
| 23:10-23:13 | Three design calls from QA report: ch3 先睡覺 second confirm, ch4 認輸 confirm by 紅纓, 麻糬 clue for chest c4_23 | main | 3 min |
| 23:13-23:29 | Repo migration: `git subtree split -P shorelight` (417, later 425 commits), merged onto user's README commit in `sol008/Shorelight`, no force push | main + user | 16 min (mostly user wait) |
| 23:36-23:39 | ch4 風穴石耳 靈視 glow, verified in 2D/3D screenshots | main | 3 min |
| 00:00-00:04 | Merge ch9-11, regenerate guide, RELEASE_NOTES, build `Shorelight-1.0.0-20261028.zip` (15 MB), unzip boot-check 2D+3D, send | main | 4 min |
| 00:32-01:05 | Local re-run of ch9-11 side scripts (ch11 rerun alone, 24/24) | main, background | 33 min |
| 10-28 05:04-22:50 | Player Q&A (剝皮寮, 柿霜 footprint, 山歌 answers/directions); festival ambience fix (ch4 test 195/195), new zip | main | 2-20 min each |
| 23:09-23:20 | Level-up full HP/真氣 refill + victory line + HUD level fix + unit test + guide, new zip | main | 11 min |
| 10-29 02:19-02:25 | game-forge proposal (skill + starter template + Shorelight as reference); user asks for a full plan first; transcript mining begins | main | |

QA results (cloud): soft-locks found that every earlier test missed. **ch11 lighthouse up-stairs on wall tiles on every floor** (finale unreachable on foot; the old test teleported). **ch9 sand bridge stranded the party.** **ch5 半邊井 心燈 permanently missable.** About 25 quests had no in-game pointer. Bare-tile items: 懷錶, 扇貝殼, ch9 log pages, ch10 招魂 spots and second oar, 風穴石耳, 潮音蕈, 玄武蕈. 府城藥鋪 now sells 七彩靈蕈. Endings confirmed: 28 心燈, 13 gives 彼岸, 14 gives 千燈.

## 2. Decisions

**User:**
- Run cloud QA for all side quests (22:12).
- Move the game to a new private repo, which the user created (23:27).
- Level-up should fully refill (23:09). The user proposed it and the assistant agreed.
- Asked for a "comprehensive plan first" before building game-forge.

**Assistant, made alone:**
- Split QA into 4 sessions of 3 chapters each, and folded the hidden-spot audit into them.
- Made the 3 missable-content design calls itself; it had told the QA sessions it would.
- No hint tag on secret 靈視 finds; an NPC hint is used instead.
- Resolved merge conflicts:
  - kept both `lib.js` files by renaming one to `lib68.js`;
  - ch10 chest table: took the QA version and kept the 釋迦 note.
- Merged on top of the user's README commit instead of force-pushing.
- Festival audio: no melody, drones only, following the screenplay rule "不得合成或模仿祭歌旋律". Gain was raised after measuring the track 6 dB under other tracks.
- Level-up refill applies only to the character who levels; status ailments are not cured.

**Asked the user:**
1. "Audit every chapter for invisible action-spot items?" (22:01, again 22:06). It was never answered directly; the user's cloud-QA request subsumed it. *A default rule ("no interactable on a bare tile without a visible marker plus an NPC hint", run as a validator) would pre-answer it.*
2. "Create an empty private repo, grant access, reply with the name" (23:13). Forced by the GitHub integration's 403 on `create_repository`. *A requirements template field "Private repo: owner/name (created empty, Claude access granted)" pre-answers it.*
3. "Make testProject private or delete game branches?" It was never answered. *Pre-answerable: never build in a public scratch repo.*
4. "Is the ambience volume/distance right?" A taste check with a 40 s preview attached. This one is legitimately human.
5. "Go with skill + template + example, or skill only?" The user redirected to planning first.

## 3. Problems and lessons

| # | Problem | Root cause | Fix | RULE |
|---|---|---|---|---|
| P1 | 扇貝殼 unfindable (user report) | Item on bare grass tile (3,5), single exact tile, hidden precondition (met ghosts at night), guide omitted condition | NPC line, area trigger, unconditional offer, glint, guide fix | Every interactable needs a visible marker or glint, an NPC or quest-log pointer, and a hit area of 2 tiles or more. Enforce with a validator over all `examine` events. |
| P2 | Same class found by QA in 8+ places plus ~25 quests with no pointer | No discoverability requirement during authoring; tests set flags directly | Cloud QA added clues | Run discoverability QA **before** first ship, not after the user trips on one. Every quest step needs `hint` metadata, which the validator checks. |
| P3 | ch11 lighthouse stairs on wall tiles; finale unreachable | Chapter test **teleported** past floors (a test that lied) | Fixed tiles | Tests may not teleport across the critical path. Add a pathfinding reachability check (BFS from entry to every exit, stair and quest target) to the validator. |
| P4 | Festival night silent; user reported "no chanting" | Screenplay required ambience, but code had none, **and ch4 test asserted "festival night: no BGM"**, freezing the bug | New ambient track in `js/core/music.js`, fade in/out, test updated | Derive audio assertions from the screenplay's sound notes (scene to required cue). A test must encode the spec, never current behavior. |
| P5 | Level-up did not refill; player stuck with 0 真氣 | Design default copied from PAL95-era conventions | Full refill for leveled member, victory line in zh/en, unit test | Ship a default QoL list in the template: level-up refill, auto-save, auto-battle, point-of-no-return warnings, 2x speed. |
| P6 | HUD level stale after level-up | Victory HUD never re-read level | One-line fix | Screenshot every UI state change with real flow, not forced state. |
| P7 | ch8 `tide` test Game Over on base branch | Test omitted `s.gear()` so party fought ungeared (test setup, not game) | Added gear | Use one shared `chapterStart(ch)` fixture (level, gear, items) for every test session. A failing test on base gets root-caused within the hour. |
| P8 | Validator warnings 15 to 18 after merge | Flags built dynamically (`'ch4_pc_'+k`), invisible to static scan | Judged false positive | Forbid dynamic flag names, or declare patterns in a registry the validator reads. Keep warnings at 0 so new ones stand out. |
| P9 | Merge conflict: two QA branches each created `tools/test/sidequests/lib.js` | Parallel briefs did not reserve file names | Renamed to `lib68.js` | Each parallel brief names its exclusive new-file namespace, e.g. `sidequests/ch6_8/*`. Shared helpers are created before fan-out. |
| P10 | Conflict: ch10 guide chest table edited by item-placement and QA | Hand-edited generated guide | Took QA version | Guide is generated from game data only; nobody hand-edits generated sections. |
| P11 | Helper broke another's test mid-edit (ch11 test hit map-drawing error from in-progress sparkle code) | Multiple local agents share one working tree | Waited | One worktree per local agent; merge only green branches. |
| P12 | Stop hook "uncommitted changes" fired 4+ times; `WIP snapshot` commits; ch3/ch4 fixes pushed before their tests finished | Shared tree dirty from background helpers; stop hook demands clean tree each turn | Loop `git add -A; commit` | Worktree isolation (P11) keeps main tree clean. Commit only verified units; never use blanket WIP commits. |
| P13 | Untranslated lines (4 each in ch3/7/9) from item-placement helper | i18n not part of helper's done criteria | Patched later | Validator fails on any zh key missing en. Put it in every brief's definition of done. |
| P14 | Guide count 39 vs real 37 unobtainable items | Guide's rougher heuristic | Strict scan | Single source of truth: the validator's item-source graph feeds the guide. |
| P15 | ch11 side test killed at 30-min background limit | Default background timeout | Rerun alone with 90-min limit (took 33 min) | Set explicit timeout ≥ 2x expected. Split suites per chapter so none exceeds 20 min. |
| P16 | GitHub `create_repository` 403 | Integration lacks repo-create permission | User created repo | Ask for the private repo in the requirements intake at minute 0. |
| P17 | User's repo was not empty (README) | Instructions not followed exactly | Merge, no force push | Always inspect the target before pushing; merge, never force. |
| P18 | Game public in testProject for 2 days | Built in user's scratch public repo | Migrated; user told to privatize | Start in a dedicated private repo. |
| P19 | Misspelled `sol08/Shorelight` twice | Typing from memory | Corrected next message | Copy identifiers from tool output. |
| P20 | Screenshots caught random battle; victory screen already closed; CJK font missing in PIL labels; label used wrong street name | Ad-hoc screenshot scripts | Debug flag to clear enemies, poll state, game's bundled font, name from map data | Build a `shoot.js` harness with `noEncounters`, `waitForState`, bundled CJK font, and labels pulled from map data. |
| P21 | Noise messages "helper's monitor timed out, nothing changed" (3x) | Stale background waits relayed to user | None | Suppress no-op notifications; report only state changes. |
| P22 | QA used shortcuts (debug map with flags, level boosts, simulated shop buys) | Full play too slow | Accepted | State the shortcuts in each report. Keep at least one no-shortcut full-chain run per release. |
| P23 | 2-tile-wide objects interactable from one half only (ch9 carts, ch10 oars) | Engine uses object's nominal tile | Fixed where found; remaining chapters unchecked | Engine: interaction hitbox = full footprint. Validator flags multi-tile objects. |

## 4. Process patterns

**Worked**
- **Cloud fan-out by chapter range.** Each session had its own branch and machine, so the local CPU stayed free. Each brief held one detailed goal list: play like a player, never set quest progress, check discoverability and missables, fix, add English, update the guide, write a PASS/FAIL script and a report table.
- **Cloud lifecycle**:
  - `send_later` check-ins (23:05, re-armed, 00:00);
  - `list_events` to see whether a session is final;
  - fetch, test-merge, merge, run unit (64/64) and validate, then push;
  - `send_message` "merged, please stop, don't push further".
  - It merged partial results early (ch9-11 merged while its final test run was still going).
- **Main thread used idle time well.** It made the QA sessions' design calls while waiting, and re-ran each merged branch's scripts locally.
- **Merge gate**: unit + validate after every merge, plus the merged chapter's side scripts.
- **Release gate**: build zip, unzip, boot 2D and 3D to the title screen, screenshot, send. Each release also updated `docs/RELEASE_NOTES.md`, removing items once they were fixed.
- **User-facing answers in the user's language.** Chinese answers carried annotated maps, rendered by `tools/guide/shoot_maps.js` and marked up with PIL.
- **Verifying the fix in game data, not just visuals.** It emptied 真氣 before the fight, then asserted full after.

**Failed / weak**
- **Shared working tree** for several local helpers caused P11, P12 and P13.
- **Reactive QA.** Discoverability and soft-lock QA came only after the user found a bug. It should have been a pre-ship phase.
- **The assistant's own retrospective (02:19):** "Your playtesting found most of the real problems… Automated tests passed right over every one of them." That covers the camera, the footprints, the shell, the festival silence and the level-up refill.
- **Cost transparency.** It noted "$5-40 per cloud session" but gave no budget cap; quota pressure was a theme earlier.

## 5. Handholding in this slice

| Time | User message | Class | Removal |
|---|---|---|---|
| 21:56 | 扇貝殼 "never happens" | Avoidable | Discoverability validator + pre-ship QA (P1-P2) |
| 22:12 | "start cloud tasks to verify side quests" | Avoidable | Make side-quest walkthrough QA a mandatory phase in the playbook |
| 23:27 | "done with the new repo" | Avoidable (one-time setup) | Repo in requirements intake |
| 01:29 | "give me the latest zip" | Avoidable | Always attach the current zip and its path at every release, and pin "latest build" in a status artifact |
| 05:04 | "where is 剝皮寮" | Avoidable | Guide must include an annotated image of every map, with exits and named locations |
| 05:53 | "where is 柿霜上的四爪腳印" | Avoidable | Guide generator marks every quest clue tile on its map (the hakka_road map had no image) |
| 21:51 | "山歌擂台 answers" | Avoidable | Guide auto-documents every minigame: scoring, best answers, win thresholds |
| 21:52 | "what are all the directions" | Avoidable | Same; state "randomized" in the guide plus the pitch mnemonic |
| 22:27 | no chanting at 向天湖 ritual | Partly avoidable | Screenplay-to-audio-cue assertions (P4); final feel stays human |
| 23:09 | level-up should refill | Necessary-human (playtest feel), but pre-emptable | QoL default list (P5) |
| 02:19 / 02:21 / 02:24 | praise, skill request, plan-first | Necessary (direction) | n/a |

Ratio: about 8 of 11 interventions were avoidable. Most fall into two buckets: **guide completeness** (4) and **discoverability or spec-conformance QA** (3).

## 6. Tools, scripts and docs referenced or created

- `scratchpad/withbrowser.sh`: browser queue wrapper. It serializes headless-Chrome tests, used as `withbrowser.sh timeout 900 node ...`.
- `tools/test/chapters/chN.test.js <session>`: per-chapter scripted playthrough sessions. Examples: ch3 `soldiers` 19/19; ch4 195/195; ch8 `tide`/`river`; helpers `s.gear()` and boost.
- `tools/test/sidequests/` (new, from cloud QA): per-chapter side-quest PASS/FAIL scripts plus `lib.js` (ch0-2) and `lib68.js` (ch6-8). The ch9-11 scripts are self-contained.
- `tools/guide/shoot_maps.js <map>:vision --force`: renders map images into `docs/guide/img/map_*.jpg`.
- Guide builder: regenerates `docs/guide/` (attaches as `GUIDE/` in the zip). It reports "0 unreachable items".
- Validator (`validate`): flag read/set, item sources, i18n. Unit tests: 64/64.
- `render_music` tool: renders a track to audio and measures loudness and loop seams.
- Zip builder + zip checker: unzip, then boot 2D and 3D. Output `Shorelight-1.0.0-20261028.zip`, with `Play Shorelight.command` for Mac (Gatekeeper "Open Anyway" note).
- Docs:
  - `docs/RELEASE_NOTES.md`
  - `PLAYING.md` (zh/en manual)
  - `docs/guide/chapters/ch03.md` etc.
  - balance notes
  - the screenplay sound notes, which were the source of truth for P4
- In-game: 遊玩統計 page, where Z copies a play report to paste to Claude (a playtest telemetry channel); `?nobatch` URL flag; 自動戰鬥 settings.
- Game files touched:
  - `js/maps/ch3_guanyin.js`, `ch4_hsinchu.js`
  - `js/i18n/en_ch3.js`
  - `js/core/music.js` (new festival ambience song)
  - `js/engine/map.js` (`drawHints`)
- Forge mining: `scratchpad/forge/user_msgs.txt` and `tl_part_00..04` (condensed timeline split in 5).
- Proposed: `sol008/game-forge` repo with `.claude/skills/game-forge/`, plus a starter template extracted from Shorelight:
  - engine: map, battle, auto-battle, menus, minigames, i18n, save, Play Stats, 3D;
  - tools: validator, unit tests, side-quest and full-chain harnesses, `sim_economy`, guide builder, packaging, font builder.

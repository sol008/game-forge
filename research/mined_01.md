# Mined slice 01: 2026-10-27 06:44 to 09:20 UTC (~2.6 h)

This slice runs from finishing the design picks, through cutting a pet, a parallel finish of all chapters with a browser-test queue, parallel English translation and engine fixes, to resuming the cloud 3D teams. The repo is `/home/user/testProject/shorelight`, on branch `claude/magical-davinci-kp4fhq`.

## 1. Phases and outputs

| Time | Phase | Who | Output |
|---|---|---|---|
| 06:44–06:48 | 紅纓 (pick 01) and 雲歸 (pick 01): bake the portraits, sync the sprite palette, update the bibles, commit | Main, serialized because of quota | Portraits, sprite tweaks, `docs/design/PICKS.md`, both story bibles |
| 06:48–06:56 | 芋圓 options 02–10, render, montage, sheet, doc | Main | `docs/design/v2/yuyuan_sheet.png` (about 8 min, about half of it spent debugging the SDF engine) |
| 07:01–07:06 | 麻糬 10 options | Main | `tools/design2/mochi.js`, sheet and doc (about 5 min) |
| 07:12–07:16 | 糰子 rebuilt from scratch (his old option file used a helper library that was never written) | Main | `tools/design2/tuanzi.js` and 10 options. This was wasted work: he was cut 6 min later. |
| 07:22–07:25 | Cut 糰子: his summon became 白芷's 貓咪助陣 (Lv10, random 芋圓 or 麻糬 outcomes), plus bibles, WRITERS_GUIDE, i18n, the 3D contract, and an in-browser skill test (6 casts) | Main | About 3 min. About 800 lines in ch3–11 were left for the chapter builders. |
| 07:33 | Resume only the ch1 builder (quota) | Local subagent | |
| 07:52–08:48 | "Full speed": resume all 11 chapter builders (ch1–11) with one standard change brief | 11 local subagents | ch2 done about 08:20; ch1 and ch5 08:22; ch3 08:28 (130/130); ch7 08:29; ch6 08:30; ch8 08:34; ch10 08:40; ch4 08:42 (138/138 + 57/57); ch9 08:48; ch11 still testing at 09:20. **10 chapters finished in about 1 h** once the test queue was in place. |
| 08:13–08:22 | Engine bugs reported by the builders, fixed centrally | Main | Fixes in `js/engine/map.js`, `battle.js`, `menu.js` |
| 08:44–09:05 | English translation: `en_ch0..11.js` stubs, then 5 pair agents (0+1, 2+3, 4+5, 6+7, 8+10) and ch9 at 08:47 | 6 local subagents | Ch0–10 at 99–100% by 09:05, about 20 min. The estimate was 25–35 min; actual rate was about 100 lines/min per agent. |
| 08:45–09:16 | Engine agent: 3D hooks (decals, overlays) and leftover gameplay bugs | Local subagent | 7 fixes |
| 09:01–09:03 | Merge `origin/r3d-chars` (71 rigged figures; checked first with `git merge-tree --write-tree`); resume 10 cloud teams (`r3d-animals`, `-arch-han`, `-arch-coast`, `-nature`, `-props-street`, `-props-interior`, `-monsters-a`, `-monsters-b`, `-env`, `-battle`) | Cloud sessions | The chars team alone cost about $35 |
| 09:02 | Boss balance agent: simulator with an AI that heals and uses items, realistic level and gear, target 70–90% first-try wins, writes `docs/BALANCE.md`. Party 3D-costume agent: applies the v2 picks and compares against the sheets. | 2 local subagents | |
| 09:16 | ch11 translation split across 2 agents (`en_ch11.js` + `en_ch11b.js`; loader regex `en_ch(\d+)[a-z]?`). Started before ch11's tests finished, because only battle tuning was left. | 2 local subagents | |

Measured timings:
- A chapter's full test run takes 10–15 min when it has the machine to itself (ch1 10.5 min, ch2 14 min, ch3 12 min, ch6 3.5 min).
- Finishing a chapter took 30–90 min, mostly test → fix → re-test the failing segment.
- With about 12 browsers running at once, everything ran 2–3× slower.

## 2. Decisions

**Made by the user**
- Design picks: 雲歸 01, 芋圓 07, 麻糬 04.
- Cut 糰子.
- "yes go ahead" to the chapter-by-chapter rewrite.
- "full speed, finish all chapters first."
- Throttle tests ("only run test for the first 4").
- "report more frequently."
- "use extra CPU" and "pick up extra work."

**Made by the assistant without asking**
- Converted the 糰子 summon into a cat-assist skill and redistributed his gags (雲歸 eats the mushrooms; 芋圓 gets the gluttony and panic gags; 麻糬 sniffs out mushrooms).
- Engine change: 麻糬 follows while `mochi_joined` is set, even when 白芷 is absent.
- Test-slot scheduler. Chapter pairs for translation.
- Chapter-scoped i18n dictionaries.
- Renamed the dessert item to 芋圓湯 "Taro Ball Soup" so 芋圓 always means the cat "Taro".
- Lore rule: 白芷 has silver hair and gold eyes only in her true lamp-spirit form.
- Renamed the speaker 銀髮少女 to 提燈少女.
- 回魂香 revives the whole party at 30%, and its price went from 420 to 1200.
- Merged r3d-chars. Resumed the cloud teams. Set the balance target.
- Deferred Mac packaging until the text is final, because the font subset depends on it.

**Questions the assistant asked, and whether a default would have answered them**
- "Pick a number" (×3 sheets). This is taste. A template field such as `design_picks: auto|ask`, with "recommend and proceed; the user can override later," would remove the block. The assistant kept working on the next item meanwhile, which was correct.
- The chapter-by-chapter 糰子 rewrite, answered with "yes go ahead". This could have been pre-answered by a rule: "when the user cuts content, propagate the cut everywhere without asking."
- "Tell me if you'd rather keep 回魂香 cheap." This was non-blocking and is the right style: decide, then disclose.
- The battle cloud team's "resume?" prompt needed the user to answer in that session. A launch brief that says "the lead may pause or resume you" would have pre-answered it.

## 3. Problems and lessons

| # | Problem | Root cause | Fix | Rule |
|---|---|---|---|---|
| 1 | SDF engine error on 芋圓 option 06 | Generated cone code reused the names `x2/y2/z2`, which collided with outer transformed coordinates | Renamed them with unique suffixes | Codegen must use gensym/unique identifiers. Add a fuzz test that renders every primitive nested inside every transform. |
| 2 | Option 09's stone shield was invisible; about 9 re-renders by trial and error (06:52–06:54) | Real cause: the bounds pass-through was culling geometry. Rotation guesses wasted the time. | Evaluated the SDF at the slab's position and fixed the bounds | When a render is invisible, query the distance field or render a debug multi-view **first**; don't tweak transforms. Document primitive axis conventions. |
| 3 | 麻糬 calico failed with "missing material 0" | Fur displacement (−6 cm) went beyond the bounding-proxy margin, so rays hit an empty proxy | Widened the margin | Bound margins must include the maximum displacement. Assert in the compiler. |
| 4 | NaN on 麻糬 option 10 | `E.bez` returns a flat list; nested pairs were appended to it | Fixed the call | Helpers need typed or JSDoc return shapes, plus a quick shape assert. |
| 5 | 糰子's sheet was fully built, then cut 6 min later; about 800 lines across ch3–11 needed rewriting | The cast roster wasn't re-confirmed after the user added two real cats as new pets | Cut and redistributed his material | When new cast is added, ask once: "keep or cut overlapping cast?" Lock the cast roster before generating any assets. |
| 6 | Hit the monthly spend limit at 07:00 and 07:35. The user had to retry; the assistant can't raise billing. | No budget plan | The user raised the limit; work was serialized for a while | Requirements should state a budget and a quota mode. Show a cost estimate per team (the 3D chars team cost about $35). On a quota hit, checkpoint and commit everything. |
| 7 | Tests 2–3× slower, load average about 26 on 4 CPUs | 11 agents × headless Chromium (about 12 browsers), some agents running 2 tests at once | Browser-test **slot queue** of about 3–4; others report "READY FOR TEST"; 3D off; one test process per agent; segment runs `--from/--only`; screenshots only on failure. The validator runs without a browser. | Run a browser semaphore of about nproc−1 from day 1, through a lock-file queue script. Never let agents launch browsers freely. |
| 8 | The ch1 builder polished for 30 min after 6/6 passed (adding a real-keypress check that then failed) | No definition of done or stopping rule | Lead: "wrap up, fix only that failure, report FINISHED" | Every brief needs a done criterion: tests pass + validator clean, then commit, report and stop. Extra checks go in a backlog. |
| 9 | Engine bugs surfaced only during content work. Each builder wrote its own workaround. Bugs: an awaited follower move never fired `onArrive` (cutscenes froze, hit by ch5, 6, 7 and 8); `S.move` speed leak; a monster draw corrupting the transform of every later draw (missing save/restore); `bgmAfter:null` warning; map `noSave` couldn't depend on state; idle / `S.light` / sfx gaps; `bgm:null` after a battle | No engine API test suite before content fan-out | The lead fixed each one centrally and broadcast "workarounds optional" | Single engine owner. Builders report engine bugs in a fixed format and don't patch the engine. Write engine API conformance tests (await move, speed restore, draw isolation, null bgm) before fan-out. |
| 10 | **Tests lied about balance**: boss tests passed only because the test boosted the party (ch8 to Lv36 vs about 28 expected; ch10 too). The ch3 ambush wiped a Lv11 party 2 times in 3. ch8 hit Game Over. | The test harness sets level and gear freely | Separate balance-sim agent at the expected level and gear | Tests must load level and gear from the canonical progression table. Any override fails CI. A balance sim with a win-rate target is a required phase. |
| 11 | Tests ran with 3D off, but 3D is the default mode. Chapter decals, overlays, spirit lights and ch9's HUD (drawn twice) were broken in 3D. The later ch2 camera bug the user hit was also in 3D. | Tests turned 3D off for speed | Engine agent added the 3D hooks | Run every chapter at least once as a smoke pass in the **default** render mode. Check both render paths for every chapter-specific visual hook. |
| 12 | Text didn't match the chosen look: 白芷 described as silver-haired with gold eyes (ch1, 4, 7, 9) | Text was written before the design pick and nobody re-swept it | Grep sweep plus the lore rule | After any design lock, write an `appearance facts` file and grep the scripts for conflicting descriptors (hair and eye words). Make it a validator lint. |
| 13 | i18n: short lines (誰？ 好！) collided across chapters in one global dictionary. Then chapter entries overwrote shared UI and data strings (the cat "Taro" would have renamed the "Taro Balls" item everywhere). | Flat global dictionary | Chapter-scoped dictionaries (`G.state.chapter`) that only fill gaps and never override en_ui or en_data | Design i18n as `shared` + per-scene/chapter scopes from the start. Keep a glossary with the cast names (Taro, Mochi). |
| 14 | Cat character and dessert item shared the name 芋圓 | Name collision in the data | Renamed the item to 芋圓湯 | Lint for unique names across characters, items and skills. |
| 15 | A cat spoke a line in ch10, against the silent-cats rule; a timeline slip ("last Ghost Festival" where it should be "eighteen years ago") | Constraints existed only in prose | Translators caught them | Encode character constraints as lint (a speaker whitelist; silent characters can't have dialogue). A canonical timeline file. Translators work well as a second QA pass. |
| 16 | Glyph puzzles (the 洛 lantern, ch1 mine-lamp marks, 山歌 rhymes) can't be translated directly | Language-dependent puzzle content | Kept the Chinese glyph with a gloss; wrote new English rhyming couplets | The translation brief should flag puzzles; the extractor should mark glyph keys. |
| 17 | The ch11 dictionary was too large for one agent | 2,464 lines | Split into `en_ch11b.js` with a loader regex | Split translation units at about 1,200 lines. |
| 18 | After context compaction at 08:20, the lead had to grep the session `.jsonl` to map agent IDs to chapters | No agent registry | Grep | Keep `scratchpad/agents.json` (id, task, branch, status, log path), updated on every launch. |
| 19 | User asked "is ch3 stuck?" It wasn't: it was waiting on a 12-min test. | No heartbeat | Tailed the logs | Test harness prints segment progress and timings to a known log. Add a `status.sh` that summarizes all agents. |
| 20 | Cloud battle team refused the lead's resume: the earlier pause counted as coming from the user, so the session waited for the user's own confirmation. It had also written zero files in its first run (planning only). | Cross-session messages aren't consent | User had to reply in that session | The launch brief should say up front that the lead may pause or resume the team. Prefer finishing over pausing. Make cloud teams push their first files early. |
| 21 | Stop-hook "uncommitted changes" fired **17×** in 1.5 h; repeated `for i in 1 2 3; git add -A; commit "WIP snapshot"` | Many agents write into the shared working tree | WIP snapshot commits | Agents commit their own files at milestones. The lead auto-commits on a timer. Use worktrees/branches per agent, or a commit daemon. |
| 22 | ch5 test failed after the chapter had already ended | Test kept waiting after the hand-off to ch6 | Test fixed | Hand-off assertions end the segment. |

## 4. Process patterns

**Worked:**
- **Standard change brief** broadcast to all builders through SendMessage: cut list, cast additions, locked looks, done criteria. 11 builders were resumed in about 1 min.
- **Test-slot queue** run by the lead ("your slot is open now; ch3 finished"). Load dropped from about 26 to about 5–10. 10 chapters closed in about 1 h.
- **Segment test runs** (`--from`, `--only`). Re-run only what failed.
- **The lead owns the engine.** Fixes were made centrally and broadcast with "workarounds optional".
- **Backfilling idle CPU** with text-only agents (translation uses almost no CPU).
- **Pairing translation chapters** across 6 agents, plus a glossary and coverage tooling (`extract.js`). Translators also served as QA: they found 6 source bugs.
- **`git merge-tree --write-tree`** to check a merge is clean before merging a cloud branch.
- **Self-scheduled check-ins** every 15 min with `send_later`, with progress tables that include ETAs.
- **Decide and disclose** for non-taste calls (the 回魂香 price).
- **Deferring packaging** until the text is final, because the font subset depends on it.

**Failed:**
- Unbounded browser parallelism.
- No definition of done (the ch1 polish).
- Builders patching around engine bugs.
- Pausing cloud sessions with a message that later blocked their resume.
- No agent registry before compaction.
- Commit-nag churn.
- Reports only in reply to user questions, until the user asked for a cadence at 08:24.

## 5. Handholding in this slice

| Time | Intervention | Class | How to remove it |
|---|---|---|---|
| 06:46, 07:00, 07:12 | Design picks 01, 07, 04 | Necessary (taste) | Non-blocking already; option to auto-pick the recommended one |
| 07:00 | "Try again" ×2 (spend limit) | Avoidable | Budget field in requirements, a cost forecast, a checkpoint on the limit |
| 07:22 | Cut 糰子 | Necessary (scope), but cheaper if asked earlier | Lock the cast roster when cast is added |
| 07:33 | "yes go ahead" | Avoidable | Rule: propagate a user's cut without asking |
| 07:35 | "update monthly spending" | Necessary (billing) | Upfront budget |
| 07:39 | "continue?" | Avoidable | Proactive status cadence |
| 07:52 | "full speed again" | Avoidable | A quota/pace mode in requirements |
| 08:09 | "tests are slow" | Avoidable | A browser semaphore from the start |
| 08:24 | "report more frequently" | Avoidable | A default 15-min report cadence |
| 08:26 | "check if ch3 is stuck" | Avoidable | Heartbeat logs and an automatic stall detector (no log change in N min triggers a ping) |
| 08:43, 09:01 | "extra CPU or bandwidth? pick up work" | Avoidable | Auto-backfill: when load < nproc and the backlog isn't empty, launch the next work package |
| 08:49 | "how long does translation take" | Avoidable | Put ETAs in every report |
| 09:19 | "3D teams paused?" | Avoidable | Watch cloud sessions (get_session status_bucket) and report blocked ones; settle resume authority at launch |

13 of the 16 interventions were avoidable. Only the design picks, the scope cut and billing truly need the user.

## 6. Tools, scripts and docs touched or created

- `tools/design2/mochi.js`, `tools/design2/tuanzi.js`, and the 芋圓 option code: 10-option character/pet generators using an SDF engine plus a cat kit (coats, poses, charms).
- `docs/design/v2/{yungui,yuyuan,...}_sheet.png` and the matching docs: option sheets and cards, montages in the scratchpad `pets/`.
- `docs/design/PICKS.md`: record of the design picks and cuts.
- `docs/STORY_BIBLE.md`, `docs/STORY_BIBLE_zh.md`, `WRITERS_GUIDE.md`: canonical lore. 糰子 is marked cut.
- `docs/CONTRACTS_3D.md`: the interface contract for the cloud 3D teams. `docs/r3d_reports/TEAMS.txt` is the team list.
- `docs/story/chN_*.md`: screenplays, kept in sync with `js/maps/chN_*.js`.
- `tools/test/chapters/chN.test.js`: playthrough tests by segment (`--from/--only`). Logs go to the scratchpad (`c1/`, `ch3/`, `c11b/runN.log`).
- The chapter validator (no browser; flags unreachable chests).
- `tools/i18n/extract.js` (`--missing`): coverage per chapter and the missing list. `tools/i18n/GLOSSARY.md`: names (Taro, Mochi).
- `js/i18n/en_chN.js` (+ `en_ch11b.js`), `en_ui.js`, `en_data.js`; `js/core/i18n.js`: chapter-scoped, never overrides shared strings.
- `docs/BALANCE.md`: written by the balance-sim agent.
- `~/.claude/stop-hook-git-check.sh`: the commit or push nag.
- `send_later`: the 15-min progress-check prompt, which re-arms itself.
- `Play Shorelight.command` and `build_font.py`: Mac launcher and font subsetting, deferred until the text is final.

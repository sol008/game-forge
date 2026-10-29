# forge-tools

These scripts are orchestration tools for game-forge, not game code. They fix the Shorelight failure modes:
- browser oversubscription and queue starvation;
- "is it stuck?";
- no agent registry after compaction;
- silent agents;
- untested release zips.

**Where they live in a game.** Phase 00 copies this folder into each game repo as `tools/forge/`
(and records the game-forge commit sha in `docs/forge/env.md`). Cloud sessions check out only the
game repo, so this is how they get the tools. Phases, briefs and the examples below call them as
`tools/forge/<tool>`, never `forge-tools/` or `$FORGE/forge-tools`. Fix tools here in game-forge,
then re-copy them.

Bash scripts run on Linux and macOS (bash 3.2+, no `flock` needed). The Node tools need `require('playwright')`.
None of them makes network calls. The exceptions are `merge_gate.sh`'s `git fetch`, the browsers loading local `file://` pages,
and `release_gate.js --url`, which loads a hosted build.

| Tool | Usage |
|---|---|
| `governor.sh` | `governor.sh [--prio] [--max-hold SEC] [--] <cmd...>` runs `cmd` in a browser slot. `--status` lists holders and waiters, and `--set-slots N\|auto` retunes the slot count live. |
| `agents.sh` | `agents.sh add <id> <task> <branch> <log> [eta]` · `set <id> status\|eta\|note <val>` · optional `set <id> worktree <path>` and `set <id> chapter <n>` · `done <id> [status] [note]` (terminal statuses only: `done failed stopped merged cancelled`) · `list` (also `get`, `rm`, `tsv`) |
| `status.sh` | `status.sh [--if-changed]` prints one markdown table for the check-in. It exits 3 if any agent is stalled. |
| `watchdog.sh` | `watchdog.sh [-q] <logfile> [sec=90] -- <cmd...>` kills `cmd` when the log stops growing for `sec` seconds, prints the last 20 lines and exits 125. |
| `merge_gate.sh` | `merge_gate.sh [--check] <branch>` does a fetch, a `merge-tree` pre-check, `merge --no-ff` and tests. On red it rolls back. It never pushes. |
| `release_gate.js` | `node release_gate.js <zip> \| --url URL [--modes 2d,3d] [--out DIR] [--entry index.html] [--settings-key KEY --settings MODE=JSON] [--query MODE=QS] [--press KEYS] [--assert JS] [--allow-net]`. With `--url` it loads a hosted build instead of unzipping: requests to the URL's own origin are allowed, other origins are errors unless `--allow-net`, and HTTP responses ≥ 400 are errors. |
| `shoot.js` | `node shoot.js --url URL\|PATH [--eval-before JS] [--wait-for JS] [--press KEYS] [--out PNG] [--viewport WxH] [--label x,y,text] [--labels-eval JS] [--font FILE\|--font-b64 DATA\|--font-from-page JS]` |
| `cost_estimate.md` | The canonical per-phase numbers (cloud $ and local agent-hours, full and mini sizes), Shorelight's measured data, how to calibrate `L` and report spend, and the G0b cap question |

Every tool takes `--help`. `_lib.sh` and `_lib.js` hold shared helpers.

## Environment

| Variable | Default | Meaning |
|---|---|---|
| `FORGE_DIR` | `$PWD/.forge`. Inside a git repo, the `.forge` of the **main** checkout, so every worktree shares it. | State: `governor/`, `agents.json`, `queue.log`, `watchdog.log`, `spend.txt`, `budget.txt`, gate logs and screenshots. The tools write a `.gitignore` containing `*` into it, so it is never committed. |
| `FORGE_SLOTS` | `nproc − 1`, minimum 1 | Browser slots. `governor.sh --set-slots N` (the file `governor/slots.conf`) overrides it, and waiters re-read it every poll. |
| `FORGE_STALL_MIN` | `20` | `status.sh` flags an active agent as STALLED after this many minutes with no log growth and no commit. |
| `FORGE_TEST_CMD` | `npm test` if `package.json` has a real test script, else `bash tools/test/run.sh --quick` | The test command for `merge_gate.sh`. With no test command it refuses to merge; set it to `true` to merge untested on purpose. |

These are less common:
- `FORGE_MAX_HOLD` (1800 s): the governor's max hold time; 0 means unlimited.
- `FORGE_QUEUE_WARN` (300 s): queue waits longer than this are logged.
- `FORGE_POLL` (2 s): how often the governor polls.
- `FORGE_REPO` (`.`): the repo `status.sh` reads.
- `FORGE_BUDGET`: the cap in USD.
- `FORGE_TEST_STALL`: wraps the merge-gate tests in `watchdog.sh` with this many seconds.
- `FORGE_NO_FETCH=1`: skips the fetch.
- `FORGE_JSON=python`: forces `agents.sh` to use its python3 fallback instead of jq.
- `FORGE_NO_GOVERNOR_WARN=1`: silences the Node tools' "not under governor" note.

## Rules of use

- **Self-test the governor** at setup. With one slot, two 2-second jobs must run one after the other,
  so this takes **at least 4 s** (about 2 s means the governor is not serializing):
  `time (FORGE_SLOTS=1 tools/forge/governor.sh -- sleep 2 & FORGE_SLOTS=1 tools/forge/governor.sh -- sleep 2; wait)`.
- **Every** headless-browser job goes through the governor, and slow tests also go through the watchdog:
  `tools/forge/governor.sh -- tools/forge/watchdog.sh .forge/logs/ch3.log 90 -- node tools/test/e2e.js --chapter 3`.
  Use `--prio` for user-reported bugs only.
- Register every launch: `tools/forge/agents.sh add ch3 "Build ch3" build/ch3 /path/ch3.log +40m`. Cloud sessions use `-` for the log.
  Optionally record `tools/forge/agents.sh set ch3 worktree ../wt-ch3` and `tools/forge/agents.sh set ch3 chapter 3`.
  After compaction, run `tools/forge/agents.sh list` before anything else.
- Stop an agent with `tools/forge/agents.sh done ch3 stopped drained` (status `stopped`, note "drained").
  `drained` is not a status; terminal statuses are never flagged as stalled.
- The 15-min check-in runs `git fetch -q; tools/forge/status.sh --if-changed`. Post the table only when it prints.
  Exit 3 means the lead investigates the stalled agents now.
- Merge with `tools/forge/merge_gate.sh <branch>` only, then push yourself.
- Release only after this passes on the built zip, using the game's own mode switches (one mode per render × language):
  `tools/forge/governor.sh -- node tools/forge/release_gate.js dist/Game.zip --modes 2d_zh,3d_zh,2d_en,3d_en --settings-key game_settings --settings '2d_zh={"render3d":false,"lang":"zh"}' --settings '3d_zh={"render3d":true,"lang":"zh"}' … --query 3d_zh=lite`.
  Look at the screenshots, then send the zip and its path.
- **Hosted builds:** after deploying, run the same gate against the live URL:
  `tools/forge/governor.sh -- node tools/forge/release_gate.js --url https://host/game/index.html --modes 2d,3d --settings-key game_settings --settings '2d={"render3d":false}' --settings '3d={"render3d":true}'`.
  Same-origin requests are allowed; a CDN or analytics call to another origin fails the gate unless `--allow-net`.

Exit codes: 0 means ok.

| Tool | Non-zero exit codes |
|---|---|
| `governor.sh` | the command's own exit status; 124 when killed at max hold |
| `watchdog.sh` | 125 when it kills a stalled command |
| `status.sh` | 3 when an agent is stalled |
| `merge_gate.sh` | 1 tests failed (rolled back), 2 conflict, 3 cannot merge, 4 dirty tree, 5 no test command, 6 no such ref |
| `release_gate.js`, `shoot.js` | 1 errors, 2 usage problem |

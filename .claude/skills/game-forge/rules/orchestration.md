# Orchestration rules: run many agents without the user babysitting

These rules exist because of Shorelight:
- ~30 workers on 4 CPUs (load 19–26);
- tests ran 2–3× slower;
- jobs starved in the queue for 15–54 min;
- 40+ commit nags and 27+ "WIP snapshot" commits;
- cloud sessions lost their work by not pushing;
- one team blocked ~40 min waiting for a "yes";
- the user had to ask "is it stuck?" or "are we using the machine?" about 10 times.

## Resources
- **Probe first.** At setup, record `nproc`, RAM, GPU (headless is usually software WebGL, ~2 fps for 3D), Playwright, fonts and free disk space in `docs/forge/env.md`.
- **Pace mode** comes from requirements (default **balanced**):

  | Mode | Local agents | Cloud sessions |
  |---|---|---|
  | balanced | up to the governor limit | only for heavy 3D asset teams and the QA walkthrough wave |
  | max-speed | up to the governor limit | anything that would wait |
  | frugal | mostly serial | none unless needed |
- **Browsers only through `tools/forge/governor.sh -- <cmd>`.** Slots ≈ nproc − 1. Use `--prio` for user-reported bugs.
- **Target load** ≈ cores − 0.5.
  - If load is below target and the backlog isn't empty, start the next work package without asking.
  - Backfill CPU-light work (translation, proofreading, docs) into idle capacity.

## Isolation
- One **git worktree or branch per local agent**. Cloud sessions use their own branch.
- Each brief names an **exclusive file namespace**, including names for new files. Shared helpers are created by the lead *before* fan-out. In Shorelight, two QA branches both created `sidequests/lib.js`.
- Agents commit their own files on their own branch. The lead merges green branches with `merge_gate.sh`.
- Logs and artifacts go to the scratchpad or `.forge/`, never the repo. Add `*.log` to .gitignore (durable records live in `docs/forge/`, lock files in `.forge/`).
- No blanket `git add -A` WIP snapshots of the shared tree: they captured half-finished agent work in Shorelight. Risky features ship behind a default-off flag until verified.

## Registry, status, watchdog
- Every launch: `tools/forge/agents.sh add <id> <task> <branch> <log> <eta>`. Runtime state (registry, locks, queue log, spend) lives in the main checkout's gitignored `.forge/`.
- Each check-in also commits a snapshot, `agents.sh list > docs/forge/AGENTS.md`, so the registry survives a context reset or a new container. After a reset, **read the registry or the snapshot**, not transcripts.
- **Check-in every 15 min** via `send_later`. Each check-in:
  1. run `status.sh`;
  2. act on stalls;
  3. merge finished branches;
  4. commit and push;
  5. post one table (`status_table.md`);
  6. re-arm.

  Stay silent when nothing changed.
- **Watchdog.**
  - Wrap tests in `watchdog.sh` (90 s without output = fail).
  - `status.sh` flags agents with no log growth or commits for 20 min. The lead investigates and fixes **before the user could notice**: kill the hung child, re-brief, or take over.
- Follow-ups for files another agent owns go in `docs/forge/followups.md` and are applied when it hands off.

## Cloud sessions
- Launch with the full brief (`briefs/cloud_session.md`), in a permission mode that never blocks on approval. Never use plan mode.
- The brief says the lead may pause or resume the session; prefer finishing over pausing.
- The session pushes a WIP commit every 10 min and after each asset, and posts status in commit messages. The lead reads `git log`, not chat.
- Every session has a time budget, a stop rule and a "ship without you" deadline.
- **Merge early**, then send "merged, please stop, don't push further". Before a release, **freeze**: drain all agents, then merge, then build.

## Briefs
Every brief comes from `briefs/` and has:
- goal; owned files; definition of done; time budget and stop rule;
- re-run scope (only failures);
- "report engine or shared bugs, don't patch them";
- "only claim APIs you can show by file:line".

The lead greps for every API an agent reports before relying on it. One Shorelight agent invented `G.Tiles.warm`.

## Engine ownership
One engine owner: the lead or a designated agent. Builders report engine bugs in a fixed format and never patch around them. The owner fixes each bug once and broadcasts "workarounds optional".

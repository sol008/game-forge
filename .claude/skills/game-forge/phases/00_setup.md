# Phase 0: Setup

## Purpose

Turn the intake answers into a locked, committed `docs/REQUIREMENTS.md`, a private repo that pushes, and the orchestration machinery: governor, registry, watchdog and check-in loop. All of it exists **before** the first agent is launched.

## Inputs

- Intake done (`intake.md`). G0 and G0b answered: required fields (languages, render mode, platform), budget/cap answer, private repo `owner/name`.
- A draft `docs/REQUIREMENTS.md` (from `requirements_template.md`), not yet committed.
- The game-forge checkout (`$FORGE`) with `forge-tools/`.

## Steps

All steps: **lead only**, serial. No agents yet: nothing exists for them to work on safely.

1. **Inspect the target repo** before writing to it.
   - `git ls-remote https://github.com/<owner>/<name>`; confirm it is **private** (`gh api repos/<owner>/<name> --jq .private`).
   - Public or scratch repo: stop and ask for a private one. This is part of G0.
   - Not empty (README, licence): clone and build on top. Merge; **never force-push**.
   - Copy the `owner/name` from tool output, never retype it.
2. **Working directory.** Clone to a neutral path, e.g. `~/game`, not a title-based folder. Title and slug live only in `CONFIG` and `REQUIREMENTS.md`, so a rename never moves files.
3. **Probe the environment** and write `docs/forge/env.md`:
   - `nproc`, `free -g`, disk; GPU present? (none means SwiftShader: no video or performance claims, and 3D tests need a lite mode);
   - `node -v`, Playwright browsers path, `python3 -c 'import fontTools'`;
   - CJK or other script fonts installed? Font source reachable (Google Fonts or a vendored copy)?
   - npm registry reachable (needed only for one-time vendoring such as a 3D library bundle).
   Leave existing files alone; never `git rm` what you did not create.
4. **Lock the requirements.** Add a `## Lock` section to `docs/REQUIREMENTS.md`:
   - locked fields: premise (or "pending G1"), setting and route scope, title pair, slug, cast roster, render mode, languages, platform, chapter count;
   - `lock: v1 <sha256 of the file, 12 chars>`;
   - the **engine reference policy** (similar → may read `sol008/Shorelight`, write fresh; different → clean room, `blueprint/` only) and one line on why;
   - the **priority order** if something must give, and the "ship without you" deadline.
   A locked field changes only through a **change order** (step 9).
5. **Repo skeleton** (commit 1):
   - `.gitignore`: `*.log`, `dist/`, `node_modules/`, `tools/**/out/`, `*.tmp.*`, generated font data if it is rebuilt at package time;
   - `docs/REQUIREMENTS.md`, `docs/forge/env.md`, `docs/forge/cost.md` (the G0b table);
   - empty `docs/forge/followups.md` (deferred fixes keyed by file owner) and `docs/forge/agents.json` (`[]`);
   - a two-line `README.md` (title, "under construction").
   Push. This proves the remote works.
6. **Arm the governor** (`$FORGE/forge-tools/governor.sh`):
   - browser slots = `nproc − 1` (minimum 1); load target = cores − 0.5;
   - priority lane for user-reported bugs; max hold time per job; config re-read on every poll; waits > 5 min reported;
   - self-test: run two dummy jobs with 1 slot and confirm they serialize.
   From now on **no agent launches a browser except through `governor.sh`**. Every brief says so.
7. **Arm the registry and watchdog.**
   - `forge-tools/status.sh` reads `docs/forge/agents.json` (id, task, branch, worktree, log, ETA, started) and prints one table.
   - Watchdog: no log growth or commits for 20 min → alert the lead; a test with no output for 90 s → kill and fail with the last step.
   - Logs and screenshots go to `$SCRATCH/<task>/`, never into the repo.
8. **Arm the check-in loop.** `send_later` every report interval (default 15 min) with the prompt from `status_table.md`:
   check agents and cloud sessions → post **one** table (state, ETA, load, spend, blockers) → commit `docs/forge/*` → push → re-arm. Silent when nothing changed.
9. **Change orders** (rule for the rest of the build). When the user changes a locked field after fan-out:
   1. list running agents (an interrupt may have killed some) and stop the affected ones;
   2. bump `lock: v2`, write the delta in `REQUIREMENTS.md § Changes`;
   3. send **one** standard change brief to every surviving agent; propagate cuts everywhere without asking;
   4. report the cost of the change in the next status table.
   Ambiguous additions (new cast, new reference photos) default to **additive**; confirm in the same reply that discloses it.
10. **Worktree convention.** One worktree per agent: `git worktree add ../wt/<task> -b <area>/<task>`. Agents commit only their own files on their own branch; the lead merges green branches with `forge-tools/merge_gate.sh`. No blanket `git add -A`, no "WIP snapshot" commits on the lead's tree.

## Outputs

- `docs/REQUIREMENTS.md` (with `## Lock`, reference policy, priority order).
- `docs/forge/env.md`, `docs/forge/cost.md`, `docs/forge/agents.json`, `docs/forge/followups.md`.
- `.gitignore`, `README.md`.
- A running `send_later` check-in; governor config in `$SCRATCH/forge/`.

## Exit gate

Automated:
- [ ] `git push` to the private remote succeeds; `gh api … --jq .private` is `true`.
- [ ] `REQUIREMENTS.md` lint: no `TBD` in required fields (languages, render mode, platform, repo); `## Lock` present with a hash.
- [ ] `governor.sh` self-test serializes 2 jobs on 1 slot.
- [ ] `status.sh` prints a table (empty registry is fine).
- [ ] The check-in trigger exists (`list_triggers`).

Human: **G0** (hard block: requirements and repo) and **G0b** (cap question; default no cap). Both happen during intake; this phase never asks anything new.

## Pitfalls from Shorelight

- **Built in a public scratch repo for 2 days.** The game sat in `testProject`, public, until a migration with `git subtree split`. Start in a dedicated private repo.
- **`create_repository` returned 403.** Claude cannot create repos; the user had to, mid-build, after a 16-min wait. Ask at intake.
- **Target repo was not empty** (a README). Merge onto it; no force push.
- **Folder renamed 3 times in 12 minutes** (`qiandeng` → `biandeng` → `lantern-of-the-far-shore` → `shorelight`) and ~20 min of naming Q&A. Neutral working directory; title in config only.
- **Setting changed after 15 agents launched** ("travel through all major places in Taiwan"). The interrupt also killed agents; 20 were relaunched. Lock first, and treat a late change as a change order.
- **The 2D→3D pivot at hour 2** threw away the 2D art pipeline (78 sprites, 112 objects, tiles became stand-ins). Render mode is a required intake field.
- **~30 workers on 4 CPUs** (load 19–26): every test ran 2–3× slower. The governor exists from minute 15, not hour 4.
- **Monthly spend limit hit twice** (07:00, 07:35); work went serial. Budget and forecast at G0b; checkpoint at 90%.
- **40+ stop-hook commit nags and 27+ "WIP snapshot" commits** from agents sharing one tree. Worktrees from the first launch.
- **The lead `git rm`'d unrelated files** in the target repo, then had to revert. Leave what you didn't create.
- **Misspelled `sol08/Shorelight` twice.** Copy identifiers from tool output.
- **After a context compaction** the lead grepped the session transcript to map agent IDs to chapters. The registry and `followups.md` are the memory: re-read them after any reset.

## Time/cost estimate

- 15 min of lead time after intake (intake itself: 10–20 min of the user's time across rounds).
- Cost: lead only; no agents, no cloud sessions.

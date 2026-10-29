# Phase 0: Setup

## Purpose

Turn the intake answers into a locked, committed `docs/REQUIREMENTS.md`, a private repo that pushes, and the orchestration machinery: governor, registry, watchdog and check-in loop. All of it exists **before** the first agent is launched.

## Inputs

- Intake done (`intake.md`). G0 and G0b answered: required fields (languages, render mode, platform), budget/cap answer, private repo `owner/name`.
- A draft `docs/REQUIREMENTS.md` (from `requirements_template.md`), not yet committed.
- This skill's folder (`$FORGE`, see SKILL.md) with `forge-tools/`. Step 5 copies it into the game repo; after that, everyone calls `tools/forge/<tool>`.

## Steps

All steps: **lead only**, serial. No agents yet: nothing exists for them to work on safely.

1. **Inspect the target repo** before writing to it.
   - `git ls-remote https://github.com/<owner>/<name>`; confirm it is **private** (`gh api repos/<owner>/<name> --jq .private`).
   - Public or scratch repo: stop and ask for a private one. This is part of G0.
   - Not empty (README, licence): clone and build on top. Merge; **never force-push**.
   - Copy the `owner/name` from tool output, never retype it.
2. **Working directory.** Clone to a neutral path, e.g. `~/game`, not a title-based folder. Title and slug live only in `CONFIG` and `REQUIREMENTS.md`, so a rename never moves files.
3. **Probe the environment** and write `docs/forge/env.md`:
   - **paths**: `FORGE=<this skill's folder>` (lead only); `SCRATCH=<scratchpad dir>/<slug>`; `FORGE_DIR` left at the tools' default (the main checkout's `.forge/`, gitignored, runtime only). Every later `$FORGE`/`$SCRATCH` means these values;
   - `nproc`, `free -g`, disk; GPU present? (none means SwiftShader: no video or performance claims, and 3D tests need a lite mode);
   - `node -v`, Playwright browsers path, `python3 -c 'import fontTools'`;
   - CJK or other script fonts installed? Font source reachable (Google Fonts or a vendored copy)?
   - npm registry reachable (needed only for one-time vendoring such as a 3D library bundle);
   - `gh repo view sol008/Shorelight` (reference reachable?) and push access to `sol008/game-forge`;
   - **tool availability**, one line each, with the fallback in use:

     | Tool | Missing → fallback |
     |---|---|
     | AskUserQuestion | same lettered options in plain text (`intake.md`) |
     | `send_later` / `list_triggers` | `/loop 15m` with the check-in prompt |
     | `create_session` / `get_session` | pace `frugal`: no cloud; heavy work runs local and serial |
     | Shorelight reachable | no → `similar, reference unavailable → clean room` |
     | `sol008/game-forge` push | no → lessons go to `docs/forge/lessons_for_forge.md` |
   Leave existing files alone; never `git rm` what you did not create.
4. **Lock the requirements.** Add a `## Lock` section to `docs/REQUIREMENTS.md`:
   - locked fields: premise (or "pending G1"), setting and route scope, title pair, slug, cast roster, render mode, languages, platform, chapter count;
   - `lock: v1 <12 chars>`: the sha256 of `REQUIREMENTS.md` with the `lock:` line removed (`grep -v 'lock: v' docs/REQUIREMENTS.md | sha256sum | cut -c1-12`);
   - the **engine reference policy** (similar → may read `sol008/Shorelight`, write fresh; different → clean room, `blueprint/` only) and one line on why;
   - the **priority order** if something must give, and the "ship without you" deadline (both from intake round 8).
   A locked field changes only through a **change order** (step 9).
5. **Repo skeleton** (commit 1):
   - `.gitignore`: `*.log`, `dist/`, `node_modules/`, `tools/**/out/`, `*.tmp.*`, generated font data if it is rebuilt at package time;
   - **forge tools**: `cp -R "$FORGE/forge-tools/." tools/forge/`; write the forge version into `docs/forge/env.md`: the `version` from `plugin.json` if present, else `sha256sum "$FORGE/SKILL.md" | cut -c1-12`. Cloud child sessions check out only the game repo, so this copy is how they get the tools. Re-copy only as a deliberate commit ("forge tools → <sha>");
   - `docs/REQUIREMENTS.md`, `docs/forge/env.md`, `docs/forge/cost.md` (the G0b table);
   - empty `docs/forge/followups.md` (deferred fixes keyed by file owner) and `docs/forge/AGENTS.md` (a snapshot of `tools/forge/agents.sh list`, re-committed at each check-in). The live registry `.forge/agents.json` is runtime state in `$FORGE_DIR` and is never committed;
   - a two-line `README.md` (title, "under construction").
   Push. This proves the remote works.
6. **Arm the governor** (`tools/forge/governor.sh [--prio] -- <cmd...>`):
   - browser slots = `nproc − 1` (minimum 1; `FORGE_SLOTS` or `--set-slots`); load target = cores − 0.5;
   - priority lane (`--prio`) for user-reported bugs; max hold time per job (`--max-hold`, default 1800 s); config re-read on every poll; waits > 5 min logged to `$FORGE_DIR/queue.log`;
   - self-test: `time (FORGE_SLOTS=1 tools/forge/governor.sh -- sleep 2 & FORGE_SLOTS=1 tools/forge/governor.sh -- sleep 2; wait)` takes ≥ 4 s.
   From now on **no agent launches a browser except through `tools/forge/governor.sh`**. Every brief says so.
7. **Arm the registry and watchdog.**
   - `tools/forge/agents.sh add <id> <task> <branch> <log> [eta]` at every launch; put the worktree and chapter in `agents.sh set <id> note "<worktree> chN"`. Stopping an agent: `agents.sh done <id> stopped` with note "drained".
   - `tools/forge/status.sh` prints one table from the registry (exit 3 = an agent is stalled).
   - Watchdog: no log growth or commits for 20 min → alert the lead (`status.sh`); a test with no output for 90 s → `tools/forge/watchdog.sh <log> 90 -- <cmd>` kills it and prints the last step.
   - Logs and screenshots go to `$SCRATCH/<task>/`, never into the repo.
8. **Arm the check-in loop.** `send_later` every report interval (default 15 min) with the prompt from `status_table.md`; no `send_later` → `/loop 15m` with the same prompt:
   check agents and cloud sessions → post **one** table (state, ETA, load, spend, blockers) → snapshot `docs/forge/AGENTS.md`, commit `docs/forge/*` → push → re-arm. Silent when nothing changed.
9. **Change orders** (rule for the rest of the build). When the user changes a locked field after fan-out:
   1. list running agents (an interrupt may have killed some) and stop the affected ones;
   2. bump `lock: v2`, write the delta in `REQUIREMENTS.md § Changes`;
   3. send **one** standard change brief to every surviving agent; propagate cuts everywhere without asking;
   4. report the cost of the change in the next status table.
   Ambiguous additions (new cast, new reference photos) default to **additive**; confirm in the same reply that discloses it.
10. **Worktree convention.** One worktree per agent: `git worktree add ../wt/<task> -b <area>/<task>`. Agents commit only their own files on their own branch; the lead merges green branches with `tools/forge/merge_gate.sh`. No blanket `git add -A`, no "WIP snapshot" commits on the lead's tree.

## Outputs

- `docs/REQUIREMENTS.md` (with `## Lock`, reference policy, priority order).
- `docs/forge/env.md` (FORGE, SCRATCH, forge sha, probes, tool availability and fallbacks), `docs/forge/cost.md`, `docs/forge/followups.md`, `docs/forge/AGENTS.md`.
- `tools/forge/` (copy of `forge-tools/`).
- `.gitignore`, `README.md`.
- A running check-in (`send_later` or `/loop 15m`); governor config and the live registry in `$FORGE_DIR`.

## Exit gate

Automated:
- [ ] `git push` to the private remote succeeds; `gh api … --jq .private` is `true`.
- [ ] `REQUIREMENTS.md` lint: no `TBD` in required fields (languages, render mode, platform, repo); `## Lock` present with a hash.
- [ ] `tools/forge/` exists and `env.md` records the forge sha, `FORGE`, `SCRATCH` and the tool-availability table.
- [ ] `tools/forge/governor.sh` self-test serializes 2 jobs on 1 slot (≥ 4 s).
- [ ] `tools/forge/status.sh` prints a table (empty registry is fine).
- [ ] The check-in exists (`list_triggers`, or the `/loop` is running).

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

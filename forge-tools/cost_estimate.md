# Cost estimate and spend reporting

The G0b gate: estimate cost **before** fan-out, ask once whether the user wants a cap, then
report spend in every status table. Shorelight had no budget plan. It hit the monthly spend
limit twice (07:00 and 07:35), the user had to raise billing mid-build, and work fell back to
one task at a time.

## 1. Data points from Shorelight (measured, not guessed)

| What | Observed | Source |
|---|---|---|
| One cloud session | **about $5–40** | lead's own note during the build |
| 3D characters cloud team (71 rigged figures, the heaviest team) | **about $35** | timeline, 09:01 |
| Cloud 3D fan-out | 11 teams; 10 merged within ~50 min of each other | timeline, 09:25–10:14 |
| Side-quest QA walkthrough, 4 cloud sessions | **47, 61, 65 and ~108 min** (ch3-5, ch0-2, ch6-8, ch9-11) | timeline, 22:12–00:04 |
| Local chapter builders | 11 in parallel; 10 chapters finished in ~1 h once the test queue was fixed | timeline, 07:52–08:48 |
| Whole build | ~13 h to v1.0, 437 commits, ~150k lines of game JS | §0 of PLAN.md |

There is **no measured $/hour for local subagents** in the record. Section 3 says how to
measure it in the first hour instead of guessing.

## 2. Worksheet (fill one row per phase at G0b)

`C` is the cost of one cloud session: use **$35–40** for heavy 3D or long QA sessions and
**$5–20** for light, short ones. `L` is the measured cost of one local agent-hour (section 3).
The agent counts and hours come from PLAN.md §5; scale them to the game's scope (a 2-chapter
mini dry run is roughly 1/5 of the chapter work).

| # | Phase | Local agent-hours | Cloud sessions × C | Estimate (low – high) |
|---|---|---|---|---|
| 0 | Setup | 1 lead × 0.25 h | – | 0.25·L |
| 1 | Pre-production | (1 + 4–6 writers) × 1.5 h ≈ 8–11 | – | 8L – 11L |
| 2 | Engine + conformance | 1 × 1 h | – | 1L |
| 3 | Art and design | 2–4 × 2.5 h ≈ 5–10 | – | 5L – 10L |
| 4 | Chapter build | chapters × 1–2 h (11 ch ≈ 11–22) | – | 11L – 22L |
| 5 | 3D assets (if 3D) | lead merges ≈ 1–2 | teams × C (11 × $5–40 = **$55–440**; budget heavy teams at ~$35) | 1L + $55 – 2L + $440 |
| 6 | Localization | ~6 × 0.5 h ≈ 3 | – | 3L |
| 7 | Balance + economy | 2 × (continuous, ~4–6 h) ≈ 8–12 | – | 8L – 12L |
| 8 | Pre-ship QA wave | 4–6 × 2 h ≈ 8–12 | 4 walkthroughs × C (47–108 min each: **$20–160**) | 8L + $20 – 12L + $160 |
| 9 | Polish | 3–4 × 1.5 h ≈ 5–6 | – | 5L – 6L |
| 10 | Docs + guide | 3 × 1.5 h ≈ 4.5 | – | 4.5L |
| 11 | Freeze + release | 1 × 0.25 h | – | 0.25L |
| 12 | Playtest loop, per round | helpers 4–8 × 1–2 h | 0–2 overflow × C | per round: 4L + $0 – 16L + $80 |
| | **Total to first zip** (phases 0–11) | **≈ 55–84 agent-hours** | **≈ 15 sessions: $75–600** | **55L + $75 – 84L + $600** |

Add **25% contingency** for relaunches and rework. Shorelight relaunched agents after late
requirement changes. Phase 1's requirements gate is meant to remove that cost, but it is not
yet proven.

## 3. Calibrating L (do this in phase 0–1, not later)

1. Record spend before launching the phase-1 writers: `echo "$(date +%FT%R) \$X.XX start-of-phase-1 (measured)" >> $FORGE_DIR/spend.txt`.
   Use whatever the account exposes: `/cost` in Claude Code for API-billed sessions, or the
   usage page figure the user gives at G0.
2. After about 30–60 min, record it again and divide the delta by the agent-hours in that window. That is `L`.
3. Re-run the worksheet with the measured `L`. If the new total moves by more than 30%,
   post one line about it in the next status table. That line is disclosure, not a question.

If spend cannot be read at all, write estimates instead: `… $X.XX (estimate: N agent-h × L + M cloud × C)`.
Every line says whether it is `measured` or `estimate`.

## 4. Reporting spend

- `$FORGE_DIR/spend.txt`: append-only, one line per update, newest last. `status.sh` shows the
  first `$amount` on the last line. Format:
  `2026-10-29T10:15 $42.10 total (measured; cloud 3D 6/11 merged)`.
- `$FORGE_DIR/budget.txt`: the cap in USD (only if the user set one) or `FORGE_BUDGET`.
  `status.sh` then shows `% of cap` and flags **WARN ≥70%** and **CHECKPOINT ≥90%**.
- Update `spend.txt` at every 15-min check-in while cloud sessions run, and at every phase exit.
- **At 70%:** say so in the status table and stop launching new cloud sessions unless they are on the critical path.
- **At 90%:** checkpoint everything. Every agent commits and pushes, cloud sessions get "merged, stop", and work drops to serial.
  Never let a quota stop land mid-write. Shorelight lost a cloud session's unpushed work that way.
- **Final report** (with the release zip): the total; local agent-hours × `L`; each cloud session
  with its time and cost; the estimate vs the actual per phase; and the biggest overrun with its cause.
  The lessons go into this file.

## 5. G0b question template (send once, right after G0)

> **Cost estimate (G0b).** For *{title}*, {scope: N chapters, 2D/3D, languages}, I estimate:
>
> | Phase group | Estimate |
> |---|---|
> | Pre-production + engine + art | ${a}–${b} |
> | Chapter build + localization + balance | ${c}–${d} |
> | 3D asset teams ({n} cloud sessions) | ${e}–${f} |
> | QA wave + polish + docs + release | ${g}–${h} |
> | **Total to first playable zip (incl. 25% contingency)** | **${lo}–${hi}** |
>
> These figures are based on Shorelight: a cloud session cost about $5–40, the 3D characters
> team about $35, and a QA walkthrough took 47–108 min. My local-agent rate is {measured|assumed}
> at ${L}/agent-hour.
>
> **Do you want a spending cap?** Reply with a letter:
> - **A. No cap** (default). I report spend in every status table.
> - **B. Cap at ${round(hi × 1.2)}**. I warn at 70%; at 90% I checkpoint and go serial.
> - **C. Cap at ${lo}**. Same rules; heavy 3D and QA move to fewer, longer cloud sessions.
> - **D. Frugal mode**. Mostly serial, no cloud overflow. About {k}× the wall-clock time.
> - **E. A different cap: $____**
>
> If I don't hear back, I'll go with A and start now.

Write the answer to `docs/REQUIREMENTS.md` (field: budget cap and quota mode), and write the cap to
`$FORGE_DIR/budget.txt`.

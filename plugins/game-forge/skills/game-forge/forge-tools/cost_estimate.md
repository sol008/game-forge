# Cost estimate and spend reporting

This file is the **canonical source** of the per-phase cost numbers. Phase files quote its rows
(`cost_estimate.md row N` = phase N); when a number changes, change it here first.

The G0b gate: estimate cost **before** fan-out, ask once whether the user wants a cap, then
report spend in every status table. Shorelight had no budget plan. It hit the monthly spend
limit twice (07:00 and 07:35), the user had to raise billing mid-build, and work fell back to
one task at a time.

## 1. Data points from Shorelight (measured, not guessed)

| What | Observed (**measured**) | Source |
|---|---|---|
| One cloud session | **about $5–40** | lead's own note during the build |
| 3D characters cloud team (71 rigged figures, the heaviest team) | **about $35** | timeline, 09:01 |
| Cloud 3D fan-out | 11 teams; 10 merged within ~50 min of each other | timeline, 09:25–10:14 |
| Side-quest QA walkthrough, 4 cloud sessions | **47, 61, 65 and ~108 min** (ch3-5, ch0-2, ch6-8, ch9-11) | timeline, 22:12–00:04 |
| Local chapter builders | 11 in parallel; 10 chapters finished in ~1 h once the test queue was fixed | timeline, 07:52–08:48 |
| Whole build | ~13 h to v1.0, 437 commits, ~150k lines of game JS; about 2 days including the playtest loop | §0 of PLAN.md |

Everything else in this file is an **estimate** derived from those points. There is **no measured
$/hour for local subagents** in the record; section 3 says how to measure it 30 min in.

## 2. Per-phase numbers (canonical)

Two sizes:
- **Full**: about 11 chapters, Shorelight scale. About **13–16 h** of wall clock to the first playable zip.
- **Mini**: 2 chapters. About **4–8 h** of wall clock in total.

Scale between them by chapter count. Local work and cloud spend are **always quoted separately**:
- **agent-h** = local agent-hours. Their dollar cost is `agent-h × L` (section 3).
- **cloud $** = cloud sessions × `C`, where `C` ≈ **$35–40** for heavy 3D or long QA sessions and **$5–20** for light, short ones (measured range $5–40).

| # | Phase | Full: agent-h | Full: cloud $ | Mini: agent-h | Mini: cloud $ | Basis |
|---|---|---|---|---|---|---|
| 0 | Setup | 0.25 | – | 0.25 | – | lead only |
| 1 | Pre-production | 8–11 | – | 2–4 | – | (lead + 4–6 writers) × 1.5 h; mini: 1–2 writers |
| 2 | Engine + conformance | 1 | – | 1 | – | lead only; same engine at either size |
| 3 | Art and design | 5–10, + ~1 per 2D art kit | – | 2–4, + ~1 per 2D art kit | – | 2–4 design agents × ~2.5 h; one agent per art kit (2D) |
| 4 | Chapter build | 11–22 | – (overflow: contingency) | 2–4 | – | 1–2 agent-h per chapter |
| 5 | 3D assets (3D only) | 1–2 | **$55–440** | 0.5–1 | **$10–160** | full: 11 teams × $5–40 (characters ~$35, measured); mini: 2–4 teams. 2D: art-kit smoke + lineup, ~0.5 agent-h, $0 |
| 6 | Localization | 3 | – | 0.5–1 | – | ~6 agents × 0.5 h; 0 when there is only one language |
| 7 | Balance + economy (or puzzle solver) | 8–12 | – | 2–3 | – | 2 background agents for the whole build |
| 8 | Pre-ship QA wave | 8–12 | **$20–160** | 2–3 | **$0–40** | 4–6 local × ~2 h; full: 4 cloud walkthroughs (47–108 min each, measured); mini: 0–1 |
| 9 | Polish | 5–6 | – (perf overflow: contingency) | 1–2 | – | 3–4 agents × 1.5 h |
| 10 | Docs + guide | 4.5 | – | 1–2 | – | 3 agents × 1.5 h |
| 11 | Freeze + release | 0.25 (+0.25 if hosted) | – | 0.25 (+0.25 if hosted) | – | lead only |
| | **Total to first playable** (phases 0–11) | **≈ 55–85 agent-h** | **≈ $75–600** (2D: $20–160) | **≈ 15–30 agent-h** | **≈ $10–200** (2D: $0–40) | wall clock: full 13–16 h, mini 4–8 h |
| 12 | Playtest loop, per round | 4–16 | $0–80 | 1–3 | $0–40 | helpers 4–8 × 1–2 h (mini 1–3 × 1 h); cloud only for heavy 3D repros |

Add **25% contingency** to both columns for relaunches, rework and optional overflow sessions
(cloud sweep in 8, perf in 9, max-speed overflow in 4). Shorelight relaunched agents after late
requirement changes. Phase 1's requirements gate is meant to remove that cost, but it is not
yet proven.

## 3. Calibrating L (30 min into phase 1)

`L` is the cost of one local agent-hour. Until it is measured, quote local cost as a **range**:
`agent-h × $3–25`. That assumed range comes from the measured cloud data (one session ≈ $5–40
over roughly 50–110 min) and is labelled `assumed`. If local usage is covered by a subscription
rather than billed per token, say so: then `L` is quota, not dollars, and the cap covers cloud $ only.

1. Record spend just before launching the phase-1 writers: `echo "$(date +%FT%R) \$X.XX start-of-phase-1 (measured)" >> $FORGE_DIR/spend.txt`.
   Use whatever the account exposes: `/cost` in Claude Code for API-billed sessions, or the
   usage page figure the user gives at G0.
2. **30 min in**, record it again and divide the delta by the agent-hours in that window. That is `L`.
3. Re-run the totals with the measured `L` (cloud $ + agent-h × L) and write them to
   `docs/forge/cost.md`. Post one line in the next status table with the narrowed total and,
   if a cap is set, the cap as a % of it. That line is disclosure, not a question.

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

Fill it from the Full or Mini column (scaled by chapter count), plus 25% contingency.
With no AskUserQuestion tool, send the same lettered options as plain text.

> **Cost estimate (G0b).** For *{title}*, {scope: N chapters, 2D/3D, languages}, about {wall} h to the first playable:
>
> | Phase group | Cloud $ | Local agent-hours |
> |---|---|---|
> | Pre-production + engine + art (0–3) | – | {h1} |
> | Chapter build + localization + balance (4, 6, 7) | – | {h2} |
> | 3D asset teams (5; {n} cloud sessions) | ${c5lo}–${c5hi} | {h3} |
> | QA wave + polish + docs + release (8–11) | ${c8lo}–${c8hi} | {h4} |
> | **Total to first playable (incl. 25% contingency)** | **${clo}–${chi}** | **{hlo}–{hhi} h** |
>
> **Total ≈ cloud $ + agent-hours × L = ${lo}–${hi}.** L (my cost per local agent-hour) is
> {assumed at $3–25 until I measure it 30 min into phase 1 | measured at $L}. I'll post the
> narrowed total in the status table once it is measured.
> Basis (Shorelight, measured): a cloud session cost about $5–40, the 3D characters team about
> $35, and a QA walkthrough took 47–108 min.
>
> **Do you want a spending cap (cloud $ + local agent-hours × L)?** Reply with a letter:
> - **A. No cap** (default). I report spend in every status table.
> - **B. Cap at ${round(hi × 1.2)}**. I warn at 70%; at 90% I checkpoint and go serial.
> - **C. Cap at an amount you name: $____** (a tight cap such as ${lo} works too). Same rules;
>   heavy 3D and QA move to fewer, longer cloud sessions.
> - **D. Frugal mode**. Mostly serial, no cloud sessions. About {k}× the wall-clock time.
>
> If I don't hear back, I'll go with A and start now.

Write the answer to `docs/REQUIREMENTS.md` (field: budget cap and quota mode), the table to
`docs/forge/cost.md`, and the cap to `$FORGE_DIR/budget.txt`. Re-check the cap against the
total once `L` is measured.

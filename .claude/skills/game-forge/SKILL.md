---
name: game-forge
description: Build a complete, shippable video game end to end (story, engine, levels/chapters, art, optional 3D, localization, balance, QA, strategy guide, packaged zip) from a requirements intake, using parallel agents and cloud sessions with minimal human handholding. Use when the user asks to build, make or create a game, or to continue or fix a game built with game-forge.
---

# game-forge

This skill builds a game the way 《彼岸燈》 Shorelight was built (12 chapters, 175 maps, 3D, zh+en, ~150k lines in about 2 days), minus the ~45 interventions that could have been avoided. The playbook is distilled from that build. The full rationale is in `docs/PLAN.md`, and the evidence is in `research/`.

## Non-negotiables

1. **Intake first** (`intake.md`). Lock the requirements before *any* fan-out: premise, setting/route, title, cast roster, **render mode**, **languages**, **platform**. Write the result to `docs/REQUIREMENTS.md` in the game repo.
2. **Stop for the human only at gates**:
   - G0 intake;
   - G0b cost estimate;
   - G1 pitch, only if no premise was given;
   - G2 design gallery;
   - G3 taste review, which never blocks work;
   - G4 playtest;
   - G5 ship.

   Everything else: **decide and disclose** in the next status table. Never ask "should I continue?".
3. **Every bug class becomes a check** (`rules/testing.md`, `rules/discoverability.md`). Tests encode the *spec*, never current behaviour.
4. **Orchestrate within resources** (`rules/orchestration.md`):
   - governor for browsers and CPU;
   - one worktree or branch per agent;
   - an agent registry;
   - a 15-min status table;
   - a watchdog;
   - cloud overflow.
5. **Money is visible** (`rules/budget.md`): estimate before building, ask whether the user wants a cap, report spend in every table.
6. **Communicate like `rules/communication.md`**:
   - one table per check-in;
   - zips at milestones;
   - answers in the user's language;
   - spatial answers from annotated maps.

## Phases (each file has steps, briefs, exit gate, pitfalls)

| # | File | Gate to leave |
|---|---|---|
| 0 | `phases/00_setup.md` | Repo pushable, forge-tools working, check-in armed, G0 + G0b done |
| 1 | `phases/01_preproduction.md` | G1 (if needed); screenplays frozen with a hash; lore lint clean |
| 2 | `phases/02_engine.md` | `blueprint/conformance_suite.md` green **before content fan-out** |
| 3 | `phases/03_art_design.md` | G2 picks; in-game assets baked from the approved source |
| 4 | `phases/04_chapter_build.md` | Each chapter: test PASS in default render mode, validator 0 errors |
| 5 | `phases/05_3d_assets.md` (if 3D) | Contract smoke test first; lineups match references; merge-tree clean |
| 6 | `phases/06_localization.md` | Coverage ≥99.9%; every line fits its box |
| 7 | `phases/07_balance.md` (from 2 chapters on) | Win-rate band per boss; chain test unassisted |
| 8 | `phases/08_qa_wave.md` (mandatory) | Walkthroughs PASS; 0 unobtainable or unreachable; every missable warned |
| 9 | `phases/09_polish.md` | Budgets met; previews sent (G3) |
| 10 | `phases/10_docs.md` | Guide built (every map annotated, minigames explained); VERIFICATION.md |
| 11 | `phases/11_release.md` | Release gate green; zip sent |
| 12 | `phases/12_playtest.md` | Each bug has a regression check; lessons committed to game-forge |

Milestone zips go out at first playable, after the QA wave, and at release.

## Engine policy

No code template. Each game writes its engine fresh from `blueprint/`. At intake, rate the similarity to Shorelight (`sol008/Shorelight`):
- **Similar** (e.g. a story RPG): agents may **read** the matching Shorelight module as reference, then write fresh code.
- **Different**: **clean room**. Use `blueprint/` only, and never open Shorelight's code.

Record the decision and the reason in `docs/REQUIREMENTS.md`.

## Files

- `intake.md`: multiple-choice intake script.
- `requirements_template.md`: the template it fills.
- `phases/`: 13 phase playbooks.
- `briefs/`: agent and cloud-session brief templates.
- `rules/`: testing, discoverability, orchestration, budget, communication.
- `lessons.md`: the Shorelight incident list.
- `status_table.md`: check-in format.
- `../../../blueprint/`: engine and QA-tool design.
- `../../../forge-tools/`: governor, agents, status, watchdog, merge/release gates, screenshots, cost estimate.

## Self-improvement

After each game, and after any playtest fix whose lesson is general, **commit the new rule or lesson directly to `sol008/game-forge` main**: lessons.md, the relevant rules/ or phases/ file, or blueprint/. Keep game-specific details out.

# game-forge

A Claude Code skill, an engine blueprint and orchestration tools for building a complete game end to end (story → engine → chapters → art/3D → localization → balance → QA → strategy guide → packaged zip) from a multiple-choice requirements intake, with minimal human handholding.

Distilled from building 《彼岸燈》 Shorelight (`sol008/Shorelight`): 12 chapters, 175 maps, 3D, Traditional Chinese + English: ~13 h to v1.0, about 2 days including the playtest loop.

Expected wall clock to the first playable zip: a full-size game ~13–16 h; a mini game (2 chapters) ~4–8 h.

## Use it

1. Create an **empty private repo** for the new game, and give Claude access to it.
2. Start a Claude Code session with **this repo + the new game's repo**.
3. Say: *"Build a game with game-forge."*
4. The skill runs the multiple-choice intake, estimates the cost, then builds.

It stops for you only at the gates:
- intake;
- cost cap;
- story pitch (only if you gave no premise);
- design gallery;
- taste previews (these don't block work);
- playtest;
- ship.

Status tables every 15 min; a playable zip at each milestone.

## Layout

| Path | What |
|---|---|
| `.claude/skills/game-forge/SKILL.md` | Entry point: non-negotiables, phases, gates |
| `.claude/skills/game-forge/intake.md`, `requirements_template.md` | The G0 intake and the requirements file it writes |
| `.claude/skills/game-forge/phases/` | 13 phase playbooks (00 setup … 12 playtest) |
| `.claude/skills/game-forge/briefs/` | Agent and cloud-session brief templates |
| `.claude/skills/game-forge/rules/` | testing, discoverability, orchestration, budget, communication |
| `.claude/skills/game-forge/lessons.md` | Incident → rule list; grows after every game |
| `blueprint/` | Engine and QA-tool design (no code template: each game writes fresh code) |
| `forge-tools/` | governor, agent registry, status, watchdog, merge gate, `release_gate.js`, screenshot harness, cost estimate. Copied into each game repo as `tools/forge/` at setup |
| `docs/PLAN.md` | The approved plan and every decision behind it |
| `research/` | Evidence from the Shorelight build (timeline mining, codebase survey) |

## Self-improvement
After each game, and after playtest fixes with a general lesson, the forge commits the new rules straight to `main`. Without push access, it writes them to `docs/forge/lessons_for_forge.md` in the game repo and lists them in the final report.

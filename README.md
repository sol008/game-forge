# game-forge

A Claude Code skill, an engine blueprint and orchestration tools for building a complete game end to end (story → engine → chapters → art/3D → localization → balance → QA → strategy guide → packaged zip) from a multiple-choice requirements intake, with minimal human handholding.

Distilled from building 《彼岸燈》 Shorelight (`sol008/Shorelight`): 12 chapters, 175 maps, 3D, Traditional Chinese + English: ~13 h to v1.0, about 2 days including the playtest loop.

Expected wall clock to the first playable zip: a full-size game ~13–16 h; a mini game (2 chapters) ~4–8 h.

## Install (pick one)

| Where you work | How | Notes |
|---|---|---|
| **Claude Code on the web / cloud sessions** (and CLI, via sync) | Upload the skill zip to your **claude.ai account skills**: build it with `bash tools/package_skill.sh`, then upload `dist/game-forge-<ver>.zip` | The documented route that loads in **every** cloud session, whatever repo it starts in |
| **Terminal (CLI)** | `/plugin install game-forge --marketplace sol008/game-forge` (or `/plugin marketplace add sol008/game-forge`, then `/plugin install game-forge@sol008-tools`) | Private repo: needs `gh auth login` + `gh auth setup-git`. Skill runs as `/game-forge:game-forge` |
| **A session with this repo attached** | Nothing: `.claude/skills/game-forge` is a link to the plugin's skill folder | Handy while developing the forge itself |

Cloud sessions do **not** install plugins from a repo's settings, so use the account upload there.

## Use it

1. Create an **empty private repo** for the new game, and give Claude access to it.
2. Start a Claude Code session on the new game's repo (the skill is available from your account).
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
| `plugins/game-forge/skills/game-forge/` | **The skill, self-contained** (SKILL.md, intake, phases, briefs, rules, lessons, `blueprint/`, `forge-tools/`). `.claude/skills/game-forge` links here |
| `…/SKILL.md` | Entry point: non-negotiables, phases, gates |
| `…/intake.md`, `requirements_template.md` | The G0 intake and the requirements file it writes |
| `…/phases/` | 13 phase playbooks (00 setup … 12 playtest) |
| `…/briefs/` | Agent and cloud-session brief templates |
| `…/rules/` | testing, discoverability, orchestration, budget, communication |
| `…/lessons.md` | Incident → rule list; grows after every game |
| `…/blueprint/` | Engine and QA-tool design (no code template: each game writes fresh code) |
| `…/forge-tools/` | governor, agent registry, status, watchdog, merge gate, `release_gate.js`, screenshot harness, cost estimate. Copied into each game repo as `tools/forge/` at setup |
| `.claude-plugin/marketplace.json`, `plugins/game-forge/.claude-plugin/plugin.json` | Plugin marketplace for CLI installs |
| `tools/package_skill.sh` | Builds the account-upload zip |
| `docs/PLAN.md` | The approved plan and every decision behind it |
| `research/` | Evidence from the Shorelight build (timeline mining, codebase survey) |

## Self-improvement
After each game, and after playtest fixes with a general lesson, the forge commits the new rules straight to `main`. Without push access, it writes them to `docs/forge/lessons_for_forge.md` in the game repo and lists them in the final report.

After lessons land on `main`, re-run `tools/package_skill.sh` and re-upload the zip so account sessions pick them up. Plugin users run `/plugin update`.

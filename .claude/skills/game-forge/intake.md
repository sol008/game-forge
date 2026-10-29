# Intake (gate G0): multiple-choice requirements

The user asked: **ask as many questions as needed, in multiple-choice form.** Use the AskUserQuestion tool:
- up to 4 questions per round, each with 2–4 options;
- the recommended option first, labelled "(Recommended)";
- the user can always type "Other".

Run rounds until every **required** field is answered. Fields with defaults (below) are asked only if they matter for this game.

If the user already gave a brief, pre-fill from it. Ask only what is missing or ambiguous, and quote their words back in the option descriptions.

## Round order

1. **Identity and genre**
   - genre;
   - one-line premise, or "pitch me 3" (G1);
   - title known? (zh/en/other);
   - inspiration or quality bar.
2. **Required technical fields (no defaults)**
   - **languages** (original + translations);
   - **render mode** (2D / 3D with 2D fallback / 3D only);
   - **platform** (offline zip for Mac+Chrome / hosted web page / Windows / other);
   - camera and art style if 3D.
3. **Scope**
   - chapter or level count;
   - target play time;
   - endings and their conditions;
   - side-content density;
   - collectibles.
4. **Setting and culture**
   - era and place;
   - route or geography scope;
   - cultural-accuracy bar;
   - sacred or sensitive content policy (default: witnessed only, never a minigame, no melodies imitated).
5. **Cast**
   - party size; pets;
   - design options per party member (default 10);
   - story cast (default 1 design each);
   - reference photos;
   - **roster lock**: "if we add someone, keep or cut overlapping cast?".
6. **Systems**
   - combat model;
   - element system;
   - stat names; currency;
   - difficulty target (default: boss first-try win 86–94% for a careful player at the expected level).
7. **QoL defaults**: confirm or switch off any of these:
   - level-up refill;
   - auto-save;
   - smart auto-battle;
   - 2× speed;
   - point-of-no-return warnings;
   - harvest and interactable markers;
   - photosensitivity setting;
   - Play Stats page.
8. **Process**
   - pace (default **balanced**);
   - report cadence (default **15 min**);
   - zips (default **phase milestones**);
   - taste review (default **non-blocking**);
   - design picks (default **one gallery**).
9. **Repo**: the new game's **empty private repo** (`owner/name`) with Claude access.
   - Claude cannot create repos: the GitHub integration returns 403.
   - Never build in a public or scratch repo.

## After the rounds

1. Write `docs/REQUIREMENTS.md` from `requirements_template.md`, marking every value as **user** or **default**.
2. Rate the similarity to Shorelight and record the engine policy (see SKILL.md).
3. **G0b cost estimate** (`forge-tools/cost_estimate.md`): a table by phase; then one question: "Set a spending cap? (No cap / $X / $Y / custom)". The default is no cap, but spend appears in every status table.
4. Show a one-screen summary, then start phase 0. **Do not ask "shall I begin?"**: the intake answers are the go.

## Defaults when the user skips a question

| Field | Default |
|---|---|
| Premise | Show 3 pitches with title pairs (G1); auto-pick the recommended one after 2 h |
| Design options | 10 per party member, 1 per story NPC |
| Pace | balanced |
| Reports | every 15 min |
| Zips | phase milestones |
| Guide | always: generated, annotated maps, minigames explained |
| Sacred content | witnessed only |
| Cut content | propagate the cut everywhere without asking |

Languages, render mode and platform have **no default**: keep asking until answered.

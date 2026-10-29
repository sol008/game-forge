# Intake (gate G0): multiple-choice requirements

The user asked: **ask as many questions as needed, in multiple-choice form.** Use the AskUserQuestion tool:
- up to 4 questions per round, each with 2–4 options;
- the recommended option first, labelled "(Recommended)";
- the user can always type "Other".

No AskUserQuestion (e.g. a cloud session): ask the same questions in one plain-text message per round, options lettered A–D, recommended first, plus "or type your own". Accept replies like `1A 2C 3: <text>`.

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
   - **hosting target**, only if hosted web page: separate public deploy repo on GitHub Pages (Recommended; you create it, as in round 9; the game repo stays private, only built files are pushed) / Netlify / itch.io, uploaded by you / zip only;
   - camera if 3D.
   More than 4 apply: split the round.
2b. **Presentation and deliverables**
   - **art style**, for 2D and 3D alike (offer 3 styles fitting the genre, e.g. pixel art / painted / cel-shaded);
   - **music style** and signature motif (e.g. chiptune / orchestral / regional folk instruments);
   - **guide language(s)** (original (Recommended) / every shipped language / English only);
   - **puzzle-translation policy**, only with translations (re-author per language (Recommended) / keep + gloss / lead decides per puzzle).
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
   - design picks (default **one gallery**);
   - **pick mode** (ask, auto-pick the recommended designs after 2 h (Recommended) / auto-recommend now);
   - **ship-without-you deadline** and priority order if something must give (default: none; scope gives before quality).
9. **Repo**: the new game's **empty private repo** (`owner/name`) with Claude access.
   - Claude cannot create repos: the GitHub integration returns 403.
   - Never build in a public or scratch repo. (A hosted build's separate deploy repo holds built files only, never source.)

## After the rounds

1. Write `docs/REQUIREMENTS.md` from `requirements_template.md`, marking every value as **user** or **default**.
2. Rate the similarity to Shorelight and record the engine policy (see SKILL.md).
3. **G0b cost estimate** (`$FORGE/forge-tools/cost_estimate.md`; phase 0 copies it to `tools/forge/`): a table by phase. Quote **cloud $** and **local agent-hours** separately; `L` ($ per local agent-hour) is not measured until 30 min into phase 1, so show local cost as a range until then. Then one question: "Set a spending cap on cloud $ + local agent-hours × L? (No cap / $X / $Y / custom)". The default is no cap, but spend appears in every status table, and the cap is re-checked once `L` is measured.
4. Show a one-screen summary, then start phase 0. **Do not ask "shall I begin?"**: the intake answers are the go.

## Defaults when the user skips a question

| Field | Default |
|---|---|
| Premise | Show 3 pitches with title pairs (G1); auto-pick the recommended one after 2 h |
| Design options | 10 per party member, 1 per story NPC |
| Pick mode | ask; auto-pick the recommended designs after 2 h, tagged `[default]` |
| Art style | the recommended option of round 2b |
| Guide language | the original language |
| Puzzle policy | re-author per language |
| Hosting target | zip only |
| Deadline | none; scope gives before quality |
| Pace | balanced |
| Reports | every 15 min |
| Zips | phase milestones |
| Guide | always: generated, annotated maps, minigames explained |
| Sacred content | witnessed only |
| Cut content | propagate the cut everywhere without asking |

Languages, render mode and platform have **no default**: keep asking until answered. A hosted web page with no hosting answer ships as zip only and says so in the summary.

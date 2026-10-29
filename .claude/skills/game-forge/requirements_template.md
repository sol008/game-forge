# {{TITLE}}: requirements

> Written by the intake (G0). Every value is tagged `[user]` or `[default]`.
> Change this file only through the user. A change after fan-out is a **scope change**: list its impact in the next status table.

## Identity
- Title (original / English): `{{title_orig}}` / `{{title_en}}`
- Repo: `{{owner/name}}` (private, Claude has push access)
- Slug (folder, save-key prefix): `{{slug}}`. It never changes after setup.

## Genre and premise
- Genre:
- Premise / logline: (or `G1: 3 pitches`)
- Themes and tone:
- Inspirations / quality bar ("better than …"):
- Content limits:

## Required technical choices
- Languages: original `{{lang}}`; translations `{{langs}}`; puzzle-translation policy
- Render mode: `2D | 3D + 2D fallback | 3D only`; camera; art style; resolution
- Platform: `offline zip (Mac + Chrome) | hosted web | Windows | …`; launcher

## Setting
- Era and place:
- Route / geography scope:
- Cultural-accuracy bar; sources; respect guide:
- Sacred content: `witnessed only` [default]

## Cast
- Party (size, roles):
- Pets:
- Story cast:
- Design options: party `10` / story NPCs `1` [default]
- Reference images folder:
- Roster lock rule:

## Scope
- Chapters/levels:
- Target play time (main / with side content):
- Endings and conditions (e.g. collectible threshold):
- Side content density; collectibles:

## Systems
- Combat model; element system; stat names; currency; level cap
- Difficulty target: boss first-try win `86–94%` at the expected level [default]
- Economy target: a normal player affords the expected gear at each boss

## QoL (on unless switched off)
- [ ] Level-up refills HP/MP
- [ ] Auto-save
- [ ] Smart auto-battle that clears normal content
- [ ] 2× speed
- [ ] Point-of-no-return warnings naming what will be lost
- [ ] Interactables look different from decoration (markers/glints)
- [ ] Photosensitivity setting
- [ ] Play Stats page with a copy-report key

## Deliverables
- Game zip; PLAYING.md; RELEASE_NOTES.md; VERIFICATION.md
- Strategy guide: **always** (language: `{{guide_lang}}`)
- Screenshots folder

## Process
- Pace: `balanced` [default]; reports: `15 min`; zips: `phase milestones`; taste review: `non-blocking`
- Budget cap: `{{none | $X}}` (set at G0b after the estimate)
- Deadline / priority order if something must give:

## Engine policy
- Similarity to Shorelight: `similar | different`, because …
- Therefore: `read Shorelight as reference, write fresh` | `clean room (blueprint only)`

## Change log
| When | Change | Impact |
|---|---|---|

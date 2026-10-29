# Designer brief: {{DESIGN_KIND}} options for {{CHARACTERS}} — {{GAME}}

<!-- Lead: DESIGN_KIND = character | pet | monster | art direction. Send only after the cast roster is locked.
PILOT_GATE = "stop until the lead sends GO or notes" (default) | "continue once every checklist line passes".
Fill every slot and delete this comment. -->

## Goal
Produce {{N_OPTIONS}} complete, studio-grade design options per character in {{CHARACTERS}}, for the G2 gallery.
Start with **one pilot sheet** for {{PILOT_CHAR}}, then scale. The in-game assets will be baked from the same source as
the picked option, so build every option from code or data that can export a portrait, sprite or 3D spec.

## Read first
1. `{{REQUIREMENTS}}`: art style, render mode ({{RENDER_MODE}}), quality bar reference, cast roster and pick mode.
2. `{{BIBLE}}` and its cultural guide `{{CULTURE_GUIDE}}`: role, personality, era, place.
3. `{{CAST_DATA}}`: the machine-readable cast data (name, age, role, element, signature items). Single source.
4. `{{REF_PHOTOS_NOTES}}`: binding notes on the user's reference photos. Quality bar: {{QUALITY_BAR_REFS}}.
5. `{{CONTRACTS}}`: portrait, sprite or rig formats the picked design must feed.

## Files you own (exclusive)
- `{{DESIGN_SRC_DIR}}/*` (generator code), `{{DESIGN_OUT_DIR}}/*` (sheets, cards, docs), `{{GALLERY_ENTRY}}`.
- Never edit game files, cast data, the bible or contracts. Report wrong or missing cast data; don't work around it.
- A character not in the locked roster: stop and report. Don't design it.

## Process
1. **Pilot.** One full sheet for {{PILOT_CHAR}}. Self-review it against the quality bar below; write the checklist
   result. Commit, report `PILOT READY`, then: {{PILOT_GATE}}.
2. **Scale** to all of {{CHARACTERS}}. Re-run the checklist per sheet. Iterate while a gap is visible; cap at
   {{MAX_ITERATIONS}} passes per sheet.

## Quality bar (each option)
- Full-body front view at a consistent body ratio; bust close-up; {{TURNAROUND}} (3D needs front, side and back).
- Palette of 5–7 named swatches with hex codes; 3–5 costume callouts in {{SRC_LANG}} and en.
- Title, a one-line concept and a one-sentence cultural basis: what real dress or practice it draws on, and where the
  fantasy departs from it.
- **Silhouette first:** recognisable in solid black at sprite scale ({{SPRITE_PX}} px) and different from the other
  options by silhouette, not just colour.
- **No shared face template.** Each design has its own face shape, jaw, brow, eyes, nose and mouth. Shared helpers
  are fine for cloth shading, never for faces or bodies.
- Shape language matches personality; clear value grouping; one focal accent; wearable, correctly layered costume.
- Every signature item from the cast data is visible: {{SIGNATURE_ITEMS}}.
- Options range from faithful-historical to bold-fantasy; no throwaway options.

## Culturally sound
- Ground costume in real dress of {{ERA_PLACE}}; label anachronisms as deliberate fantasy or remove them.
- Never depict a real deity as a character. Never put real sacred or ceremonial dress on a fictional character.
- {{CULTURE_RULES}}

## Metadata from the bible, never typed
Name, age, role, element and signature items on every card are read from `{{CAST_DATA}}` by your generator. A
hand-typed label is a bug. A design that changes a story fact (age, species, signature item) goes in the report as a
proposal; don't put it on the card.

## Definition of done
1. `{{DESIGN_CHECK_CMD}}` passes: every sheet renders headless with 0 console errors, card metadata equals cast data,
   and every signature item is present.
2. Tests: if the game is 3D ({{RENDER_MODE}}), the turnaround exists for every option. No game tests are needed;
   designs do not touch level or gear fixtures.
3. Validator clean for your outputs: no missing images, no broken links in `{{GALLERY_ENTRY}}`.
4. en strings present: every option name, concept line and callout has an en version.
5. Commit only your paths to `{{BRANCH}}` in `{{WORKTREE}}`. Report, then **STOP**.

## Time budget and stop rule
Budget {{BUDGET_MIN}} min (pilot ≤ {{PILOT_MIN}} min). At 75 %: finish open sheets, start none. At 100 %: commit,
report PARTIAL. When a render is invisible or broken, debug the cause (query bounds, render a multi-view) before
tweaking transforms by trial and error.

## Re-run scope
Re-render only the sheets or options that changed or failed the check.

## Tools and hygiene
- Rendering uses a browser, so run it only through `forge-tools/governor.sh -- <cmd>`.
- Montages, test renders and logs go to `{{SCRATCH}}/{{AGENT_ID}}/`. Only final sheets go in `{{DESIGN_OUT_DIR}}`.
- Look at every PNG you produce with the Read tool before calling it done.
- Only report helper APIs you can show by file:line.

## Report format
```
STATUS: PILOT READY | DONE | PARTIAL | BLOCKED     time: <used>/{{BUDGET_MIN}} min
Branch: {{BRANCH}} @ <sha>
Sheets: <char> — <path>, options <n>, checklist <pass/fail per line>
Recommended pick per character, with a one-line reason:
Cast-data conflicts or proposals:
Export path to in-game assets (portrait/sprite/3D spec): <file:line>
Backlog:
```

> **Shorelight lesson.** Design v1 was rejected as "really bad": every option reused one generic face template. A sheet
> labelled 白芷 as 17 while the bible said 19, because the label was typed by hand. 星河's signature scarf was missing
> from the sprite. The in-game portrait didn't match the picked design until portraits were baked from the sheet's
> own code. 糰子 got a full 10-option sheet and was cut six minutes later, before the roster was locked.

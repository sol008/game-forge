# Phase 3: Art and design

## Purpose

Produce character and pet designs that meet the quality bar, get the user's picks in **one gallery (G2)**, then **bake every in-game asset from the same source** as the approved sheet. For 2D render modes, also make the **art kits** (tiles, objects, backdrops, UI) that builders draw from.

## Inputs

- `docs/REQUIREMENTS.md`: render mode, art style, quality-bar references, options per party member (default 10), story-cast designs (default 1), pick mode (`ask` with a 2-h auto-pick / `auto-recommend`), reference photos folder.
- `docs/STORY_BIBLE.md` (cast, cultural guide, route table), `docs/canon/cast.json`, `docs/canon/appearance_facts.json`.
- `docs/CONTRACTS.md` sprite, portrait and (if 3D) character-spec formats, once phase 2 has written them. Sheets can start before; baking cannot.

## Steps

Runs in parallel with phases 1 (late) and 2. Design agents are CPU-light, but **every render goes through `tools/forge/governor.sh -- <cmd>`**.

1. **Design brief** (lead). `docs/design/DESIGN_BRIEF.md`, game-specific, binding:
   - quality bar: named reference titles; "a studio concept sheet", not a prototype;
   - per option: full-body front, bust close-up, palette swatches with names, 3–5 callouts, title + one-line idea, cultural basis;
   - **silhouette test**: each option reads in solid black at map-sprite scale and differs from the others by silhouette, not colour;
   - shape language matches personality; clear value grouping; costume logic (closures, layers, footwear);
   - **no shared face template**: every option has its own facial structure;
   - keep only story-essential motifs from the bible; everything else may change;
   - **sheet metadata (name, age, role) is pulled from `docs/canon/cast.json`** (`{{CAST_DATA}}`), never typed free-hand.
2. **References** (lead). `docs/design/REFERENCES.md`: binding notes on what to take from each user photo (features, colouring, signature marks). Photos are not committed unless the user says so. Ambiguous reference ("are these new pets or replacements?") → default **additive**, disclose in the same status table.
3. **Pilot sheet** (1 local agent, `briefs/designer.md`). The protagonist only, full option count. Lead self-review against the bar, as a checklist written into `docs/design/<char>/review.md`:
   - [ ] options distinct in black silhouette at sprite scale;
   - [ ] faces distinct (jaw, brow, eye shape), proportions consistent within each option;
   - [ ] palette harmony and one focal accent; callouts legible;
   - [ ] cultural basis stated and plausible for the setting and era;
   - [ ] metadata matches the bible.
   Fail → fix the brief and the shared tooling, re-run (max 2 rounds). **Do not scale until the pilot passes.**
4. **Fan-out** (local agents, one per party member and pet; one agent for all story cast at 1 design each). Each:
   - own worktree, branch `design/<char>`, exclusive files `tools/design/<char>/*`, `docs/design/<char>/*`;
   - **the drawing code is the source**: `tools/design/<char>/design.js` exports one draw function per option, used by the sheet *and* later by the bakers;
   - writes `docs/design/<char>/sheet.png`, `opt01..NN.png`, `<char>.md` (per option: idea, palette hex, costume breakdown, cultural basis, signature items);
   - definition of done: review checklist passes on self-check, renders viewed with Read, time budget 40 min.
5. **Gallery and G2** (lead). Build `docs/design/GALLERY.html` (also published as a private artifact): every party member and pet, all options side by side, the recommended pick per character with one line of rationale. Send **one** message with the link.
   - Pick mode `auto-recommend`: proceed with the recommendations now; the user may override later.
   - Pick mode `ask`: keep working (phases 2, 4, 5 prep). **Only baking waits.**
   - **No reply in 2 h**: take the recommended picks, tag them `[default]` in `docs/design/PICKS.md`, bake, and say so in the next status table. The user may override a `[default]` pick until phase 11; an override re-bakes that character.
6. **Record picks** (lead). `docs/design/PICKS.md` (binding): character → option → sheet path → spec section → bake status. Cuts are recorded too (and propagated everywhere without asking).
7. **Canon update** (lead). Rewrite `docs/canon/appearance_facts.json` from the picked specs. Run the lore lint over screenplays and any built chapters; fix contradicting descriptors directly (bump the screenplay version in `FREEZE.md`, notify the builder).
8. **Bake from the same source** (1 local agent per picked character, or the lead serially at ~5–7 min each). Bakers import `design.js` and render:
   - dialogue portraits (all expressions + blink) at game resolution;
   - map and battle sprite specs (palette, pieces, held items);
   - the 3D character spec input for phase 5 (if 3D).
   Never redraw a picked design in a second, generic renderer.
9. **Signature-item checklist** (baker). `docs/design/<char>/checklist.md`: every callout item → present in portrait / sprite / battle / 3D. A missing renderer piece (a scarf, an earring) is added to the kit, not dropped.
10. **Side-by-side review** (lead). One image per character: sheet option | baked portrait | in-game sprite at play scale | 3D model (when phase 5 lands). Visible gaps → another pass automatically, up to 3 passes. This is never a question for the user.
11. **Art kits** (render mode 2D, or 3D with 2D fallback; starts after step 3's pilot passes, in parallel with steps 4–10). One local agent per kit, `briefs/designer.md` with `DESIGN_KIND=art-kit`:
    - kits: **tiles** per region/biome in the route table, **objects** (props, interactables with their marker/glint, multi-tile footprints), **backdrops** (battle or scene backgrounds, if any), **UI** (frames, icons, cursor; font sizes from `CONFIG`);
    - own worktree, branch `art/<kit>`, exclusive files `tools/art/<kit>/*` (drawing code = source, as in step 4) and the kit's registry module per `docs/CONTRACTS.md`;
    - each kit registers its ids in `docs/design/ART_KITS.md` (id → kit → size → used by chapter); one contact sheet per kit at play scale, viewed with Read;
    - lead review against the art style and the same quality bar; max 2 passes.
    **Kit ids are frozen before phase 4**: after that, only the lead adds ids; none is renamed or removed. Builders use only registered ids and report a missing one; they never invent one. Phase 5 for 2D is then only an art-kit smoke test plus a lineup.

## Outputs

- `docs/design/DESIGN_BRIEF.md`, `docs/design/REFERENCES.md`, `docs/design/GALLERY.html`, `docs/design/PICKS.md`.
- `docs/design/<char>/{sheet.png,optNN.png,<char>.md,review.md,checklist.md,side_by_side.png}`.
- `tools/design/<char>/design.js` (the single source) and its baker.
- 2D: `tools/art/<kit>/*`, kit registry modules, `docs/design/ART_KITS.md` (frozen ids), `docs/design/<kit>_sheet.png`.
- Baked game assets per `docs/CONTRACTS.md` (portrait and sprite modules); updated `docs/canon/appearance_facts.json`.

## Exit gate

Automated:
- [ ] Every entry in `PICKS.md` has baked portrait and sprite assets, and each baker imports its `tools/design/<char>/design.js` (grep check; no second drawing path).
- [ ] Sheet metadata (age, name, role) equals the bible values (script diff).
- [ ] Lore lint 0 conflicts after the canon update.
- [ ] Every signature-item checklist is fully ticked.
- [ ] Validator 0 errors with the new portrait and sprite ids.
- [ ] 2D: every kit in `ART_KITS.md` loads in the sandbox with 0 placeholder draws; ids frozen.
- [ ] `PICKS.md` has a pick (user or `[default]`) for every party member and pet.

Lead review: side-by-side image per character, filed in `docs/design/<char>/side_by_side.png`.
Human: **G2** gallery (picks only; work continues; 2-h timeout to the recommended picks).

## Pitfalls from Shorelight

- **Design v1 was "really bad"**: one shared face template made every option a palette swap; vague costumes; no rationale. 7 concept agents were relaunched with a v2 brief. Hence the pilot and the quality-bar checklist.
- **The in-game portrait didn't match the picked design**: it was drawn by an older generic face template, so edits had no visible effect. Fixed by baking portraits from the sheet's own drawing code. Hence one source.
- **A sheet said 17; the bible said 19.** Metadata comes from data.
- **The sprite renderer had no scarf piece** for the hero's signature item. Hence the checklist.
- **Reference photos misread**: two cat photos were taken to replace an existing pet; 2 agents were re-briefed. Default additive.
- **A pet fully designed (10 options) and cut 6 min later.** Lock the roster before generating assets.
- **Picks requested one character at a time** (6 separate "pick a number" questions in ~40 min, each blocking its bake). One gallery.
- **Procedural-art debugging sinks**: generated SDF code reused names `x2/y2/z2` (use unique identifiers); a shield invisible through ~9 re-renders of rotation guesses when the bounds pass was culling it (query the distance field or render a debug multi-view first); fur displacement beyond the bounding margin.
- **Late likeness asks** ("make 白芷 more feminine", flat 3D faces). Budget a face pass in the side-by-side loop.
- **Text kept the old look** (silver hair in 4 chapters) after the pick. Re-run the lore lint at step 7.

## Time/cost estimate

- 2–3 h wall clock: brief 15 min, pilot 30–40 min, fan-out 40 min in parallel, gallery 10 min, G2 wait ≤ 2 h (work continues), baking ~5–7 min per character serially (or parallel agents). 2D art kits run in parallel (~40 min each).
- Cost: ≈ 5–10 local agent-hours (`tools/forge/cost_estimate.md` row 3; 2–4 design agents at a time), plus ~1 agent-hour per 2D art kit. Light CPU, short browser renders through `tools/forge/governor.sh`; no cloud sessions.

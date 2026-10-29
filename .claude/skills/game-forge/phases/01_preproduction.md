# Phase 1: Pre-production

## Purpose

Write the canon (story bible, systems design, canon fact files, glossary) and one screenplay per chapter, then **freeze the screenplays with a version hash** so builders implement a fixed spec.

## Inputs

- `docs/REQUIREMENTS.md` with `## Lock` (phase 0). Premise may be "pending G1".
- Registry (`tools/forge/agents.sh list`), governor armed.
- Examples of good output (similar policy only; clean room uses `blueprint/content_formats.md`): Shorelight `docs/STORY_BIBLE.md`, `docs/WRITERS_GUIDE.md`, `docs/story/ch0_prologue.md` (map table, ASCII layout, flag table, sound notes), `tools/i18n/GLOSSARY.md`.

## Steps

1. **G1 pitch** (lead; only if no premise). Send **one** message: 3 pitches, each with a zh/en (or other-language) title pair, a 3-line arc, tone, route sketch and ending hook. Mark one "(Recommended)". No answer in 2 h: take the recommended one.
   While waiting, do premise-independent work: steps 4 (systems), 6 (glossary skeleton), 6b (lint tool). **No writer fan-out before the premise is locked.** Then update `REQUIREMENTS.md § Lock` (`premise: locked`).
2. **Story bible** (lead, ~30 min). `docs/STORY_BIBLE.md`, plus `STORY_BIBLE_<lang>.md` for the original language if it differs from the working language. Sections:
   - world lore; the game's signature mechanic (Shorelight: 心燈 lanterns + 靈視 spirit sight);
   - **cast**: id, name in every language, age, role, voice, motifs, weapon/element; mark silent characters;
   - **route / geography table**: chapter → region → maps, matching the locked route scope;
   - chapter beats; endings and their conditions; collectible list with threshold and slack (slack = 25% of the threshold, minimum 2; Shorelight: 28 lanterns, 14 for the true ending);
   - **cultural accuracy and respect guide** (binding): what is real, what is invented, sacred-content rule (witness only: ambience, no melody imitation, no minigames);
   - enemy roster by area.
   The **cast roster is locked here**. An addition later triggers one question: "keep or cut overlapping cast?"
3. **Canon fact files** (lead). Machine-readable, all in `docs/canon/`; the lore lint reads them:
   - `docs/canon/cast.json`: per character id, names in every language, age, role, element, signature items. The single source for sheets (`{{CAST_DATA}}` in `briefs/designer.md`), bakers and data.
   - `docs/canon/appearance_facts.json`: per character hair, eyes, skin, build, age, height, signature items, and **form exceptions** (e.g. "silver hair only in true spirit form"). Seeded from the bible; rewritten after the G2 picks (phase 3).
   - `docs/canon/speakers.json`: who may speak; silent characters (pets, mute NPCs) get narration and emotes only.
   - `docs/canon/timeline.json`: one canonical timeline ("18 years ago", ages, dates).
   - `docs/canon/names.json`: every proper name (cast, places, items, skills) must be unique across categories.
   - `docs/canon/collectibles.json`: the **plan list** (name, chapter, quest id `q_*`). Ids are derived, never hand-typed: `<collectibleId>_<quest suffix>` (quest `q_c3_bell` → `ember_c3_bell`). The validator checks the plan against the code both ways.
4. **Systems design** (lead). `docs/SYSTEMS.md`:
   - combat model, elements chart, stat names, currency (all go into `CONFIG` in phase 2);
   - **progression table**: per chapter the expected level, gold, gear tier, party and kit at entry and at each boss. This becomes `G.Data.progression` and the `chapterStart(ch)` fixture (phase 7 owns tuning);
   - XP/gold curve, shop tiers, collectible thresholds, difficulty band (default boss first-try 86–94%);
   - QoL defaults from `REQUIREMENTS.md` (level-up refill, auto-battle that clears normal content, point-of-no-return warnings, harvest markers…).
5. **Writers' guide** (lead). `docs/WRITERS_GUIDE.md`, the screenplay format every chapter file follows:
   - **header table**: chapter, maps, flags, estimated play time;
   - **maps**: id (unique snake_case place name, e.g. `tamsui_fort`), name, purpose, size in tiles, ASCII layout, light, particles, exits;
   - **scene cues**: one `<!-- cue: <scene-id> bgm=<id>|none ambience=<id>|none sfx=<ids> -->` per scene; `none` is an explicit silence;
   - **NPCs**: id, sprite, position, all dialogue and its flag variants;
   - **cutscenes** as numbered beats `speaker(expression): line`, stage directions in brackets, choices, `flag: chN_*`, items, joins, battles;
   - **side quests**: every step has a **hint** (NPC line, quest-log text, or visible marker), rewards, missable window;
   - shops, chests, **puzzles with exact mechanics**; mark language-dependent ones `[PUZZLE-LANG]` (glyphs, rhymes, wordplay);
   - **sound notes** per scene, including "must not" rules (e.g. "never synthesize the ritual chant");
   - style: voices, line length limit (Shorelight: ≤ 60 chars), dialect policy, id conventions (flags `chN_*`, chapter-local data `cN_*`, quests `q_*`).
6. **Glossary v0** (lead). `docs/i18n/GLOSSARY.md`: cast, places, stat names, currency, elements, the signature mechanic, in every language. Translators extend it later; they never rename.
6b. **Screenplay + lore lint** (lead, **before** writer fan-out: writers' definition of done runs it). `tools/lint/screenplay.js` (spec in `blueprint/qa_tools.md`):
   - every scene names a map and has one `<!-- cue: <scene-id> bgm=<id>|none ambience=<id>|none sfx=<ids> -->` line, plus its encounters and rewards;
   - every side-quest step has a hint; every flag is `snake_case` and `chN_`-prefixed; map ids are unique snake_case place names;
   - every speaker is in `cast.json` and allowed by `speakers.json`;
   - **lore lint**: descriptors near a character's name (hair, eye, age words) agree with `appearance_facts.json`; time phrases agree with `timeline.json`;
   - collectibles match the plan list in `collectibles.json`; names unique per `names.json`;
   - extracts the cue lines to `docs/story/cues.json`; phase 4's `tools/test/spec_conformance.js` asserts them in game.
   Run it green on the sample scene in `WRITERS_GUIDE.md` before any writer starts.
7. **Writer fan-out** (4–6 local agents, `briefs/writer.md`). Split by region or chapter range (Shorelight: 6 writers by region). Each:
   - own worktree, branch `write/chA-B`, exclusive files `docs/story/chN_*.md` for its range;
   - reads bible, writers' guide, canon files, glossary, `docs/CONTRACTS.md` if it exists (art and music ids may still be placeholders: name a fallback);
   - definition of done: screenplay lint 0 errors on its files; open continuity questions listed in a `## Questions for the lead` section, never asked mid-run;
   - time budget 60 min.
   Writers are CPU-light (no browser), so they don't count against governor slots.
8. **Tag key scenes** (lead, at merge, before freeze). Mark 5–8 key emotional scenes in the screenplays, e.g. `<!-- key-scene: reunion -->`, and list them in `docs/story/KEY_SCENES.md` with why each matters. Phase 9 polishes exactly these, and the G3 taste previews come from them. *(Shorelight: the polish agent chose its 6 scenes late, by its own judgement.)*
9. **Merge and resolve** (lead). Merge writer branches; answer `Questions for the lead` by **decide and disclose**: rename minor-name clashes, follow the timeline file, pick dialect orthography from a standard dictionary. Never send continuity nits to the user.
10. **Freeze** (lead). `tools/lint/freeze.sh` writes `docs/story/FREEZE.md`:
    ```
    | file                     | version | sha256 (12) | frozen at        |
    | docs/story/ch3_harbor.md | v1      | 9f2c1a04be7d | 2026-11-02 05:10 |
    ```
    Builder briefs cite the hash. A later edit bumps the version, and the lead sends the diff to that chapter's builder in the same turn. Builders re-check the hash at start and at done.

## Outputs

- `docs/STORY_BIBLE.md` (+ language twin), `docs/SYSTEMS.md`, `docs/WRITERS_GUIDE.md`.
- `docs/canon/{cast.json,appearance_facts.json,speakers.json,timeline.json,names.json,collectibles.json}`.
- `docs/i18n/GLOSSARY.md` (v0).
- `docs/story/chN_<slug>.md` (one per chapter, plus endings), `docs/story/cues.json`, `docs/story/FREEZE.md`.
- `tools/lint/screenplay.js`, `tools/lint/freeze.sh`.

## Exit gate

Automated:
- [ ] Screenplay lint: 0 errors, 0 warnings across all chapters.
- [ ] Lore lint: 0 conflicts (appearance, speakers, timeline); `names.json` has no duplicates.
- [ ] Collectibles available ≥ threshold + slack (25%, minimum 2), each tied to a `q_*` quest in some chapter.
- [ ] `FREEZE.md` lists every screenplay with a hash that matches the file.
- [ ] `REQUIREMENTS.md § Lock` shows the premise locked.

Human: **G1** only, and only if the requirements had no premise.

## Pitfalls from Shorelight

- **Setting pivot after 15 agents launched.** 6 writers were relaunched by region. Writers start only after the lock.
- **ch0 screenplay revised after its builder started**; a message told the builder to re-read it. Hence the freeze hash.
- **Text vs chosen look.** 白芷 was written silver-haired with gold eyes in ch1, 4, 7 and 9 after the pick said otherwise. Hence `appearance_facts.json` and the lore lint, re-run after G2.
- **A silent cat spoke a line** in ch10, and a timeline slip ("last Ghost Festival" for "eighteen years ago"). Only translators caught them. Hence `speakers.json` and `timeline.json`.
- **芋圓 the cat vs 芋圓 the dessert.** One name, two things. Hence `names.json`.
- **Cast added, then cut.** Two real cats became pets; 糰子 was fully designed, then cut 6 min later, leaving ~800 lines across ch3–11 to rewrite. Lock the roster; ask "keep or cut?" once.
- **Collectibles awarded via flags only** did not count toward the ending; the finale checked the wrong ids for 4 stories. Hence the `collectibles.json` plan list, derived ids, and a validator check both ways.
- **Festival night shipped silent**: the screenplay required ambience, and a test asserted "no BGM". Hence `<!-- cue: -->` lines → `cues.json` → `spec_conformance.js` assertions.
- **~25 quests with no in-game pointer**, found only by post-ship QA. Hints are written into the screenplay, per step.
- **Glyph puzzles** (the 洛 lantern, mine-lamp marks, 山歌 rhymes) could not be translated. Flag them `[PUZZLE-LANG]` at writing time.
- **~20 min of title Q&A** spread over several messages. G1 is one message.

## Time/cost estimate

- ~1.5 h wall clock: lead 45 min (bible, systems, guide, canon), writers 45–60 min in parallel, merge and freeze 15 min. Add up to 2 h if G1 waits for the user (premise-independent work continues).
- Cost: 4–6 local text agents; no browser, no cloud sessions.

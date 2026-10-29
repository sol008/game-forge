# Phase 6: Localization

## Purpose

Every displayed string exists in every language, uses the glossary's terms, and fits its box. The structure (scopes, glossary, extractor) exists from day 0; the translation work backfills idle CPU as chapters merge.

## Inputs

- `docs/REQUIREMENTS.md`: original language, target languages, puzzle-translation policy.
- The i18n module from phase 2: **shared scope** (UI, data) + **per-chapter scope** that only fills gaps, never overrides shared.
- `docs/i18n/GLOSSARY.md` v0 (phase 1); `docs/story/*.md` with `[lang-dependent]` puzzle flags.
- Merged chapters with i18n stubs (phase 4). Translation of a chapter starts when it merges, not when all have.

## Steps

1. **Day-0 structure** (lead, during phase 2; verify here).
   - Dictionaries: `<lang>_ui`, `<lang>_data` (shared), `<lang>_chN[a-z]` (per chapter, loader accepts a letter suffix).
   - Lookup order: current chapter fills gaps; shared always wins on its own keys.
   - Source text: whole static literals; interpolation only through `%s`/`%d` templates with whole-phrase static parts.
   - Extractor `tools/i18n/extract.js`: buckets keys into ui / data / chN, reports coverage, `--missing`, `--stub chN`; **marks puzzle and glyph keys** (from screenplay flags and a glyph heuristic); excludes painted art text by declared pattern.
2. **Glossary complete** (1 local agent or the lead, before chapter fan-out). `docs/i18n/GLOSSARY.md`:
   - how the dictionaries work (exact-key match, templates, load order, markup that must survive);
   - style: spelling variant, quote and ellipsis conversion, no italics if the renderer can't draw them, gloss a cultural term once then use the plain word;
   - dialect and register rules (Shorelight: 阿嬤 → *Grandma*, 歹勢 → *sorry, sorry*);
   - **term table**: every cast name, place, item, skill, stat, element, currency, the signature mechanic; one rendering each.
   Translators may add terms; renaming one goes through the lead.
3. **Shared first** (1 local agent, `briefs/translator.md`). `<lang>_ui` and `<lang>_data`. Every chapter translator depends on these terms.
4. **Cut units** (lead). One unit = one chapter dictionary; **split at ≤ 1,200 source lines** into `chN` / `chNb`; pair small chapters into one unit. Register each unit in `.forge/agents.json`.
5. **Translator fan-out** (~6 local agents, `briefs/translator.md`). CPU-light, so they **backfill** idle capacity alongside builders. Each:
   - own worktree, branch `i18n/<lang>-chN`, exclusive files: its dictionary files only;
   - reads the screenplay for context, the glossary, the bible's voice notes;
   - definition of done: `extract.js --missing` shows 0 for its unit; glossary lint clean; validator 0 errors; source issues found (a silent character speaking, a timeline slip, a wrong name) written to `docs/forge/followups.md`, **not** fixed in source;
   - time budget ~30 min per 1,200 lines (measured ~100 lines/min per agent).
6. **Puzzle keys** (lead decides per key, from the requirements policy):
   - *keep + gloss*: keep the original glyph, add a translated gloss (Shorelight: the 洛 lantern);
   - *re-author*: new wordplay in the target language (Shorelight: new English rhyming couplets for the 山歌 duel).
   If the game logic checks the answer, the lead adds a per-language answer to the data; the translator never edits logic. Record each decision in `docs/i18n/puzzles.md`; the guide (phase 10) documents both languages.
7. **Late-string rule** (every brief, all phases). An agent that adds or changes display text adds every translation in the same commit. A source-language fix (proofread, phase 8, `briefs/proofread.md`) also updates the translation and any test that quotes it.
8. **Layout check** (1 local agent, browser via `governor.sh`). `tools/i18n/layout.js`:
   - measures every string with the real bundled font against its box (dialogue, menu columns, battle target, turn bar, title, item descriptions), **for every language including the original**;
   - fixes overflow **in the UI code** (wrap, shrink-to-fit, wider column), never by truncating strings;
   - screenshots every screen in every language through `forge-tools/shoot.js` and views them;
   - report to `docs/qa/layout_<lang>.md` (fixed, remaining, method).
9. **Glyph coverage.** Font subsetting runs at package time (phase 11); here, assert that the font source covers every character used by every language.

## Outputs

- i18n dictionaries: `<lang>_ui`, `<lang>_data`, `<lang>_chN[a-z]` (paths per `blueprint/architecture.md`).
- `docs/i18n/GLOSSARY.md` (final), `docs/i18n/puzzles.md`.
- `docs/qa/layout_<lang>.md`; extractor reports in `tools/i18n/out/` (gitignored).
- `tools/i18n/extract.js`, `tools/i18n/layout.js`, glossary lint.

## Exit gate

Automated:
- [ ] Coverage **≥ 99.9%** per target language (`extract.js --missing`); the remainder listed and justified.
- [ ] Validator i18n rule: 0 source keys without a translation in any target language.
- [ ] Layout check: **0 overflows** in every language, including the original.
- [ ] Glossary lint: every glossary term renders the same way everywhere.
- [ ] No dictionary unit over 1,200 source lines; no chapter key overrides a shared key.
- [ ] Every flagged puzzle key has a decision in `puzzles.md`.

No human gate.

## Pitfalls from Shorelight

- **One flat global dictionary**: short lines (誰？ 好！) collided across chapters. Then chapter entries overrode shared strings: naming the cat "Taro" would have renamed the "Taro Balls" item everywhere. Hence shared + per-chapter scope from day 0.
- **The cat and the dessert shared the name 芋圓.** The item became 芋圓湯 "Taro Ball Soup". Unique names belong in the canon (phase 1).
- **Glyph puzzles** (the 洛 lantern, mine-lamp marks, 山歌 rhymes) had no direct translation; solved ad hoc. Flag at writing time, decide per key.
- **The ch11 dictionary reached 2,464 lines**, too much for one agent; it was split mid-run with a loader change. Split at 1,200 up front.
- **9, then 29 English overflows** (titles, settings, battle target text, turn bar); a text-baseline bug hit Chinese too. Measure every language, fix in UI code.
- **Untranslated lines from late helpers** (4 each in ch3, 7, 9); coverage dipped to 89–90% when a stats page added menu text. Late-string rule + validator.
- **A generic `'%s、%s'` template loaded first** silently shadowed chapter templates. Document load order in the glossary.
- **Translators were the best QA**: they caught a talking silent cat, a timeline slip and 6 source bugs. Route their findings to the lead.
- **Estimate vs actual**: 25–35 min forecast, ~20 min actual for 11 chapters with 6 agents; layout QA took ~33 min.

## Time/cost estimate

- ~30 min wall clock for translation (6 agents in parallel, staggered as chapters merge) + ~30 min layout check per target language.
- Cost: ~6 local agents, CPU-light; 1 browser slot for the layout check. No cloud sessions.

# Translator brief: {{UNITS}} {{SRC_LANG}} → {{TARGET_LANG}} — {{GAME}}

<!-- Lead: one unit is at most ~1,200 source lines; split bigger units into a/b files first. CPU-light: use these
agents to backfill idle capacity. Fill every slot and delete this comment. -->

## Goal
Translate every display string of {{UNITS}} into natural {{TARGET_LANG}} ({{TARGET_STYLE}}), matching the glossary
exactly, and make every line fit its box. You are also a second QA pass: report source bugs you notice.

## Read first
1. `docs/i18n/GLOSSARY.md`: names, terms, style rules. Single source of truth.
2. `{{I18N_DOC}}`: lookup rules (exact source key, templates `%s`/`%d`, markup spans, scope and load order).
3. `{{BIBLE}}`: tone and voices. `docs/canon/appearance_facts.json`, `docs/canon/timeline.json`.
4. Source files: {{SOURCE_FILES}}. Missing-key list: `{{I18N_CMD}} --missing --unit {{UNITS}}`.
5. Puzzle policy from `{{REQUIREMENTS}}`: {{PUZZLE_POLICY}}.

## Files you own (exclusive)
- `{{DICT_FILES}}` (unit-scoped dictionaries only).
- Never edit source text, game code, the shared dictionaries `{{SHARED_DICTS}}` or the glossary. Put proposed shared
  keys or glossary additions in your report.
- Unit entries fill gaps only. They must never override a shared UI or data string.

## Rules
- Copy every key byte for byte, full-width punctuation included. Keep `%s`, `%d` and markup spans on the same words.
- Glossary names and terms exactly. Gloss a culture-specific term once, on first use, then use the plain word.
- Keep each speaker's voice from the bible; dialect flavour light and readable, never pidgin. Deities with reverence.
- Keys tagged `// i18n:puzzle` (from `[PUZZLE-LANG]` screenplay lines) and any other glyph, pun or rhyme puzzle:
  apply {{PUZZLE_POLICY}}. If you rewrite a puzzle, its solution
  must still check correctly in the game; flag it for the lead.
- Silent characters stay silent. A line that gives one a voice is a source bug: report it, don't translate around it.
- Box fit: lines over the measured width in `{{LAYOUT_CMD}}` get rephrased, not truncated.
- Source bugs (a typo, a continuity slip, a wrong name, a timeline error, a silent character speaking): report with
  file:line. Never fix them yourself.

## Definition of done
1. `{{I18N_CMD}}`: 0 missing keys for {{UNITS}}, i.e. an entry in every target language (none when `langs` =
   [source]): {{TARGET_LANG}}, and en if it is a pivot. The coverage % is informational only. Every entry left equal
   to its source is listed with a reason.
2. `{{LAYOUT_CMD}}`: 0 overflows in your units, in every box type.
3. Tests: the unit test `{{UNIT_TEST_CMD}}` still passes in {{RENDER_MODE}} with lang = {{TARGET_LANG}}, using the
   canonical fixture `{{FIXTURE}}` (a smoke run is enough).
4. `{{VALIDATE_CMD}}`: 0 errors, 0 new warnings. `{{UNIT_TESTS}}` pass.
5. Commit only your dictionary files to `{{BRANCH}}` in `{{WORKTREE}}`. Report, then **STOP**.

## Time budget and stop rule
Budget {{BUDGET_MIN}} min (expect about 100 lines/min). At 75 %: finish the open file, start no new one. At 100 %:
commit, report PARTIAL with the missing keys left.

## Re-run scope
Re-run the coverage and layout checks for your units only. Re-run the smoke test only if a template key changed.

## Tools and hygiene
- Browser runs (layout check, smoke test) only through `tools/forge/governor.sh -- <cmd>`.
- Coverage outputs and logs go to `$SCRATCH/{{AGENT_ID}}/` (set in `docs/forge/env.md`), never the repo.
- Only report loader or i18n APIs you can show by file:line.

## Report format
```
STATUS: DONE | PARTIAL | BLOCKED        time: <used>/{{BUDGET_MIN}} min
Branch: {{BRANCH}} @ <sha>    Files: <paths>
Missing keys: <unit> <n> (0 to pass; coverage <pct>, informational)
Layout: <overflows fixed>/<remaining>       Smoke: <PASS/FAIL> in {{RENDER_MODE}}
Puzzle handling: <key> — kept+gloss | rewritten (solution checked: yes/no)
Proposed glossary / shared-dict additions:
Source bugs (not fixed): <file:line> | what | suggested fix
Backlog:
```

> **Shorelight lesson** (opening Shorelight itself: similar policy only).
> One flat dictionary let short lines (誰？ 好！) collide across chapters, and a chapter entry
> nearly renamed the item "Taro Balls" everywhere after the cat Taro. The ch11 file had 2,464 lines and had to be split
> mid-run. Translators found 6 source bugs (a cat speaking, a timeline slip), which proved the value of reporting
> them. The English layout pass then fixed 29 overflows that no one had measured.

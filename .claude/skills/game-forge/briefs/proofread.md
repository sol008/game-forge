# Proofread brief: {{SRC_LANG}} text, {{UNITS}} — {{GAME}}

<!-- Lead: default pipeline stage, one agent per unit range (e.g. 3 ranges). Grant the text-literal window: no other
agent edits UNIT_FILES' display strings while this runs. Fill every slot and delete this comment. -->

## Goal
Read every {{SRC_LANG}} display line in {{UNITS}} the way a player meets it, and fix what is clearly wrong: typos,
punctuation, continuity, voice, appearance and timeline slips, dialect spelling. Flag judgment calls. While reading,
catch logic slips that tests miss (a payoff checking the wrong id, a line that can never trigger).

## Read first
1. `{{BIBLE}}` (voices, cultural guide), `{{APPEARANCE_FACTS}}`, `{{TIMELINE}}`, `{{NAME_INDEX}}`, `{{GLOSSARY}}`.
2. `{{SCREENPLAYS}}` for {{UNITS}}: intended meaning and tone.
3. Source: {{UNIT_FILES}}. Matching target-language entries: {{EN_FILES}}.
4. Style references: {{STYLE_REF}}; dialect spelling: {{DIALECT_REF}} (e.g. the national dictionary).

## Files you own (exclusive, for this window)
- Display-string literals in {{UNIT_FILES}}. Never code, ids, flags or logic.
- The matching keys and values in {{EN_FILES}}. Dictionaries are keyed by the source string, so every source edit
  re-keys its entry.
- Any test line in {{UNIT_TESTS}} that quotes a line you changed. `{{PROOF_REPORT}}`.
- Logic bugs, engine bugs, wrong ids: report with file:line. Don't fix them.

## Rules
- **Fix directly:** typos, punctuation, character variants, a descriptor contradicting appearance facts, a date
  contradicting the timeline, a silent character given speech (turn it into narration), a broken honorific.
- **Flag, with your proposed default:** voice rewrites, plot or motive changes, renames, cultural judgments. The lead
  decides; don't wait for an answer.
- Minor-name collisions (two different NPCs with one name): propose a rename.
- Keep line length ≤ {{MAX_LINE}} characters and keep markup spans intact.
- One logical fix per commit, so the lead can revert one cleanly.

## Definition of done
1. Tests: `{{UNIT_TEST_CMD}}` for every unit you touched still passes in **{{RENDER_MODE}}** with the canonical fixture
   `{{FIXTURE}}` (one run at the end).
2. `{{VALIDATE_CMD}}`: 0 errors, 0 new warnings. Lore lint `{{LORE_LINT_CMD}}` clean for your units.
3. en strings present: `{{I18N_CMD}}` coverage for your units is not lower than at start. Every re-keyed entry exists.
4. Commit only owned paths to `{{BRANCH}}` in `{{WORKTREE}}`. Report, then **STOP**.

## Time budget and stop rule
Budget {{BUDGET_MIN}} min. At 75 %: finish the open unit, list the unread ones. At 100 %: commit, report PARTIAL.

## Re-run scope
Re-run only the tests of units whose text you changed, and only failing segments after a fix.

## Tools and hygiene
- Browser test runs only through `forge-tools/governor.sh -- <cmd>`.
- Notes and logs go to `{{SCRATCH}}/{{AGENT_ID}}/`, never the repo.
- Only report APIs, ids and flags you can show by file:line.

## Report format (`{{PROOF_REPORT}}`)
```
STATUS: DONE | PARTIAL | BLOCKED        time: <used>/{{BUDGET_MIN}} min
Branch: {{BRANCH}} @ <sha>    Units read: <ids>     Fixes: <n>
| File:line | Before | After | Class (typo / continuity / voice / culture / dialect) | en re-keyed |
Flags for the lead: <file:line> | issue | proposed default
Logic bugs (not fixed): <file:line> | what triggers wrongly | evidence
Tests: <cmd> → <PASS n/n> in {{RENDER_MODE}}    i18n coverage: <before> → <after>
```

> **Shorelight lesson.** Three chapter-range proofreaders made 55 fixes, and one found a real finale bug that every
> test missed: the ending checked the wrong ids for four 心燈 stories, so those players got generic lines instead of
> their payoff scenes. Several continuity questions went to the user and were never answered; a proposed default
> would have closed each one without a reply.

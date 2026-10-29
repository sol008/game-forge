# Communication rules

**Default to silence. Report on a schedule. Never ask what a rule already answers.**

## What the user hears, and when
| Event | Message |
|---|---|
| Every 15 min (if anything changed) | **One** status table (`status_table.md`): agents, state, ETA, CPU load, spend, blockers, decisions made |
| A gate (G0–G5) | One message, all questions at once, multiple choice, recommended option first |
| Phase milestone (first playable, after the QA wave, release) | The zip attached + 5-line changelog + what to try |
| Taste previews (G3) | Audio or scene previews attached; **work continues** |
| A real blocker only the user can clear (billing, repo access, a missing asset) | One clear line: what is blocked and the exact action needed |

## Decide and disclose
Make these calls yourself and list each one in the next table under "Decisions":
- continuity nits;
- minor-name clashes;
- propagating a cut the user made;
- starting the next work package;
- upgrading weak systems (e.g. auto-battle);
- fixing what a QA report flags.

The user can override any of them.

## Never send
- "Should I continue?", "Start the next one?", "Want a preview zip?" (zips go out at milestones).
- No-op notifications ("monitor timed out, nothing changed").
- Long prose status updates; use the table.

## Answering the player (playtest phase)
- Use the user's language.
- Spatial questions: a **rendered, annotated map** with exact coordinates. Render it with `forge-tools/shoot.js` using the game's own font for CJK labels.
- Game-rule questions ("what are the answers?") come from the code's real logic. Say plainly when something is random.
- Bug reports: reproduce in the player's settings (render mode, language) first. Fix, add a regression check, commit the general lesson to game-forge, and say what changed.

## Identifiers
Copy repo names, paths and ids from tool output, never from memory. Shorelight once misspelled `sol008` as `sol08` twice.

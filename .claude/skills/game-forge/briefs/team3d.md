# 3D team brief: {{DOMAIN}} — {{GAME}}

<!-- Lead: usually run as a cloud session, so wrap this in cloud_session.md. Launch only after the contract smoke
test passed with one sample asset per team type. If a domain is split across teams, name one registry owner.
Fill every slot and delete this comment. -->

## Goal
Give every asset in {{DOMAIN}} a finished 3D model at the bar in `{{CONTRACTS_3D}}`: {{ASSET_LIST}}
({{ASSET_COUNT}} types; full list: `{{REGISTRY_LIST_CMD}}`). Each one is on-model against its reference, within
budget, and finished from every camera angle. No untextured grey boxes.

## Read first
1. `{{CONTRACTS_3D}}`: units, axes, camera, lighting, materials, registry API, budgets, ownership table. Binding.
2. `{{REFS}}` and `{{PICKS}}`: reference sheets and picked designs. On-model means matching these.
3. `{{ART_NOTES}}`: footprints, solid cells, placement rules.
4. The lead-owned core you call: {{CORE_FILES}}. Read it; never change it.

## Files you own (exclusive)
- `{{TEAM_FILES}}`, `{{TEAM_TOOLS_DIR}}/*`, `{{REPORT_PATH}}`, `{{LINEUP_DIR}}/*`.
- Registry owner for {{DOMAIN}}: {{REGISTRY_OWNER}}. If that isn't you, register through its API only.
- Never edit or shim the core. If the contract lacks a hook or the core has a bug, use the documented fallback,
  report it (format below) and keep going. The lead fixes the core once for every team.

## Order of work
1. **Contract smoke (first 15 min):** build one sample asset end to end, load it in game on `{{SMOKE_MAP}}`, push it.
2. Build assets in the order listed. After each asset: lineup render next to its reference, then commit and push.
3. Per asset: a viewer render from 4 sides, a triangle and draw-call count against budget, and 0 console errors.
4. One pass. Revisit an asset only if it failed a check or was off-model. **No second full sweep.**

## Definition of done
1. Tests: `{{SMOKE_TEST_CMD}}` loads {{SMOKE_MAPS}} in **{{RENDER_MODE}}** ({{LITE_FLAG}} allowed for speed) with the
   canonical fixture `{{FIXTURE}}`; 0 page errors, `{{LAST_ERROR}}` null, every {{DOMAIN}} type uses a real model.
2. `{{VALIDATE_CMD}}`: 0 errors. `{{BUDGET_CHECK_CMD}}`: every model within budget.
3. Lineup PNG per asset group in `{{LINEUP_DIR}}`, side by side with the reference; you looked at each one.
4. en strings present for any display name you add (normally none).
5. `git merge-tree --write-tree origin/{{BASE}} HEAD` is clean. Final push to `{{BRANCH}}`. Report, then **STOP**.

## Time budget and stop rule
Budget {{BUDGET_MIN}} min. At 75 %: finish the current asset, start no new one. At 100 %: push, report PARTIAL with
the unbuilt list. A crash or failure at the same step twice: report it and move to the next asset.

## Re-run scope
Re-render and re-test only failed or changed assets, then one final smoke run.

## Cloud rules (when run as a cloud session)
- Push a WIP commit every 10 min and after each asset. Status goes in the commit message:
  `[{{AGENT_ID}}] <done>/<total> | <asset> | next: <x> | blockers: <none|...>`.
- Never wait for human approval. The lead may pause, resume or stop you; follow those messages without asking.
- Ship-without-you deadline: {{SHIP_WITHOUT_YOU_AT}}. Whatever is pushed by then is merged; the rest is lost.

## Tools and hygiene
- Every browser or headless-GL run goes through `forge-tools/governor.sh -- <cmd>`.
- Test renders, logs and turntables go to `{{SCRATCH}}/{{AGENT_ID}}/`. Only curated lineups go in `{{LINEUP_DIR}}`.
- No GPU means no video or performance claims; report draw calls and triangle counts only.
- Only report APIs you can show by file:line, including what you export.

## Report format (`{{REPORT_PATH}}`)
```
STATUS: DONE | PARTIAL | BLOCKED        time: <used>/{{BUDGET_MIN}} min
Branch: {{BRANCH}} @ <sha>    merge-tree vs {{BASE}}: clean | conflicts <paths>
Assets: <done>/<total>; unbuilt: <ids>
Smoke: <maps> in {{RENDER_MODE}} → <PASS/FAIL> (log: {{SCRATCH}}/{{AGENT_ID}}/<file>)
Budget: worst tris <id n>, worst draw calls <id n>
Exports: <global.fn(args)> — <file:line>
Core/contract gaps (unpatched): <file:line> | need | fallback used
Off-model or weak assets:
Backlog:
```

> **Shorelight lesson.** 11 cloud 3D teams pushed nothing in their first 20 minutes, and all of that work was lost when
> quota ran out. The battle team then sat ~40 min waiting for a human "yes, resume". Teams shimmed a missing core hook
> and two monster teams each built their own registry. Cats passed every automated check and were still off-model.
> The 3D sweep agent started a needless 2-hour second full pass until the lead stopped it.

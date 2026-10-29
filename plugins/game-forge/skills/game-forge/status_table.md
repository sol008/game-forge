# Status table (posted every 15 min if anything changed)

```
**{{GAME}}: phase {{N}} ({{name}}), {{elapsed}} in, spend ${{spent}} / est ${{estimate}} (cap {{cap|none}})**

| Agent / session | Task | State | ETA | Note |
|---|---|---|---|---|
| ch3-builder | Chapter 3 | testing (2/4 segments) | 20 min | waiting on a browser slot (2 min) |
| cloud qa-ch6-8 | Side-quest walkthrough | 5 commits, last 4 min ago | 40 min | found 2 missables, fixing |
| … | | | | |

Load 3.4 / 4 cores · browser queue 1 waiting · stalls: none
Merged since last: ch1, ch2 (unit 64/64, validator 0)
Decisions made: renamed duplicate NPC 阿義 → 阿德 in ch10 (minor-name clash)
Needs you: nothing
```

Rules:
- One table per message, no prose beyond the 4 footer lines.
- ETA comes from the registry or the test-segment counts. Write `?` if unknown, never a guess dressed as fact.
- A stalled row is reported **together with the action already taken** (e.g. "killed hung test, re-running segment 3").
- "Needs you" says `nothing` unless a gate or a real blocker exists.

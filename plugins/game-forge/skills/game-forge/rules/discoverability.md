# Discoverability rules: the player must be able to find everything

Shorelight's most common post-ship bug: content that worked, but that a player could not find. Examples:
- 扇貝殼 on a bare grass tile;
- 懷錶 in a dark cave;
- 3 of the 7 mushrooms with no visual;
- about 25 quests whose next step nobody mentioned;
- a 心燈 lost forever behind a strip the player might never cross.

The validator enforces D1–D10, and the QA walkthrough (phase 8) checks them by playing.

| # | Rule |
|---|---|
| D1 | Every interactable that matters (quest item, collectible, clue, chest) has a **visible marker**: a glint, a sparkle, or a hint tag. Hidden or "spirit-sight" finds still get a marker when that mode is on. |
| D2 | Every such interactable also has a **pointer**: an NPC line, a quest-log stage text, or a party remark. When the find needs a mechanic (e.g. 靈視), the pointer names the mechanic and where to get it. |
| D3 | Hit areas are at least 2 tiles, or the full footprint of a multi-tile object. |
| D4 | Every quest **stage** has hint metadata saying where to go next, and the quest log shows it. |
| D5 | Every quest has **at least two ways to start** (e.g. an NPC and a touch strip), or one way that cannot be bypassed on the critical path. |
| D6 | Every **one-way transition** checks open side quests and collectibles, names **everything** it closes and where each one is, and offers "wait" and "save first" (`pointOfNoReturn`). Choices that lose content forever get a confirmation. A bare "you can't come back" tells the player nothing they can act on. |
| D7 | Interactables look different from decoration: pickable herbs differ from decorative herbs. |
| D8 | Preconditions are visible: if a find needs night, an item or a prior scene, an in-game line says so. |
| D9 | Every quest and collectible has one **guidance record** (below) in a data registry, and the validator rejects a missing field. Per-quest patches drift; one registry keeps every UI consistent. |
| D10 | Every guidance UI **reads that registry**; none holds its own copy of the text. A hint fixed once is then fixed in the log, the rumours, the party talk and the guide. |

## Guidance is a system, not per-quest patches

Plan it in phase 1 and build it in phase 2. Retrofitting it after the chapters were built cost a whole day.

**The record** (one per quest or collectible, in `G.Quests.define`'s `guide`, `blueprint/content_formats.md` §4):
- **where**: map and NPC;
- **when**: day, night or story phase;
- **closesAt**: the point of no return that ends it, if any;
- **rumour**: one line a stranger might say;
- **hints**: 4 graded tiers, each adding information the last lacked: riddle → region + NPC → area → exact spot;
- **area**: the key for per-area tallies.

**Everything that reads it:**
- collectible panel: `x/N` found, and the true-ending threshold;
- quest log: where, when, closes-at, notes;
- rumours for undiscovered quests, shown only after the player has entered their area (no spoilers from afar);
- quest-giver marks over NPCs, toggleable;
- per-area tallies (`3/5 here`);
- companion party talk, which draws on the hint tiers;
- a recap on load ("last time…", the open goals);
- a **stuck offer** after N minutes without progress or after repeated minigame fails: offer the next hint tier, never force it;
- guidance presets: **explore** (marks and offers off), **standard**, **guided** (marks on, early offers).

**QA it without the guide.** In phase 8, walkthrough agents may use **only in-game text** (no guide, no code, no screenplay) and record the lowest hint tier that was enough for each unit. A unit that needs tier 4, or that no tier solves, is a discoverability bug.

## The guide is part of discoverability
- The strategy guide is generated from data. Every map image is annotated with exits, NPCs, clue tiles, chests and collectibles.
- Every minigame is documented: scoring, best answers, what is random.

In Shorelight, the questions "where is 剝皮寮?", "where are the footprints on the persimmon frost?" and "what are the 山歌 answers?" all came from guide gaps.

## Answering the player
- **Spatial answers come from a rendered map with overlays**, never from reading the code. Shorelight gave wrong directions once ("west edge" vs the actual "bottom-left corner").
- Answer in the player's language.
- Give exact coordinates and a picture.

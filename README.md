# Endless Nature - agentic development starter pack

Working title: **Endless Nature**. This is a plan and a small set of project-management tools, not a playable game.

The proposed application is an offline Windows first-person walk through a beautiful, believable, procedurally extending wilderness. There are no objectives, combat, survival systems, NPCs or runtime AI calls. Meshy and ElevenLabs are development-time asset services. No manual Blender workflow or `.blend` dependency is permitted.

**Owner:** start with [the non-technical getting-started guide](docs/START_HERE.md).
**Coding agent:** read [AGENTS.md](AGENTS.md), then [PLAN.md](PLAN.md), the latest rows of [DLOG.md](DLOG.md), and your single assigned task.

## What works in this pack now

Requires Python 3.10 or later; the helper tools use only its standard library.

```text
python tools/project.py validate
python -m unittest discover -s tools -p "test_*.py"
python tools/project.py status
python tools/project.py brief T001
```

`brief` prints a bounded assignment. It does not call a model, edit code, run paid jobs, or start an autonomous loop. Status is recorded only in `PLAN.md`.

## Not built yet

There is no `game/project.godot`, terrain implementation, game test runner, asset-service client or Windows build. The relevant task cards create them. Any engine commands elsewhere in the pack are labelled as future commands until their owning task is accepted. The engine/plugin version lock is intentionally unresolved pending T001.

## Source of truth

`AGENTS.md` owns agent rules. `PLAN.md` owns task progress. `DLOG.md` is the chronological activity record. `docs/CONTRACTS.md` owns cross-module agreements. `docs/CODE_GUIDE.md` maps code to plain-English explanations. Task cards own individual implementation instructions. Do not duplicate these responsibilities.

Sources checked when this pack was prepared are in [docs/SOURCES.md](docs/SOURCES.md). Proposed defaults are distinguished from the user's confirmed requirements in [docs/DECISIONS.md](docs/DECISIONS.md).

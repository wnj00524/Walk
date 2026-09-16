# Decisions and deliberately unresolved questions

Do not present proposed defaults as user-confirmed choices.

| ID | Decision | Basis / state | Change rule |
| --- | --- | --- | --- |
| D01 | Walking through a procedurally extending, beautiful, realistic natural world; no other game mechanics | User requirement | Owner decision |
| D02 | Maximise agentic development; explain code for a non-technical reader; support smaller coding agents | User requirement | Owner decision |
| D03 | No manual Blender workflow; no `.blend` runtime/import dependency | Derived implementation constraint from user preference | Owner decision |
| D04 | Meshy and ElevenLabs available; other development dependencies FOSS | User requirement; intended non-commercial use confirmed within terms | Do not reopen licensing discussion without a new issue |
| D05 | Windows desktop, offline after installation; first-person view | Proposed default based on the preceding plan | Record any owner change here |
| D06 | Godot 4, typed GDScript application glue, Python standard-library tooling | Proposed architecture | Coordinator review with reasons |
| D07 | Voxel Tools smooth terrain using prebuilt compatible binaries | Candidate, not a validated dependency | T001 pins candidate; T012 must accept/reject backend |
| D08 | No native C++ development, custom engine compilation, hand-edited terrain, or custom mesher in ordinary tasks | Agent-complexity control | Separate architecture decision required |
| D09 | One temperate forest/meadow/upland palette; fixed initial light and weather | Initial scope proposal | Expand only after visual gate |
| D10 | No runtime network access, API credentials or asset generation | Product/runtime boundary | Owner and architecture review |
| D11 | 256-metre logical location cells; logical coordinates separate from renderer coordinates | Specified contract, not a plugin chunk size | Versioned contract change before implementation |
| D12 | Exact Godot/plugin versions, coordinate strategy, terrain material API, tested draw distance | Unresolved until compatibility/probe tasks | Evidence required, not guesses |
| D13 | Suggested 1080p/60 FPS target; proposed bounded-memory test tolerances | Provisional targets, hardware not supplied | Record test hardware before performance gate |
| D14 | Assets are downloaded once, inspected by scripts and visual review, then packaged locally | Asset-pipeline design | No bulk regeneration without budget approval |

## Backend rejection procedure

If prebuilt Voxel Tools cannot meet exported-build, streaming, coordinate or scriptability requirements, stop dependent work. Record the failed probe and a small comparison of alternatives. A coordinator may propose a streamed heightfield adapter behind the same boundary, but must create a separate decision and bounded spike before implementation. Do not quietly substitute a finite landscape, install a proprietary engine, or ask a small implementation agent to invent a terrain engine.

## Future change records

Append a dated decision with context, chosen option, rejected option, affected contracts/tests and migration implications. Preserve the original decision history. Task status remains in PLAN.md, not here.

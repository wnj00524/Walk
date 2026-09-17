# Development plan - sole task-status authority

## Product and working method

Create an offline Windows first-person nature walk through a realistic-looking, seeded, procedurally extending wilderness. Meshy/ElevenLabs provide reviewed development-time assets. Other tools are FOSS. No Blender/manual scene assembly or extra game mechanics.

Start with one temperate landscape palette. Every implemented feature is explained for a non-technical reader. Implementation tasks are small enough to hand to a lower-capability coding agent without asking it to invent the architecture.

## Current position

This delivery contains documentation, independent fixtures and tested documentation/briefing helpers only. No game, service client or engine integration has been built. Start with T001. The toolchain lock is a candidate record to be established, not a known working stack.

## Milestones and exit decisions

| Milestone | Main tasks | Evidence required before advancing |
| --- | --- | --- |
| M0 - reproducible foundation | T001-T004 | Exact prebuilt candidate, project import, tests that fail correctly, working check command |
| M1 - viable walking/streaming backend | T005-T012, T012a | Real smooth terrain, collision, actual coordinate strategy and Windows exported prototype; explicit backend acceptance |
| M2 - persistent and inspectable world | T013-T015 | Resume, deterministic/seam regressions and repeatable GPU captures |
| M3 - asset pipeline without manual editing | T016-T019 | Offline tests, spend controls, representative real assets approved in engine |
| M4 - first beautiful procedural slice | T020-T024 | Reproducible landforms/placement, bounded vegetation, coherent materials, owner visual acceptance |
| M5 - complete nature walk | T025-T033 | Reviewed local sound, basin/lake, safe comfort controls, restrained wind and resilient saves |
| M6 - offline release evidence | T034-T036 | Actual Windows build, measured sustained travel, owner acceptance of the full walk |

Milestones describe outcomes, not time estimates. Asset-client work can be prepared while engine work is reviewed, but start serially and obey dependency records. Do not spend on a large asset catalogue before the representative proof and backend acceptance.

## Status rules

Allowed states: WAITING, READY, ACTIVE, REVIEW, BLOCKED, DONE. Only the coordinator makes a task READY after its dependencies are DONE and its unknowns are resolved. Implementers submit REVIEW or BLOCKED; a separate review pass accepts DONE. A successful investigation of an unsuitable technology does not pass the backend gate. Missing GPU/Windows/live-asset evidence stays explicit.

Task cards contain full dependencies and scope. Later WAITING cards must be refined using actual earlier API/probe results before dispatch. Split any task that exceeds the five-file/~300-executable-line default. No one must implement all 36 cards in a single session.

## Task register

| ID | Task | State |
| --- | --- | --- |
| T001 | Record a compatible prebuilt toolchain candidate | DONE |
| T002 | Create a minimal Godot project shell | DONE |
| T003 | Create a tiny test runner that fails correctly | DONE |
| T004 | Add a reproducible game-check command | DONE |
| T005 | Implement comfortable basic first-person movement | DONE |
| T006 | Implement logical world positions | DONE |
| T007 | Implement deterministic discrete world choices | DONE |
| T008 | Load the terrain add-on and verify its actual API | DONE |
| T009 | Build one script-defined smooth streamed terrain probe | DONE |
| T010 | Probe large-distance identity and coordinate handling | DONE |
| T011 | Freeze the terrain adapter contract from probe evidence | DONE |
| T012 | Accept or reject the terrain foundation | BLOCKED |
| T012a | Prove a GDScript chunked-heightmap terrain spike | DONE |
| T013 | Save and resume the basic walker state | DONE |
| T014 | Add deterministic terrain and seam regression tests | DONE |
| T015 | Create repeatable GPU scene captures | DONE |
| T016 | Define and validate the asset request registry | DONE |
| T017 | Implement a resumable Meshy client with offline tests | DONE |
| T018 | Script the GLB import and technical asset report | DONE |
| T019 | Generate and approve a tiny representative asset batch | BLOCKED |
| T020 | Create the first configurable landform recipe | WAITING |
| T021 | Generate deterministic plant and rock placement data | WAITING |
| T022 | Render bounded spatial vegetation batches | WAITING |
| T023 | Set consistent terrain materials and daylight | WAITING |
| T024 | Accept the first procedural visual-quality slice | WAITING |
| T025 | Implement a guarded ElevenLabs sound client | WAITING |
| T026 | Produce and approve a small ambience library | WAITING |
| T027 | Add layered local environmental sound | WAITING |
| T028 | Define and generate one safe lake-basin recipe | WAITING |
| T029 | Render bounded lake surfaces | WAITING |
| T030 | Finish safe walking and basic comfort controls | WAITING |
| T031 | Add restrained vegetation motion | WAITING |
| T032 | Harden saves and version/error handling | WAITING |
| T033 | Expose quality budgets and bounded cache controls | WAITING |
| T034 | Build and run a fully offline Windows package | WAITING |
| T035 | Measure long-walk continuity and performance | WAITING |
| T036 | Accept the first complete nature walk | WAITING |

## After first acceptance, not before

New climate regions, dynamic weather, day/night, seasons, regional-drainage rivers and wildlife visuals need their own design/asset/performance tasks. They are not authorised by the current task register. Do not add objectives, survival or combat by treating the experience as an unfinished conventional game.

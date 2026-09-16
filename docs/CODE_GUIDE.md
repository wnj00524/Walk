# What each implemented part does

This index describes only code actually included now. Intended game modules are described separately in ARCHITECTURE.md.

| File | Ordinary-language purpose | Safe adjustments | Checks |
| --- | --- | --- | --- |
| tools/project.py | Checks the plan/task records and prints a small assignment for one agent | Brief byte limit, with care; do not weaken dependency checks | `python -m unittest discover -s tools -p "test_*.py"` |
| tools/test_project.py | Tests the helper itself using temporary copies and intentionally bad records | Add new failure examples; do not delete inconvenient assertions | Same command |
| fixtures/seed_vectors.json | Fixed examples of seed-based choices for future game tests | Do not regenerate to hide an implementation mismatch | T007 consumes these in Godot |
| fixtures/coordinate_vectors.json | Fixed examples of positive/negative map positions | Add independent examples without changing existing expectations | T006 consumes these in Godot |
| docs/toolchain.lock.json | Pinned toolchain candidate versions, download URLs, and SHA-256 hashes | Candidate versions require matching checksums; see [docs/features/setup.md](features/setup.md) | `python tools/project.py validate` |
| game/project.godot | Tells Godot which scene starts and sets the prototype window and renderer | Development window size; keep the main-scene path stable | `godot --headless --path game --editor --quit` |
| game/scenes/main.tscn | Draws the plain prototype title and not-yet-built notice | Label wording, colours, font sizes, and layout | Launch with `godot --path game` and inspect the window |
| game/src/app/main.gd | Turns a window-close request into an orderly application exit | Add startup behaviour only in its assigned task | Launch, close the window, and confirm exit code 0 |

Feature walkthroughs:
- [Toolchain and Environment Setup](features/setup.md)
- [Minimal Godot Project Shell](features/project-shell.md)

The minimal game shell is implemented, but terrain, walking, asset clients, and game test wrappers are not. As tasks add them, update this index without implying that planned files already work.

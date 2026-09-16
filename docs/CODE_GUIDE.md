# What each implemented part does

This index describes only code actually included now. Intended game modules are described separately in ARCHITECTURE.md.

| File | Ordinary-language purpose | Safe adjustments | Checks |
| --- | --- | --- | --- |
| tools/project.py | Checks the plan/task records and prints a small assignment for one agent | Brief byte limit, with care; do not weaken dependency checks | `python -m unittest discover -s tools -p "test_*.py"` |
| tools/test_project.py | Tests the helper itself using temporary copies and intentionally bad records | Add new failure examples; do not delete inconvenient assertions | Same command |
| fixtures/seed_vectors.json | Fixed examples of seed-based choices for future game tests | Do not regenerate to hide an implementation mismatch | T007 consumes these in Godot |
| fixtures/coordinate_vectors.json | Fixed examples of positive/negative map positions | Add independent examples without changing existing expectations | T006 consumes these in Godot |
| docs/toolchain.lock.json | Pinned toolchain candidate versions, download URLs, and SHA-256 hashes | Candidate versions require matching checksums; see [docs/features/setup.md](features/setup.md) | `python tools/project.py validate` |

Feature walkthroughs:
- [Toolchain and Environment Setup](features/setup.md)

No game source, terrain backend, asset clients or test wrappers have been implemented in this pack. As tasks add them, update this index with links to actual feature walkthroughs, without implying that planned files already work.

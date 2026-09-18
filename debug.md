# Command ledger

## 2026-09-18 — T024a recovery

### Pending

- Command: `git status --short --untracked-files=all`
- Purpose: inspect changes and generated import byproducts left by the interrupted regression batch.
- Status: FAILED
- Result: `fatal: not a git repository (or any of the parent directories): .git`

### Pending

- Command: `git -C "C:\\Users\\jdwil\\source\\repos\\Codex\\Walk" status --short --untracked-files=all`
- Purpose: inspect the repository and identify changes left by the interrupted regression batch.
- Status: COMPLETED
- Result: exit code 0; T024a source/task files are modified and Godot import/JPG/UID byproducts are untracked.

### Pending

- Command: `python tools/check_game.py --suite visual_preset`
- Purpose: run the focused visual-preset regression check for T024a.
- Status: NOT RUN

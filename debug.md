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
- Status: FAILED
- Result: exit code 2; Python resolved the script as `C:\\tools\\check_game.py`, which does not exist.

### Pending

- Command: `python "C:\\Users\\jdwil\\source\\repos\\Codex\\Walk\\tools\\check_game.py" --suite visual_preset`
- Purpose: run the focused visual-preset regression check using an explicit repository script path.
- Status: FAILED
- Result: exit code 1; prerequisite lookup reported `Godot prerequisite missing; set GODOT_BIN or install godot on PATH`.

### Pending

- Command: `$env:GODOT_BIN = "C:\\Users\\jdwil\\scoop\\shims\\godot.EXE"; python "C:\\Users\\jdwil\\source\\repos\\Codex\\Walk\\tools\\check_game.py" --suite visual_preset`
- Purpose: run the focused visual-preset regression check with the known Godot executable path.
- Status: FAILED
- Result: exit code 1; Godot version probe exited 127, expected `4.6.2.stable.official.71f334935`; log: `artifacts/check_game_20260918-095804_version.log`.

### Pending

- Command: `Get-Content "C:\\Users\\jdwil\\source\\repos\\Codex\\Walk\\artifacts\\check_game_20260918-095804_version.log"`
- Purpose: inspect the exact Godot version-probe failure before selecting a safe invocation.
- Status: COMPLETED
- Result: exit code 0; log shows `godot.EXE --version` failed with `[WinError 5] Access is denied`.

### Pending

- Command: `$env:GODOT_BIN = "C:\\Users\\jdwil\\scoop\\shims\\godot.EXE"; python "C:\\Users\\jdwil\\source\\repos\\Codex\\Walk\\tools\\check_game.py" --suite visual_preset`
- Purpose: rerun the focused visual-preset regression check with filesystem/process access elevated for Godot.
- Status: COMPLETED
- Result: exit code 0; suite executed 5, passed 5, failed 0. Logs: `artifacts/check_game_20260918-095921_import.log`, `artifacts/check_game_20260918-095921_suite_visual_preset.log`.

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

### Pending

- Command: `$env:GODOT_BIN = "C:\\Users\\jdwil\\scoop\\shims\\godot.EXE"; python "C:\\Users\\jdwil\\source\\repos\\Codex\\Walk\\tools\\run_visual.py" --output-dir "C:\\Users\\jdwil\\source\\repos\\Codex\\Walk\\artifacts\\T024a_visual_capture" --timeout 180`
- Purpose: capture the fixed-seed visual evidence after the vegetation grouping revision.
- Status: COMPLETED
- Result: exit code 0; validated 4 captures and `capture_report.json`. Log: `artifacts/T024a_visual_capture/godot_capture.log`.

### Pending

- Command: `Get-ChildItem -LiteralPath "C:\\Users\\jdwil\\source\\repos\\Codex\\Walk\\artifacts\\T024a_visual_capture" -File | Select-Object -ExpandProperty FullName`
- Purpose: enumerate the generated PNG evidence files before visual inspection.
- Status: COMPLETED
- Result: exit code 0; four PNGs plus `capture_report.json` and `godot_capture.log` were generated.

### Pending

- Command: `Get-Content "C:\\Users\\jdwil\\source\\repos\\Codex\\Walk\\artifacts\\T024a_visual_capture\\capture_report.json"; Get-Content "C:\\Users\\jdwil\\source\\repos\\Codex\\Walk\\artifacts\\T024a_visual_capture\\godot_capture.log"`
- Purpose: inspect rendered-instance counts and Godot asset-loading diagnostics for the sparse PNG result.
- Status: COMPLETED
- Result: exit code 0; report shows world seed 42, 299 rendered instances, 9 resident batches, no vegetation error, RTX 2060/OpenGL compatibility. Log contains no asset-load errors.

### Pending

- Command: `git -C "C:\\Users\\jdwil\\source\\repos\\Codex\\Walk" status --short --untracked-files=all; git -C "C:\\Users\\jdwil\\source\\repos\\Codex\\Walk" diff -- game/src/presentation/vegetation_batches.gd game/data/asset_catalogue.json game/data/habitats.json game/tests/visual_capture.gd`
- Purpose: inspect the current T024a diff and the asset-instantiation/capture configuration before editing.
- Status: COMPLETED
- Result: exit code 0; only habitat density/grouping and placement test changes are pending. Asset-instantiation source is unchanged; generated Godot import byproducts remain untracked.

### Pending

- Command: `Get-Content "C:\\Users\\jdwil\\source\\repos\\Codex\\Walk\\game\\src\\presentation\\vegetation_batches.gd"; Get-Content "C:\\Users\\jdwil\\source\\repos\\Codex\\Walk\\game\\data\\asset_catalogue.json"; Get-Content "C:\\Users\\jdwil\\source\\repos\\Codex\\Walk\\game\\tests\\visual_capture.gd"`
- Purpose: read the complete asset load, catalogue, and capture implementation to identify the material presentation defect.
- Status: COMPLETED
- Result: exit code 0; assets are loaded via `load(res://assets/initial/*.glb)` and instantiated as Node3D scenes. Capture uses the same path and has no fallback material.

### Pending

- Command: `Get-Content "C:\\Users\\jdwil\\source\\repos\\Codex\\Walk\\game\\tests\\tools\\inspect_asset.gd"; Get-Content "C:\\Users\\jdwil\\source\\repos\\Codex\\Walk\\game\\tests\\test_vegetation_batches.gd"`
- Purpose: inspect the existing asset geometry/material diagnostics and vegetation assertions before changing runtime presentation.
- Status: COMPLETED
- Result: exit code 0; fixture reports mesh counts/bounds but does not yet assert material textures; runtime test only asserts at least one instance.

### Pending

- Command: `rg --files "C:\\Users\\jdwil\\source\\repos\\Codex\\Walk\\game\\tests\\tools" "C:\\Users\\jdwil\\source\\repos\\Codex\\Walk\\game\\tests" | rg "inspect_asset|tscn$"`
- Purpose: locate the asset-inspection scene before running geometry/material diagnostics.
- Status: COMPLETED
- Result: exit code 0; inspection scene is `game/tests/tools/asset_review.tscn`.

### Pending

- Command: `$godot = "C:\\Users\\jdwil\\scoop\\shims\\godot.EXE"; foreach ($asset in @("tree_textured_01.glb", "rock_textured_01.glb", "groundcover_textured_01.glb")) { & $godot --path "C:\\Users\\jdwil\\source\\repos\\Codex\\Walk\\game" --scene res://tests/tools/asset_review.tscn -- res://assets/initial/$asset }`
- Purpose: inspect all approved GLB meshes through Godot's real importer and capture their reported geometry/material readiness.
- Status: COMPLETED
- Result: exit code 0; all three assets import as one MeshInstance3D with finite bounds (tree 1.06×2.00×1.05 m, rock 1.87×0.86×2.00 m, groundcover 2.00×0.99×1.89 m), no Blender dependency.

### Pending

- Command: `rg -n "StandardMaterial|albedo_texture|texture|material" "C:\\Users\\jdwil\\source\\repos\\Codex\\Walk\\game\\.godot\\imported\\tree_textured_01.glb-0c64f05a22b6b612b1b792214a182147.scn" "C:\\Users\\jdwil\\source\\repos\\Codex\\Walk\\game\\.godot\\imported\\rock_textured_01.glb-df50e526d6c6dd363f7d5904952c0ec3.scn" "C:\\Users\\jdwil\\source\\repos\\Codex\\Walk\\game\\.godot\\imported\\groundcover_textured_01.glb-27f530dce05a0c793b58ec563809baf3.scn"`
- Purpose: verify whether imported GLB scenes contain material texture bindings or only untextured geometry.
- Status: COMPLETED
- Result: exit code 1; no text material bindings were found in the imported `.scn` resources. This is inconclusive because Godot stores the imported scene resources in a non-text-readable form here.

### Pending

- Command: `$env:GODOT_BIN = "C:\\Users\\jdwil\\scoop\\shims\\godot.EXE"; python "C:\\Users\\jdwil\\source\\repos\\Codex\\Walk\\tools\\check_game.py" --suite vegetation`
- Purpose: verify vegetation lifecycle and approved-asset rendering after assigning each batch its cell-world origin.
- Status: COMPLETED
- Result: exit code 0; suite executed 5, passed 5, failed 0. Logs: `artifacts/check_game_20260918-102104_import.log`, `artifacts/check_game_20260918-102104_suite_vegetation.log`.

### Pending

- Command: `$env:GODOT_BIN = "C:\\Users\\jdwil\\scoop\\shims\\godot.EXE"; python "C:\\Users\\jdwil\\source\\repos\\Codex\\Walk\\tools\\run_visual.py" --output-dir "C:\\Users\\jdwil\\source\\repos\\Codex\\Walk\\artifacts\\T024a_visual_capture" --timeout 180`
- Purpose: regenerate fixed-seed PNG evidence after placing vegetation batches at their correct world-cell origins.
- Status: COMPLETED
- Result: exit code 0; validated 4 captures and refreshed `capture_report.json`/`godot_capture.log`.

### Pending

- Command: `Get-Content "C:\\Users\\jdwil\\source\\repos\\Codex\\Walk\\game\\src\\world\\placement_rules.gd"; Get-Content "C:\\Users\\jdwil\\source\\repos\\Codex\\Walk\\game\\data\\visual_route.json"`
- Purpose: verify how density/cluster settings become world positions and whether the fixed capture route actually crosses populated cells.
- Status: COMPLETED
- Result: exit code 0; records are correctly clustered within 256 m cells, while the route's overview/ground views are 232–360 m from the target and the close view is 55 m high. The route is too distant/high to prove asset appearance.

### Pending

- Command: `Get-Content "C:\\Users\\jdwil\\source\\repos\\Codex\\Walk\\tasks\\T024a.md"`
- Purpose: confirm the T024a write scope before adding a closer fixed-seed visual route.
- Status: COMPLETED
- Result: exit code 0; T024a explicitly forbids renderer and route changes. The batch-world-origin correction is therefore outside this task and was reverted.

### Pending

- Command: `rg -n -C 4 "T024a|T024" "C:\\Users\\jdwil\\source\\repos\\Codex\\Walk\\PLAN.md" "C:\\Users\\jdwil\\source\\repos\\Codex\\Walk\\DLOG.md"`
- Purpose: locate the current T024a status row and the latest chronological log position before recording the blocker.
- Status: COMPLETED
- Result: exit code 0; T024a remains READY and T024 remains BLOCKED. Latest DLOG entry is the coordinator split to T024a.

### Pending

- Command: `Get-Content "C:\\Users\\jdwil\\source\\repos\\Codex\\Walk\\docs\\CODE_GUIDE.md"; Get-Content "C:\\Users\\jdwil\\source\\repos\\Codex\\Walk\\docs\\features\\placement-rules.md"`
- Purpose: inspect the documentation locations that must explain the T024a density/grouping revision.
- Status: COMPLETED
- Result: exit code 0; CODE_GUIDE includes the habitat budget entry and placement walkthrough is the correct feature doc.

### Pending

- Command: `python "C:\\Users\\jdwil\\source\\repos\\Codex\\Walk\\tools\\project.py" validate`
- Purpose: validate the updated PLAN/DLOG/task records and documentation evidence metadata.
- Status: COMPLETED
- Result: exit code 0; 38 task records and plan structure checked. Game/runtime not tested by this command.

### Pending

- Command: `git -C "C:\\Users\\jdwil\\source\\repos\\Codex\\Walk" diff --check`
- Purpose: verify whitespace integrity across the T024a implementation and evidence changes before committing them.
- Status: NOT RUN

### Pending

- Command: `rg -n "groundcover|rock_textured|tree_textured|habitats|asset|material|texture" "C:\\Users\\jdwil\\source\\repos\\Codex\\Walk\\game\\data" "C:\\Users\\jdwil\\source\\repos\\Codex\\Walk\\game\\src" "C:\\Users\\jdwil\\source\\repos\\Codex\\Walk\\game\\assets\\initial"`
- Purpose: trace the asset catalogue, habitat selection, and material/texture references behind the PNG instances.
- Status: NOT RUN

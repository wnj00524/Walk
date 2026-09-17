# Toolchain and development environment setup

## What the walker notices

At this stage, there is no interactive game to play yet. When the project foundation is fully established, this toolchain ensures the game engine, terrain add-ons, and export templates run reliably and reproducibly on Windows without requiring manual installation or compiling C++ source code.

## How it works, in ordinary language

The application foundation is built on three core components:
1. **Godot Engine 4 (Standard 64-bit Windows Editor)**: The runtime engine and scene editor that runs the game code and handles graphics, audio, and physics.
2. **Godot Export Templates**: Precompiled engine binaries used when packaging the game as a standalone Windows `.exe` application.
3. **Voxel Tools (GDExtension edition)**: A high-performance native add-on providing smooth voxel-based procedural terrain generation and streaming. Using the GDExtension edition means it plugs directly into the official Godot engine build as a project add-on folder (`addons/zylann.voxel/`), avoiding custom engine compilations.

All exact versions, official download URLs, SHA-256 cryptographic hashes, and platform artifacts are recorded in `docs/toolchain.lock.json` so that any development agent or reviewer can obtain the exact same binaries.

### Candidate records

| Component | Exact candidate version | Artifact name | Official download source | SHA-256 Checksum |
| --- | --- | --- | --- | --- |
| Godot Editor | `4.6.2-stable` official | `Godot_v4.6.2-stable_win64.exe.zip` | [Godot 4.6.2 release](https://github.com/godotengine/godot/releases/tag/4.6.2-stable) | `14293422efb54b24a51f79d4cb55ab4001ef3d936e064a6c8af32e1f984024be` |
| Export Templates | `4.6.2-stable` official | `Godot_v4.6.2-stable_export_templates.tpz` | [Godot 4.6.2 release](https://github.com/godotengine/godot/releases/tag/4.6.2-stable) | `942366dc4e27e7686a99da4d3cfb1b8ae8d3eb9444f6d8217eef16245b599ef2` |
| Voxel Tools | GDExtension `1.7` (tag `v1.7x`) | `GodotVoxelExtension.zip` | [Voxel Tools v1.7x release](https://github.com/Zylann/godot_voxel/releases/tag/v1.7x) | `600737572a5e25541ba6f503e842a3717ba19afafa5474510a6ceff995a1d2d8` |
| Python Tooling | Python `3.12.12` (minimum 3.10) | Standard Library only | [Python.org](https://www.python.org/) | N/A (Standard installation) |

## Which files own the behaviour

- `docs/toolchain.lock.json`: The machine-readable lock file specifying the pinned versions, download URLs, SHA-256 checksums, and verification status.
- `tools/project.py`: The plan validation and briefing helper script.
- `tools/test_project.py`: Unit tests validating plan consistency, task rules, and path boundaries.
- `docs/features/setup.md`: This feature walkthrough explaining the setup process and candidate parameters.

## Windows setup instructions

### 1. Acquiring Godot 4
1. Download `Godot_v4.6.2-stable_win64.exe.zip` from the official release URL.
2. Verify its SHA-256 hash matches `14293422efb54b24a51f79d4cb55ab4001ef3d936e064a6c8af32e1f984024be`.
3. Extract `Godot_v4.6.2-stable_win64.exe` to a known tools directory (or install via Scoop: `scoop install godot`).
4. Verify by running `godot --version` in terminal. It should report `4.6.2.stable.official.71f334935`.

### 2. Acquiring Voxel Tools GDExtension
1. Download `GodotVoxelExtension.zip` from release `v1.7x`.
2. Verify its SHA-256 hash matches `600737572a5e25541ba6f503e842a3717ba19afafa5474510a6ceff995a1d2d8`.
3. When the game project directory (`game/`) is created in subsequent tasks, unzip the archive contents directly into `game/` so that `game/addons/zylann.voxel/` is populated with `voxel.gdextension` and the platform binaries (`libvoxel.windows.editor.x86_64.dll`, etc.).

### 3. Python tooling environment
- Requires Python 3.10 or later (verified on Python 3.12.12).
- Uses only Python standard library modules (`hashlib`, `urllib.request`, `json`, `argparse`, `unittest`, `pathlib`). No pip packages required for project management tools.

## Safe settings to change

- `docs/toolchain.lock.json` versions: Any proposed change to candidate versions must be accompanied by new SHA-256 hashes, official release sources, and tested binary outputs.
- Target platforms: Cross-platform references for Linux and macOS are tracked for reference, but Windows x86_64 remains the primary supported target.

## Failure symptoms and where to look

- `godot --version` fails or returns command not found: Ensure Godot executable is added to the system `PATH` or invoke it using its full path.
- Checksum mismatch: If a downloaded archive does not match the recorded SHA-256 hash, the download was truncated or modified; re-download from the official GitHub release URL.
- Extension loading failure (future tasks): If Godot fails to load `voxel.gdextension` when opening the project in T008, verify that the DLLs in `addons/zylann.voxel/bin/` match the Godot architecture (Windows x86_64).

## How it is tested, with actual commands and known limitations

### Actual checks executed

1. **Python version**:
   ```pwsh
   python --version
   ```
   Result: `Python 3.12.12` (Exit 0).
2. **Godot Editor binary start**:
   ```pwsh
   godot --version
   ```
   Result: `4.6.2.stable.official.71f334935` (Exit 0).
3. **Checksum computation**:
   Computed SHA-256 hashes of the official archives directly from the official release download streams.
4. **Starter pack validation**:
   ```pwsh
   python tools/project.py validate
   ```
   Result: `PASS: 36 task records and plan structure checked.` (Exit 0).
5. **Project unit tests**:
   ```pwsh
   python -m unittest discover -s tools -p "test_*.py"
   ```
   Result: 25 tests ran, OK (Exit 0).

### Known limitations and unverified items

- **GDExtension runtime loading**: T008 verified the pinned Windows bundle in a headless Godot runtime and recorded its reflected API in [terrain-api.md](terrain-api.md). This does not accept the terrain backend or prove editor first-run stability.
- **Export templates**: The archive SHA-256 has been recorded, but export template installation and Windows binary packaging are owned by task T034.
- **Backend viability**: Candidate toolchain recording (T001) does not constitute acceptance of the Voxel Tools backend (T012).

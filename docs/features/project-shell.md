# Minimal Godot project shell

## What the walker notices

Launching the project opens a 960 by 540 window with the title **Endless Nature — Prototype** and a clear note that the landscape has not been built yet. Closing the window exits the application normally. This screen is only a foundation check, not placeholder scenery or a claim of visual quality.

## How it works, in ordinary language

Godot starts from the main scene named in `game/project.godot`. That scene fills the window with a dark neutral background and centers two labels. Its small startup script listens only for the operating system's window-close request and asks Godot to shut down cleanly. Everything uses built-in Godot controls, so this task has no terrain add-on or imported asset dependency.

## Which files own the behaviour

- `game/project.godot` owns the application name, initial window size, renderer choice, and main-scene path.
- `game/scenes/main.tscn` owns the visible background, prototype title, and status text.
- `game/src/app/main.gd` owns orderly handling of the window's close request.

## Safe settings to change, with units and suggested ranges

- The viewport and window override in `game/project.godot` are pixels. The current 960 by 540 size is intentionally modest; 800 by 450 through 1280 by 720 is a reasonable development range.
- Label text, font sizes (pixels), colours, and offsets in `game/scenes/main.tscn` are cosmetic. Keep the word “Prototype” and the not-yet-built status until a later accepted task replaces this shell.
- Do not change the main-scene path or renderer as a cosmetic adjustment; a bad path stops startup, and renderer changes need their own compatibility evidence.

## Failure symptoms and where to look

- If Godot says the main scene cannot be found, check `run/main_scene` in `game/project.godot` and the scene path.
- If the window opens without its labels, inspect resource and parse errors for `game/scenes/main.tscn`.
- If startup reports a script error, inspect `game/src/app/main.gd`. The project has no recovery screen at this foundation stage.

## How it is tested, with actual commands and known limitations

Import resources without opening a window:

```bash
godot --headless --path game --editor --quit
```

Launch the graphical application from the repository root:

```bash
godot --path game
```

The graphical check requires a display. Headless import proves that Godot can parse and import the project, but it does not prove what the window looks like or that a Windows executable runs. Exact results for this implementation session are retained in `docs/evidence/T002.md`.

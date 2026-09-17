# Comfortable first-person walking

## What the walker notices

The T005 prototype opens on a clearly labelled simple floor. WASD moves at a steady
3.2 metres per second, the mouse looks around, and the view cannot tip into an
uncomfortable near-vertical angle. Escape releases the cursor; clicking the window
captures it again.

## How it works, in ordinary language

The `Walker` is a Godot `CharacterBody3D`, which means the player has a collision
shape and moves through the physics system rather than teleporting the camera. Input
actions are named `walk_forward`, `walk_backward`, `walk_left`, and `walk_right`.
The prototype defines those actions when the player starts so this task does not
change shared project settings. Horizontal velocity is calculated in metres per
second and Godot applies it on each physics step, so travel distance does not depend
on the number of rendered frames. There is deliberately no gravity, jumping,
stamina, head bob, or terrain claim in this fixture.

## Which files own the behaviour

- `game/src/player/walker.gd` owns movement, mouse look, cursor capture, and comfort settings.
- `game/scenes/player.tscn` owns the capsule collision shape and eye-height camera.
- `game/scenes/main.tscn` owns the labelled test floor, daylight, start marker, and controls text.
- `game/tests/test_player.gd` owns deterministic settings, pitch, and time-scaling checks.
- `game/tests/run_tests.gd` registers the `player` suite.

## Safe settings to change

`walking_speed_mps` is a speed in metres per second; 2.0–5.0 is a comfortable first
adjustment range. `mouse_sensitivity_deg_per_pixel` is degrees per mouse pixel;
0.06–0.20 is a sensible range. The pitch limits are degrees and should stay inside
-89 to 89; keeping them near -75 and 75 avoids looking almost straight up or down.
Changing the capsule or camera height should be checked visually because it changes
body contact and eye level.

## Failure symptoms and where to look

If movement does not start, look for `Walker disabled` in the Godot output and check
the exported settings. If the cursor is visible, click the window; Escape is the
intentional release path. If the player clips into the floor or appears too high,
check the capsule height, collision-shape position, and test-floor collision shape.
The floor is a review fixture only and is not evidence that terrain is ready.

## How it is tested

Run `python tools/check_game.py --suite player` for the focused suite. It checks
valid and invalid settings, both pitch limits, and equal one-second travel at 60 and
120 physics steps. Also run `python tools/project.py validate` and the helper test
suite. A graphical check is still required: look left/right, walk past the start
marker, press Escape, and click to resume. Headless tests cannot prove visual comfort,
mouse feel, GPU performance, or a Windows export.

# Explain the code to a non-technical reader

## What good documentation makes possible

The owner should be able to open a source file and answer: What part of the experience does this control? Why is it separate? What information does it need? What might break? Which settings can be changed safely? They do not need to learn programming syntax to answer these questions.

## Required file opening

Use the language's normal documentation-comment format. Keep the explanation accurate as the implementation changes.

```gdscript
## Purpose: Remembers where the walker is, even far from the starting point.
## Why: Very large drawing coordinates can make nearby movement unstable.
## Reads: A numbered 256-metre map cell and the position within that cell.
## Writes: A normalised location; this file does not move scene objects.
## Safe changes: None of the cell-size or save-format rules are cosmetic.
## Failure: Rejects non-finite offsets rather than saving a broken location.
class_name WorldPosition
extends RefCounted
```

This is a documentation example, not an implemented class. A comment must not claim that coordinate normalisation alone fixes the terrain backend.

## Functions, settings and names

Document public functions, non-obvious private functions and exported settings. Explain inputs and outputs with units, assumptions and failure cases. Use names such as `walking_speed_mps`, `ready_collision_radius_m` and `wind_volume_db`, rather than `v`, `r` and `amount`. Do not leave important values as unexplained literals.

Explain why a step exists. Good: "Use floor here so positions just west of the origin belong to the western cell." Unhelpful: "Call floor." Comments should explain boundaries, ownership, threading, costs, deterministic behaviour and safety decisions rather than repeat every line.

Briefly define necessary technical terms on first use or link to GLOSSARY.md. It is acceptable to retain precise technical identifiers after explaining them. Do not replace precision with vague prose.

## Feature walkthroughs

Maintain `docs/CODE_GUIDE.md` as a compact index. When a feature is introduced, add `docs/features/<feature>.md` with these sections:

- What the walker notices.
- How it works, in ordinary language.
- Which files own the behaviour.
- Safe settings to change, with units and suggested ranges.
- Failure symptoms and where to look.
- How it is tested, with actual commands and known limitations.

Examples should follow a real action, such as "The player walks across a cell boundary" or "The application opens a saved world". Explain the information flow without requiring the reader to understand an abstract class diagram.

## Changes and acceptance

A change that affects behaviour updates comments, its feature walkthrough and CODE_GUIDE in the same task. A bug fix explains the old failure and the new safeguard. Do not write speculative explanations for unbuilt code as though it exists. Generated/vendor files are exempt from line-by-line commenting; document their source, regeneration process and ownership instead.

The reviewer should ask five questions: Can a non-programmer state the purpose? Are units and safe controls clear? Is error behaviour described? Does the explanation match the code? Can the owner find the relevant feature from CODE_GUIDE? A linter can check that headings exist; only review checks that the explanation is useful and true.

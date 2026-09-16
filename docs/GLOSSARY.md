# Plain-English glossary

**Agent:** a coding assistant allowed to inspect files, edit them and run tools.
**Coordinator:** the role that prepares and sequences one bounded piece of work.
**Contract:** an agreement about data, behaviour and failures between parts of the program.
**Deterministic:** the same supported inputs reproduce the same intended result.
**Seed:** a number/string that identifies one generated world.
**Chunk/block:** a bounded piece of terrain loaded or processed together; not necessarily a logical location cell.
**Logical cell:** a numbered 256-metre location square used to preserve world positions.
**Streaming:** loading nearby scenery and releasing distant detail as the walker moves.
**LOD / detail level:** a simpler representation of an object or terrain at a distance.
**Terrain adapter:** the small boundary that contains calls to the chosen terrain library.
**Voxel:** a sample in a three-dimensional terrain representation; it need not be drawn as a cube.
**Heightfield:** terrain described by one ground height per horizontal location.
**GDExtension:** a native Godot add-on, supplied as compatible platform-specific binaries.
**GLB:** a binary form of the glTF 3D asset format.
**PBR material:** a material described using properties such as roughness and metallic response.
**Headless:** running without a normal displayed game window; useful for tests, not proof of visual quality.
**Fixture:** a fixed test input or deliberately controlled test scene.
**Test double / mock:** a labelled substitute used in tests, such as a fake paid-service response.
**Regression:** a previously working behaviour broken by a later change.
**Smoke test:** a small check that basic startup or collaboration works.
**Artifact:** a produced file such as a log, screenshot or executable.
**Gate:** a decision point whose required evidence must pass before dependent work proceeds.
**Dry-run:** describe what would happen without making the real external change or paid request.
**Origin shifting:** keeping drawing coordinates near the camera while preserving the separate world identity.
**Schema/version:** the agreed structure and revision of saved data.
**FOSS:** free and open-source software; source availability and licence permissions matter, not just price.

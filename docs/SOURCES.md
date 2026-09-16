# Primary references

Checked 16 September 2026 for planning. Implementers must verify APIs against the version selected by T001 and record any changed assumptions. No third-party tutorial is an authority for an API signature. Sources establish tool capabilities, not that this unbuilt application has passed its tests.

- **S01 - Codex repository guidance:** https://developers.openai.com/codex/guides/agents-md (redirects to the official ChatGPT Learn guidance). Explains AGENTS.md discovery. This is why the root filename is uppercase.
- **S02 - Godot command-line use:** https://docs.godotengine.org/en/stable/tutorials/editor/command_line_tutorial.html . Documents headless import, script execution and export-template requirements.
- **S03 - Voxel Tools distribution:** https://voxel-tools.readthedocs.io/en/latest/getting_the_module/ . Distinguishes prebuilt module/GDExtension editions and compatibility/export considerations.
- **S04 - Voxel Tools performance:** https://voxel-tools.readthedocs.io/en/latest/performance/ . Explains the limitations of intensive GDScript voxel processing and native graph approaches.
- **S05 - Voxel generator threading:** https://voxel-tools.readthedocs.io/en/latest/api/VoxelGeneratorScript/ . Warns that generator callbacks run off the scene thread and describes sampling/detail-level contracts.
- **S06 - Voxel Tools overview:** https://voxel-tools.readthedocs.io/ . The project's own caution that it is technical and not a universal turnkey solution.
- **S07 - Meshy remesh:** https://docs.meshy.ai/en/api/remesh . Describes remesh jobs; current docs direct resizing/conversion to separate endpoints.
- **S08 - Meshy resize:** https://docs.meshy.ai/en/api/resize . Describes real-world dimension and origin controls.
- **S09 - Godot 3D imports:** https://docs.godotengine.org/en/stable/tutorials/assets_pipeline/importing_3d_scenes/index.html . Use GLB/glTF rather than an indirect Blender import dependency.
- **S10 - Godot mesh detail levels:** https://docs.godotengine.org/en/stable/tutorials/3d/mesh_lod.html . Automatic import LOD is a capability, not guaranteed visual acceptance.
- **S11 - ElevenLabs sound effects:** https://elevenlabs.io/docs/api-reference/text-to-sound-effects/convert . Documents sound generation and looping controls; verify current request/response details before implementation.
- **S12 - Gemini CLI context:** https://geminicli.com/docs/cli/gemini-md/ . Documents GEMINI.md and relative context imports. Other harnesses may load instructions differently.

No model benchmarks or claims that a particular "low" model can solve every task are assumed. The workflow is deliberately model-independent.

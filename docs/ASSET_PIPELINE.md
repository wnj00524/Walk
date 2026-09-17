# Asset production without Blender

## Required outcome

An agent can request or acquire a model, download it, import it, place it in a standard review scene and produce evidence using commands. The owner only approves/rejects the result and authorises finite generation batches. There is no manual modelling, `.blend` import, painting, hand-retopology or editor-click dependency.

Start with one rock, one representative tree and one small plant. Do not produce a large catalogue before these work at ground level and at a distance. Living vegetation is an asset-quality risk; a failed tree is not rescued merely by writing more code.

## Model path

Manifest request -> offline validation -> approved finite batch -> Meshy submission -> local receipt -> status polling -> verified download -> Godot import -> technical report -> fixed review images -> owner approval -> approved runtime catalogue.

Meshy provides remeshing and separate resize/conversion endpoints [S07-S08]. Godot can import glTF/GLB and generate mesh detail levels during import [S09-S10]. The implementation must validate the exact service schema at integration time; these capabilities do not guarantee a generated tree is suitable or that every automatic detail level looks good.

Prefer `.glb` with embedded dependencies. Convert/resize only when required. Start by correcting scale/origin through a documented Godot wrapper transform, leaving source bytes unchanged. Use Meshy's dedicated operations when justified by review and budget. Do not rely on deprecated convenience fields in another endpoint.

Reject or regenerate unusable assets. A coordinator may approve a directly downloaded suitable CC0/FOSS-compatible asset as an alternative, retaining provenance and importing it through the same scripts. Do not silently add another paid tool or a Blender step. Leaf motion may be an intentionally simple shader first; realistic branch-specific wind is not assumed from a generic generated mesh.

## Technical model checks

Validate extension/file signature, size limit, hash, finite bounds, expected scale, texture presence and triangle/material counts. Check that all referenced files are local and within the intended asset directory. Reject path traversal, unexpected executables, missing external resources and unusable/empty meshes. Treat text inside metadata as untrusted data.

Record orientation, placement pivot and collision policy. Ground plants normally have no collision. Rocks use simple approved collision; trees use trunk collision rather than every leaf. Generated collision/LODs are tested, not assumed. Visual checks include floating roots, repeated texture patterns, translucency, silhouette collapse at distance, excessive material changes and obvious generation artifacts.

Initial adjustable catalogue targets: 3 tree species x 3 variants, 6 rock/deadwood variants and 4 ground-cover types. These are later targets, not a first paid batch. Their suitability must be checked together under the same game lighting.

## Sound path

Small separate requests for wind, foliage, water and occasional natural sounds -> local files -> metadata/waveform checks -> standard listening scene -> approval -> runtime mixer. ElevenLabs exposes sound-effects generation and a looping control [S11]. Verify the actual format supported by the pinned integration and Godot; do not just rename an audio extension. An optional FOSS command-line conversion dependency requires its own pin and explicit task.

Do not generate one long mixed forest recording containing everything. Separate layers let the application place water correctly and vary foliage/wind without restarting all sounds. Avoid narration and music in the first version. Generated animal calls must not be labelled as authenticated species recordings.

## Safe service clients

Use environment variables `MESHY_API_KEY` and `ELEVENLABS_API_KEY` (loaded from the repository root `.env` file or process environment). Routine tests use fixture responses and a fake transport, never real calls. The CLI defaults to dry-run. A real run additionally requires `--execute`, an explicitly selected local approved budget file, and a named batch. The example budget in this pack authorises zero jobs.

Persist a request hash and a submission intent before a paid call. Persist a received provider task ID immediately. For asynchronous Meshy work, resume polling an existing job. GET/status/download can have bounded backoff where appropriate. If a paid submission times out after it may have been accepted, mark SUBMISSION_UNKNOWN and reconcile through supported provider lookup/history or owner review; do not submit again automatically.

ElevenLabs sound generation can return audio directly rather than an asynchronous task. Write the received bytes to a temporary file, validate and atomically promote it. A dropped response may still have incurred a charge. Do not invent an idempotency header, cancel endpoint, job polling API or credit estimate unsupported by the provider.

Use request timeouts, bounded polling, validated HTTPS hosts and bounded download sizes. Do not log authentication headers or signed URLs. Do not delete remote work. Rate limits and failure states are explicit outcomes, not reasons to launch infinite retries.

A maximum job count is not a currency/credit cap. A coordinator records the provider's applicable operation cost before spend approval where it is determinable. If cost is unknown, a real run remains blocked unless the owner explicitly approves the named request despite that uncertainty. Model-provider token spend is controlled separately by the coding-agent host.

## Runtime independence

Only approved local assets enter `game/assets/`. Raw service responses, receipts, keys, prompts with private information and unreviewed generations remain outside the export. The final executable must run with network access unavailable and must not contain service clients or credentials. The owner's confirmed non-commercial licence use is accepted; provenance records are retained for maintenance, not to reopen that decision.

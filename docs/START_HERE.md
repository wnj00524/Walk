# Start here: an owner does not need to be a programmer

## Your job and the agents' jobs

Your job is to decide whether a walk looks and sounds right, approve small asset-generation batches, and choose when a build is acceptable. You should not need to model objects, manually assemble scenes, edit shaders or diagnose compiler errors.

The agents create text-based project files, scripts, tests, imports, builds and explanations. A coordinator chooses and prepares one task; an implementer does it; a reviewer checks it. These are separate passes, not necessarily separate products, subscriptions or concurrently running agents. A fresh session of the same affordable model can perform the review. Difficult architecture failures may need a more capable reviewer, but routine implementation must not depend on one being constantly available.

## Put this pack in a repository

Extract its contents into the root of a new repository. Do not blindly overwrite an existing project's AGENTS.md, PLAN.md or code. If using an existing repository, first assign a documentation-merge task and preserve existing work. No remote repository was modified when this pack was created.

Open your chosen coding agent in that repository. Give it `prompts/FIRST_TASK.md`. It should start at T001, identify a compatible prebuilt Godot/Voxel Tools candidate, and record what actually works in its environment. It must not claim to have built the game yet.

If Python is available, these optional commands show progress and prepare a bounded brief:

```powershell
python tools/project.py validate
python tools/project.py status
python tools/project.py brief T001
```

On Windows installations where `python` is unavailable but the Python launcher exists, use `py -3` in its place. Do not paste your Meshy or ElevenLabs keys into a prompt or commit them. Supply them through your agent environment's secret facility, or session environment variables entered locally. Asset spending starts disabled.

## The repeating development cycle

1. Ask the coordinator to make one dependency-satisfied task READY. It must resolve uncertain details or split the task first.
2. Start an implementation session using `prompts/IMPLEMENT_ONE_TASK.md` and that task ID.
3. Start a review session using `prompts/REVIEW_ONE_TASK.md`. It checks the actual changes and evidence.
4. At visual/audio checkpoints, open the supplied build and review the fixed sample walk. Decide accept/revise in ordinary language.

Start with serial work. Parallel work is optional only after interfaces are stable, in separate branches/worktrees with disjoint files. One coordinator reconciles PLAN.md and DLOG.md; do not let several agents overwrite the same progress table.

## What to look for in every handoff

The report should say what changed for you, what passed, what was not tested, how to see the result, and the next task. "The implementation is complete" without checks is not enough. A screenshot of a pretty scene is not proof of continuous streaming. A passing test is not proof of beauty.

If an agent repeatedly fails, use `prompts/RECOVER_BLOCKED_TASK.md`. It should preserve working changes and explain the specific blocker rather than start the application again from scratch.

## Three approvals that remain deliberately human

Approve a tiny initial asset batch, approve the first convincing ground-level scene, and approve the final nature walk. You may give feedback such as "the trees look plastic", "the ground repeats too obviously" or "water is too loud". The coordinator must translate that into one measurable revision task at a time.

## Read the status labels

WAITING means prerequisites or specification are not ready. READY means implementation may start. ACTIVE means one implementer owns the task. REVIEW means implementation evidence is ready for checking. BLOCKED means a named obstacle remains. DONE means a separate review accepted the required evidence. These describe individual tasks; a DONE test harness is not a finished game.

The included tools only check documentation/task structure and prepare briefs. They neither operate a coding agent nor guarantee compliance with the rules. Host-side permissions, sandboxing, spend controls and review remain necessary.

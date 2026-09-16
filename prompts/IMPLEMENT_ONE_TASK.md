Work on task <TASK_ID> only. Replace that placeholder with one actual READY task before starting.

Read AGENTS.md, README.md, PLAN.md and recent DLOG rows. Run `python tools/project.py brief <TASK_ID>` and inspect the listed actual source/contract files. Confirm dependencies, permitted files, expected behaviour and available checks in no more than six lines.

Implement the smallest change satisfying the card. Do not alter architecture, dependencies, expected fixtures or adjacent features. Explain authored code for the non-technical owner and update its feature walkthrough/CODE_GUIDE. Run focused and affected regression checks, keeping actual exit codes/counts and accessible evidence.

After two failed focused repairs or any unresolved contract/scope/spend/environment issue, stop and record a precise blocker. Otherwise submit REVIEW with the required handoff. Append one DLOG row. Do not mark DONE, merge, or begin the next task.

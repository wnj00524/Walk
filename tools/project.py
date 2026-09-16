#!/usr/bin/env python3
"""Check the project plan and prepare a small assignment for one coding agent.

Purpose: Help the owner hand over one well-defined task without copying the repo.
Reads: Markdown rules, task metadata and the single status table in PLAN.md.
Writes: Nothing; output goes to the terminal. No network or paid service is used.
Safe changes: The brief size limit may be adjusted. Do not weaken status checks.
Limit: This checks record structure, not game behaviour, security or code quality.
"""
from __future__ import annotations

import argparse
from dataclasses import dataclass
import json
from pathlib import Path, PurePosixPath
import re
import sys
from typing import Any

STATES = {'WAITING', 'READY', 'ACTIVE', 'REVIEW', 'BLOCKED', 'DONE'}
TASK_ID = re.compile(r'T\d{3}\Z')
SECTIONS = ('Outcome', 'Read set', 'Allowed changes', 'Steps', 'Acceptance',
            'Non-goals', 'Stop conditions')
DEFAULT_ROOT = Path(__file__).resolve().parents[1]


class PlanError(ValueError):
    """A plan record cannot safely be used to prepare an assignment."""


@dataclass(frozen=True)
class Task:
    """One card's fixed instructions; its changing status lives only in PLAN.md."""
    id: str
    role: str
    depends_on: tuple[str, ...]
    read: tuple[str, ...]
    write: tuple[str, ...]
    text: str


def safe_path(root: Path, relative: str) -> Path:
    """Resolve a repository path, refusing outside paths and escaping symlinks.

    This is a record-safety check, not a sandbox for an agent's own commands.
    """
    candidate = PurePosixPath(relative)
    if (not relative or candidate.is_absolute() or '..' in candidate.parts
            or '\\' in relative or ':' in relative or relative == '.'):
        raise PlanError(f'Not a confined repository path: {relative!r}')
    resolved = (root / relative).resolve()
    if not resolved.is_relative_to(root.resolve()):
        raise PlanError(f'Path escapes the repository: {relative!r}')
    return resolved


def read_text(root: Path, relative: str) -> str:
    """Read a required UTF-8 file and turn missing/unreadable files into a clear error."""
    try:
        return safe_path(root, relative).read_text(encoding='utf-8')
    except (OSError, UnicodeError) as exc:
        raise PlanError(f'Cannot read {relative}: {exc}') from exc


def plan_states(root: Path) -> dict[str, str]:
    """Read the only task-status table; reject duplicate or malformed task rows."""
    states: dict[str, str] = {}
    for line in read_text(root, 'PLAN.md').splitlines():
        if not re.match(r'^\|\s*T\d', line):
            continue
        cells = [cell.strip() for cell in line.strip().strip('|').split('|')]
        if len(cells) != 3 or not TASK_ID.fullmatch(cells[0]):
            raise PlanError(f'Malformed task row: {line}')
        task_id, _title, state = cells
        if task_id in states:
            raise PlanError(f'Duplicate PLAN task: {task_id}')
        if state not in STATES:
            raise PlanError(f'Unknown state for {task_id}: {state}')
        states[task_id] = state
    if not states:
        raise PlanError('PLAN.md contains no task rows.')
    return states


def load_task(root: Path, task_id: str) -> Task:
    """Read the card's JSON metadata and required human-readable instruction sections."""
    if not TASK_ID.fullmatch(task_id):
        raise PlanError(f'Invalid task ID: {task_id!r}; expected T001-style ID.')
    text = read_text(root, f'tasks/{task_id}.md')
    match = re.search(r'^```json\s*\n(.*?)\n```', text, re.M | re.S)
    if not match:
        raise PlanError(f'{task_id}: missing JSON metadata block.')
    try:
        record: Any = json.loads(match.group(1))
    except json.JSONDecodeError as exc:
        raise PlanError(f'{task_id}: invalid metadata JSON: {exc.msg}') from exc
    if not isinstance(record, dict):
        raise PlanError(f'{task_id}: metadata must be an object.')
    required = {'id', 'role', 'depends_on', 'read', 'write'}
    if set(record) != required:
        raise PlanError(f'{task_id}: metadata keys must be {sorted(required)}.')
    if record['id'] != task_id or not isinstance(record['role'], str) or not record['role']:
        raise PlanError(f'{task_id}: wrong ID or missing role.')
    for name in ('depends_on', 'read', 'write'):
        value = record[name]
        if not isinstance(value, list) or any(not isinstance(x, str) for x in value):
            raise PlanError(f'{task_id}: {name} must be a list of strings.')
        if len(value) != len(set(value)):
            raise PlanError(f'{task_id}: duplicate entry in {name}.')
    if not record['write']:
        raise PlanError(f'{task_id}: no authorised write paths.')
    for heading in SECTIONS:
        if not re.search(rf'^## {re.escape(heading)}\s*$', text, re.M):
            raise PlanError(f'{task_id}: missing section {heading}.')
    for path in record['read'] + record['write']:
        safe_path(root, path)
    return Task(task_id, record['role'], tuple(record['depends_on']),
                tuple(record['read']), tuple(record['write']), text)


def validate(root: Path) -> list[str]:
    """Return structural errors; an empty list says nothing about whether the game works."""
    errors: list[str] = []
    for path in ('AGENTS.md', 'README.md', 'PLAN.md', 'DLOG.md', 'GEMINI.md',
                 'docs/CONTRACTS.md', 'docs/CODE_GUIDE.md'):
        try:
            read_text(root, path)
        except PlanError as exc:
            errors.append(str(exc))
    try:
        states = plan_states(root)
    except PlanError as exc:
        return errors + [str(exc)]
    cards: dict[str, Task] = {}
    for task_id in states:
        try:
            cards[task_id] = load_task(root, task_id)
        except PlanError as exc:
            errors.append(str(exc))
    actual = {p.stem for p in (root / 'tasks').glob('T[0-9][0-9][0-9].md')}
    for orphan in sorted(actual - set(states)):
        errors.append(f'{orphan}: card has no PLAN.md row.')
    for task_id, card in cards.items():
        for dependency in card.depends_on:
            if dependency not in states:
                errors.append(f'{task_id}: unknown dependency {dependency}.')
            elif states[task_id] in {'READY', 'ACTIVE', 'REVIEW', 'DONE'} and states[dependency] != 'DONE':
                errors.append(f'{task_id}: dependency {dependency} is not DONE.')
        if states[task_id] in {'READY', 'ACTIVE', 'REVIEW', 'DONE'}:
            for path in card.read:
                if not safe_path(root, path).is_file():
                    errors.append(f'{task_id}: required ready-task context is missing: {path}.')
        if states[task_id] == 'DONE' and not (root / 'docs/evidence' / f'{task_id}.md').is_file():
            errors.append(f'{task_id}: DONE requires a retained evidence summary.')

    # A cycle means no valid ordering can satisfy the affected tasks.
    visiting: set[str] = set()
    visited: set[str] = set()

    def visit(task_id: str) -> None:
        """Walk dependency edges once and report impossible circular prerequisites."""
        if task_id in visiting:
            errors.append(f'Dependency cycle includes {task_id}.')
            return
        if task_id in visited or task_id not in cards:
            return
        visiting.add(task_id)
        for dep in cards[task_id].depends_on:
            visit(dep)
        visiting.remove(task_id)
        visited.add(task_id)

    for task_id in cards:
        visit(task_id)
    return errors


def make_brief(root: Path, task_id: str, inspect: bool = False,
               max_bytes: int = 24000) -> str:
    """Print one bounded handoff; waiting tasks are inspection-only, never implementation-ready."""
    errors = validate(root)
    if errors:
        raise PlanError('Fix plan structure first:\n' + '\n'.join(errors))
    states = plan_states(root)
    if task_id not in states:
        raise PlanError(f'Unknown task: {task_id}')
    task = load_task(root, task_id)
    state = states[task_id]
    if not inspect and state not in {'READY', 'ACTIVE'}:
        raise PlanError(f'{task_id} is {state}, not READY/ACTIVE. Use --inspect for coordinator review only.')
    if max_bytes < 2048:
        raise PlanError('Brief limit must be at least 2048 bytes; instructions are never silently truncated.')
    log = read_text(root, 'DLOG.md').splitlines()
    rows = [line for line in log if re.match(r'^\|\s*\d{4}-\d{2}-\d{2}', line)]
    recent = '\n'.join(rows[-5:]) or '(No work-session rows found.)'
    dependencies = ', '.join(f'{x}={states[x]}' for x in task.depends_on) or 'None'
    mode = 'INSPECTION ONLY - DO NOT IMPLEMENT' if inspect else 'ONE-TASK IMPLEMENTATION BRIEF'
    brief = (f'# {mode}: {task_id}\n\n'
             f'State: {state}. Role: {task.role}. Dependencies: {dependencies}.\n\n'
             'Read actual PLAN.md and actual source before editing; this brief is not a repository snapshot.\n\n'
             '## Root rules\n\n' + read_text(root, 'AGENTS.md') + '\n'
             '## Orientation\n\n' + read_text(root, 'README.md') + '\n'
             '## Recent work log\n\n' + recent + '\n\n'
             '## Assigned card\n\n' + task.text + '\n'
             '## Close the session\n\n'
             'Report result, changed files, actual checks, accessible evidence, documentation, '
             'unverified items and one next task. Do not start the next task.\n')
    size = len(brief.encode('utf-8'))
    if size > max_bytes:
        raise PlanError(f'Brief is {size} bytes, above limit {max_bytes}; split/simplify the task rather than truncate rules.')
    return brief


def main(argv: list[str] | None = None) -> int:
    """Run a read-only command; errors use nonzero exit codes instead of false success."""
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--root', type=Path, default=DEFAULT_ROOT,
                        help='Repository root; normally inferred from this script.')
    sub = parser.add_subparsers(dest='command', required=True)
    sub.add_parser('validate', help='Check task/plan structure, not the game.')
    sub.add_parser('status', help='Show canonical task statuses.')
    brief = sub.add_parser('brief', help='Print one bounded agent assignment.')
    brief.add_argument('task_id')
    brief.add_argument('--inspect', action='store_true', help='Read-only coordinator inspection of a non-ready task.')
    brief.add_argument('--max-bytes', type=int, default=24000)
    args = parser.parse_args(argv)
    root = args.root.resolve()
    try:
        if args.command == 'brief':
            print(make_brief(root, args.task_id, args.inspect, args.max_bytes), end='')
            return 0
        errors = validate(root)
        if errors:
            print('\n'.join(errors), file=sys.stderr)
            return 1
        states = plan_states(root)
        if args.command == 'validate':
            print(f'PASS: {len(states)} task records and plan structure checked. Game/runtime NOT TESTED.')
        else:
            for task_id, state in states.items():
                print(f'{task_id}  {state}')
            ready = ', '.join(key for key, value in states.items() if value == 'READY') or 'none'
            print(f'\nREADY: {ready}. WAITING tasks need coordinator preparation, not automatic dispatch.')
        return 0
    except (PlanError, OSError) as exc:
        print(f'ERROR: {exc}', file=sys.stderr)
        return 2


if __name__ == '__main__':
    raise SystemExit(main())

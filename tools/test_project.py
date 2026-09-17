"""Prove that the documentation helper rejects misleading or unsafe task records.

Purpose: Test the briefing/plan helper, not the future game or coding agent.
Reads: A copied version of this pack and independent numeric fixtures.
Writes: Temporary test folders only; the real plan is never changed.
Safe changes: Add failure examples; do not remove assertions to hide defects.
"""
from __future__ import annotations

from contextlib import redirect_stdout, redirect_stderr
import hashlib
import io
import json
from pathlib import Path
import re
import shutil
import tempfile
import unittest

import project

ROOT = Path(__file__).resolve().parents[1]


class ProjectToolTests(unittest.TestCase):
    """Each test modifies a disposable copy so the owner's repository remains untouched."""

    def setUp(self) -> None:
        """Make a clean, isolated copy of the plan and instructions for one test."""
        self.temp = tempfile.TemporaryDirectory()
        self.root = Path(self.temp.name) / 'repo'
        shutil.copytree(ROOT, self.root, ignore=shutil.ignore_patterns('__pycache__', 'artifacts'))
        self.addCleanup(self.temp.cleanup)

    def edit(self, name: str, before: str, after: str) -> None:
        """Change exactly one known piece of fixture text, failing if it is not found."""
        path = self.root / name
        text = path.read_text(encoding='utf-8')
        self.assertIn(before, text)
        path.write_text(text.replace(before, after, 1), encoding='utf-8')

    def metadata(self, task_id: str, **changes: object) -> None:
        """Alter one task's JSON metadata without editing the test's real source pack."""
        path = self.root / 'tasks' / f'{task_id}.md'
        text = path.read_text(encoding='utf-8')
        match = re.search(r'```json\n(.*?)\n```', text, re.S)
        self.assertIsNotNone(match)
        assert match is not None
        record = json.loads(match.group(1))
        record.update(changes)
        path.write_text(text[:match.start(1)] + json.dumps(record, indent=2)
                        + text[match.end(1):], encoding='utf-8')

    def test_bundled_plan_validates(self) -> None:
        """The supplied pack starts structurally consistent, without claiming runtime success."""
        self.assertEqual(project.validate(self.root), [])

    def test_plan_has_38_tasks_and_spike_is_done(self) -> None:
        """A bounded T024 revision is the only task ready while the gate is blocked."""
        states = project.plan_states(self.root)
        self.assertEqual(len(states), 38)
        ready = [t for t, s in states.items() if s == 'READY']
        self.assertEqual(ready, ['T024a'], f'Expected only T024a READY, got: {ready}')
        self.assertEqual(states['T011'], 'DONE')
        self.assertEqual(states['T012'], 'BLOCKED')
        self.assertEqual(states['T012a'], 'DONE')
        self.assertEqual(states['T023'], 'DONE')
        self.assertEqual(states['T024'], 'BLOCKED')

    def test_blocked_brief_is_inspection_only(self) -> None:
        """A blocked gate can be inspected without becoming a normal assignment."""
        brief = project.make_brief(self.root, 'T012', inspect=True)
        self.assertIn('Repository rules for coding agents', brief)
        self.assertIn('T012 - Accept or reject the terrain foundation', brief)
        self.assertNotIn('# T036 -', brief)
        self.assertLessEqual(len(brief.encode()), 24000)

    def test_review_brief_is_refused(self) -> None:
        """A review task cannot be handed out as a normal implementation assignment."""
        with self.assertRaisesRegex(project.PlanError, 'not READY/ACTIVE'):
            project.make_brief(self.root, 'T023')

    def test_review_task_can_be_inspected(self) -> None:
        """Review work can be inspected only with an explicit non-implementation label."""
        self.assertIn('INSPECTION ONLY - DO NOT IMPLEMENT',
                      project.make_brief(self.root, 'T023', inspect=True))

    def test_missing_ready_context_is_reported(self) -> None:
        """A task cannot be ready while its required instructions are missing."""
        (self.root / 'docs/SOURCES.md').unlink()
        self.assertTrue(any('context is missing' in e for e in project.validate(self.root)))

    def test_future_waiting_context_is_allowed(self) -> None:
        """A later card may reference a genuinely future terrain-world result."""
        self.assertFalse((self.root / 'docs/features/terrain-world.md').exists())
        self.assertEqual(project.validate(self.root), [])

    def test_unknown_state_is_rejected(self) -> None:
        """An invented success label cannot bypass the state model."""
        self.edit('PLAN.md', '| WAITING |', '| PROBABLY_DONE |')
        self.assertTrue(any('Unknown state' in e for e in project.validate(self.root)))

    def test_duplicate_plan_row_is_rejected(self) -> None:
        """The status authority cannot contain two conflicting rows for one task."""
        with (self.root / 'PLAN.md').open('a', encoding='utf-8') as stream:
            stream.write('\n| T001 | Duplicate | READY |\n')
        self.assertTrue(any('Duplicate PLAN' in e for e in project.validate(self.root)))

    def test_unknown_dependency_is_rejected(self) -> None:
        """All prerequisites must name actual tasks."""
        self.metadata('T002', depends_on=['T999'])
        self.assertTrue(any('unknown dependency' in e for e in project.validate(self.root)))

    def test_dependency_cycle_is_rejected(self) -> None:
        """Circular prerequisites are impossible to schedule and must be visible."""
        self.metadata('T001', depends_on=['T002'])
        self.assertTrue(any('cycle' in e for e in project.validate(self.root)))

    def test_premature_ready_task_is_rejected(self) -> None:
        """Readiness requires accepted prerequisites, not just their existence."""
        self.edit('PLAN.md', '| T023 | Set consistent terrain materials and daylight | DONE |',
                  '| T023 | Set consistent terrain materials and daylight | REVIEW |')
        self.edit('PLAN.md', '| T024 | Accept the first procedural visual-quality slice | WAITING |',
                  '| T024 | Accept the first procedural visual-quality slice | READY |')
        self.assertTrue(any('T024: dependency T023 is not DONE' in e
                            for e in project.validate(self.root)))

    def test_done_requires_evidence_summary(self) -> None:
        """A DONE label must at least point to retained evidence; content still needs review."""
        self.edit('PLAN.md', '| T024 | Accept the first procedural visual-quality slice | WAITING |',
                  '| T024 | Accept the first procedural visual-quality slice | DONE |')
        self.assertTrue(any('DONE requires' in e for e in project.validate(self.root)))

    def test_outside_read_path_is_rejected(self) -> None:
        """Task context cannot direct this helper to read outside the repository."""
        self.metadata('T001', read=['../private.txt'])
        self.assertTrue(any('confined repository path' in e for e in project.validate(self.root)))

    def test_absolute_path_is_rejected(self) -> None:
        """Absolute paths are not permitted in task metadata."""
        with self.assertRaises(project.PlanError):
            project.safe_path(self.root, '/etc/passwd')

    def test_windows_escape_path_is_rejected(self) -> None:
        """Windows-style outside paths are refused even on another host OS."""
        with self.assertRaises(project.PlanError):
            project.safe_path(self.root, 'C:\\private\\key.txt')

    def test_brief_is_not_silently_truncated(self) -> None:
        """A size limit cannot silently remove safety or acceptance instructions."""
        with self.assertRaisesRegex(project.PlanError, 'above limit'):
            project.make_brief(self.root, 'T012', inspect=True, max_bytes=2048)

    def test_unknown_task_is_rejected(self) -> None:
        """The helper never guesses an assignment from an unknown ID."""
        with self.assertRaisesRegex(project.PlanError, 'Unknown task'):
            project.make_brief(self.root, 'T999')

    def test_required_section_is_checked(self) -> None:
        """Each task needs explicit failure/stop instructions."""
        self.edit('tasks/T001.md', '## Stop conditions', '## Missing heading')
        self.assertTrue(any('missing section Stop conditions' in e
                            for e in project.validate(self.root)))

    def test_unexpected_metadata_is_rejected(self) -> None:
        """A duplicate metadata status cannot become a second status authority."""
        self.metadata('T001', status='DONE')
        self.assertTrue(any('metadata keys' in e for e in project.validate(self.root)))

    def test_bad_json_is_rejected(self) -> None:
        """Corrupt machine-readable metadata fails clearly instead of being ignored."""
        self.edit('tasks/T001.md', '"id": "T001",', '"id": "T001",,')
        self.assertTrue(any('invalid metadata JSON' in e for e in project.validate(self.root)))

    def test_seed_fixture_matches_independent_sha256(self) -> None:
        """The frozen reference bytes and numeric interpretations are internally correct."""
        data = json.loads((self.root / 'fixtures/seed_vectors.json').read_text())
        for row in data['vectors']:
            digest = hashlib.sha256(row['payload'].encode('ascii')).digest()
            value = int.from_bytes(digest[:4], 'big')
            self.assertEqual(digest.hex(), row['sha256'])
            self.assertEqual(value, row['first_u32'])
            self.assertEqual(value / 4294967296, row['unit_value'])

    def test_coordinate_fixture_is_mathematically_correct(self) -> None:
        """The reference locations use half-open cells correctly, including negatives."""
        data = json.loads((self.root / 'fixtures/coordinate_vectors.json').read_text())
        for row in data['vectors']:
            local = row['expected_local_m']
            self.assertGreaterEqual(local, 0)
            self.assertLess(local, data['cell_width_m'])
            self.assertEqual(int(row['expected_cell']) * 256 + local, row['world_axis_m'])

    def test_cli_reports_only_documentation_validation(self) -> None:
        """A passing helper command explicitly avoids claiming the game was tested."""
        output = io.StringIO()
        with redirect_stdout(output):
            code = project.main(['--root', str(self.root), 'validate'])
        self.assertEqual(code, 0)
        self.assertIn('Game/runtime NOT TESTED', output.getvalue())

    def test_cli_failure_is_nonzero(self) -> None:
        """An invalid assignment produces a real failing command exit status."""
        output = io.StringIO()
        with redirect_stderr(output):
            code = project.main(['--root', str(self.root), 'brief', 'T023'])
        self.assertNotEqual(code, 0)
        self.assertIn('not READY/ACTIVE', output.getvalue())


if __name__ == '__main__':
    unittest.main()

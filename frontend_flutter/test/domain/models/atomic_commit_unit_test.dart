import 'package:flutter_test/flutter_test.dart';
import 'package:otto_frontend/domain/models/atomic_commit_unit.dart';

void main() {
  group('AtomicCommitUnit.fromJson Schema Resilience', () {
    test('parses server format with title, totalAdditions, totalDeletions, parentBranch, and pr_open', () {
      final json = {
        'id': 'commit-abc',
        'title': 'feat(auth): add PKCE validator',
        'type': 'feat',
        'scope': 'auth',
        'branchName': 'atomik/auth-pkce',
        'parentBranch': 'main',
        'totalAdditions': 48,
        'totalDeletions': 6,
        'status': 'pr_open',
        'prNumber': 144,
        'hunks': [
          {'filePath': 'lib/auth.dart'},
          {'filePath': 'lib/verifier.dart'},
        ],
      };

      final unit = AtomicCommitUnit.fromJson(json);

      expect(unit.id, 'commit-abc');
      expect(unit.summary, 'feat(auth): add PKCE validator');
      expect(unit.additions, 48);
      expect(unit.deletions, 6);
      expect(unit.parentCommitId, 'main');
      expect(unit.status, CommitStatus.inReview);
      expect(unit.isPushed, true);
      expect(unit.prNumber, 144);
      expect(unit.changedFiles, containsAll(['lib/auth.dart', 'lib/verifier.dart']));
    });

    test('seamlessly maps all status string variants', () {
      final testCases = <String, CommitStatus>{
        'pr_open': CommitStatus.inReview,
        'open': CommitStatus.inReview,
        'in_review': CommitStatus.inReview,
        'inReview': CommitStatus.inReview,
        'staged': CommitStatus.readyToPush,
        'queued': CommitStatus.readyToPush,
        'ready_to_push': CommitStatus.readyToPush,
        'readyToPush': CommitStatus.readyToPush,
        'pushed': CommitStatus.pushed,
        'merged': CommitStatus.merged,
        'draft': CommitStatus.draft,
        'conflicted': CommitStatus.conflicted,
      };

      for (final entry in testCases.entries) {
        final unit = AtomicCommitUnit.fromJson({
          'summary': 'test commit',
          'status': entry.key,
        });
        expect(unit.status, entry.value, reason: 'Failed for status string: ${entry.key}');
      }
    });

    test('falls back to client format (summary, additions, deletions, parentCommitId)', () {
      final json = {
        'id': 'client-commit',
        'summary': 'fix: handle null pointer',
        'additions': 12,
        'deletions': 3,
        'parentCommitId': 'parent-123',
        'status': 'draft',
      };

      final unit = AtomicCommitUnit.fromJson(json);

      expect(unit.summary, 'fix: handle null pointer');
      expect(unit.additions, 12);
      expect(unit.deletions, 3);
      expect(unit.parentCommitId, 'parent-123');
      expect(unit.status, CommitStatus.draft);
    });

    test('falls back to bodyBullets and sha if description and id are absent', () {
      final json = {
        'sha': '8f4e2c1',
        'title': 'refactor(core): streamline DAG traversal',
        'bodyBullets': [
          'Replace O(N^2) cycle check with linear Kahn queue',
          'Normalize external base branch resolution',
        ],
        'totalAdditions': 25,
        'totalDeletions': 10,
        'status': 'staged',
      };

      final unit = AtomicCommitUnit.fromJson(json);

      expect(unit.id, '8f4e2c1');
      expect(unit.summary, 'refactor(core): streamline DAG traversal');
      expect(unit.description, contains('Replace O(N^2) cycle check'));
      expect(unit.description, contains('Normalize external base branch'));
      expect(unit.status, CommitStatus.readyToPush);
    });

    test('toJson generates bidirectional schema with title, totalAdditions, parentBranch', () {
      final unit = AtomicCommitUnit(
        id: 'c-test',
        summary: 'feat: test commit',
        branchName: 'branch-test',
        parentCommitId: 'main',
        additions: 15,
        deletions: 5,
        status: CommitStatus.inReview,
      );

      final json = unit.toJson();

      expect(json['summary'], 'feat: test commit');
      expect(json['title'], 'feat: test commit');
      expect(json['additions'], 15);
      expect(json['totalAdditions'], 15);
      expect(json['deletions'], 5);
      expect(json['totalDeletions'], 5);
      expect(json['parentCommitId'], 'main');
      expect(json['parentBranch'], 'main');
    });
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:otto_frontend/domain/models/atomic_commit_unit.dart';
import 'package:otto_frontend/domain/models/stack_dependency_graph.dart';

void main() {
  group('StackDependencyGraph Kahn\'s Algorithm', () {
    test('does not report false cycle when parentCommitId points to external branch "main"', () {
      final commits = [
        AtomicCommitUnit(
          id: 'commit-1',
          summary: 'feat: add payment gateway',
          branchName: 'atomik/payment',
          parentCommitId: 'main', // External base branch!
        ),
      ];

      final graph = StackDependencyGraph(commits: commits);
      final sorted = graph.topologicalSort();

      expect(sorted.length, 1);
      expect(sorted.first.id, 'commit-1');
    });

    test('correctly sorts linear chain with external base branch "origin/main"', () {
      final commit1 = AtomicCommitUnit(
        id: 'c1',
        summary: 'feat: step 1',
        branchName: 'branch-1',
        parentCommitId: 'origin/main',
      );
      final commit2 = AtomicCommitUnit(
        id: 'c2',
        summary: 'feat: step 2',
        branchName: 'branch-2',
        parentCommitId: 'c1',
      );
      final commit3 = AtomicCommitUnit(
        id: 'c3',
        summary: 'feat: step 3',
        branchName: 'branch-3',
        parentCommitId: 'c2',
      );

      final graph = StackDependencyGraph(commits: [commit3, commit1, commit2]);
      final sorted = graph.topologicalSort();

      expect(sorted.map((c) => c.id).toList(), ['c1', 'c2', 'c3']);
    });

    test('detects actual cyclic dependencies and throws StateError', () {
      final commitA = AtomicCommitUnit(
        id: 'cA',
        summary: 'feat: A',
        branchName: 'branch-A',
        parentCommitId: 'cB',
      );
      final commitB = AtomicCommitUnit(
        id: 'cB',
        summary: 'feat: B',
        branchName: 'branch-B',
        parentCommitId: 'cA',
      );

      final graph = StackDependencyGraph(commits: [commitA, commitB]);
      expect(() => graph.topologicalSort(), throwsA(isA<StateError>()));
    });

    test('resolves parent references across branchName identifiers', () {
      final commit1 = AtomicCommitUnit(
        id: 'c1',
        summary: 'feat: step 1',
        branchName: 'atomik/step-1',
        parentCommitId: 'main',
      );
      final commit2 = AtomicCommitUnit(
        id: 'c2',
        summary: 'feat: step 2',
        branchName: 'atomik/step-2',
        parentCommitId: 'atomik/step-1', // Points to parent branchName rather than commit ID
      );

      final graph = StackDependencyGraph(commits: [commit2, commit1]);
      final sorted = graph.topologicalSort();

      expect(sorted.map((c) => c.id).toList(), ['c1', 'c2']);
      expect(graph.isValidOrder(['c1', 'c2']), true);
      expect(graph.isValidOrder(['c2', 'c1']), false);
    });

    test('detects self-referential cycle', () {
      final commitSelf = AtomicCommitUnit(
        id: 'cSelf',
        summary: 'feat: self',
        branchName: 'branch-self',
        parentCommitId: 'cSelf',
      );

      final graph = StackDependencyGraph(commits: [commitSelf]);
      expect(() => graph.topologicalSort(), throwsA(isA<StateError>()));
    });

    test('handles multiple root commits targeting main without cycles', () {
      final root1 = AtomicCommitUnit(
        id: 'r1',
        summary: 'feat: root 1',
        branchName: 'branch-r1',
        parentCommitId: 'main',
      );
      final root2 = AtomicCommitUnit(
        id: 'r2',
        summary: 'feat: root 2',
        branchName: 'branch-r2',
        parentCommitId: 'main',
      );

      final graph = StackDependencyGraph(commits: [root1, root2]);
      final sorted = graph.topologicalSort();
      expect(sorted.length, 2);
    });
  });
}

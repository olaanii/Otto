import 'package:flutter_test/flutter_test.dart';
import 'package:otto_frontend/domain/models/atomic_commit_unit.dart';
import 'package:otto_frontend/domain/models/stack_dependency_graph.dart';

void main() {
  group('Kahn\'s Algorithm & StackDependencyGraph Tests', () {
    final commitA = AtomicCommitUnit(
      id: 'commit-a',
      summary: 'feat(core): initial foundation',
      branchName: 'stack-1',
    );
    final commitB = AtomicCommitUnit(
      id: 'commit-b',
      summary: 'feat(auth): add clerk login',
      branchName: 'stack-2',
      parentCommitId: 'commit-a',
    );
    final commitC = AtomicCommitUnit(
      id: 'commit-c',
      summary: 'feat(ui): add diff viewer',
      branchName: 'stack-3',
      parentCommitId: 'commit-b',
    );

    test('topologicalSort returns commits in correct ancestor-first order', () {
      // Pass in reverse order: [C, B, A]
      final graph = StackDependencyGraph(commits: [commitC, commitB, commitA]);

      final sorted = graph.topologicalSort();
      expect(sorted.map((c) => c.id).toList(), ['commit-a', 'commit-b', 'commit-c']);
    });

    test('isValidOrder returns true for ancestor-before-descendant order', () {
      final graph = StackDependencyGraph(commits: [commitA, commitB, commitC]);

      expect(graph.isValidOrder(['commit-a', 'commit-b', 'commit-c']), isTrue);
    });

    test('isValidOrder returns false if child precedes parent', () {
      final graph = StackDependencyGraph(commits: [commitA, commitB, commitC]);

      // B precedes A, which violates dependency
      expect(graph.isValidOrder(['commit-b', 'commit-a', 'commit-c']), isFalse);
      // C precedes B
      expect(graph.isValidOrder(['commit-a', 'commit-c', 'commit-b']), isFalse);
    });

    test('topologicalSort throws StateError when a cycle is detected', () {
      // Create artificial cycle: A depends on C, C depends on B, B depends on A
      final cyclicA = AtomicCommitUnit(
        id: 'commit-a',
        summary: 'a',
        branchName: 's1',
        parentCommitId: 'commit-c',
      );
      final cyclicB = AtomicCommitUnit(
        id: 'commit-b',
        summary: 'b',
        branchName: 's2',
        parentCommitId: 'commit-a',
      );
      final cyclicC = AtomicCommitUnit(
        id: 'commit-c',
        summary: 'c',
        branchName: 's3',
        parentCommitId: 'commit-b',
      );

      final graph = StackDependencyGraph(commits: [cyclicA, cyclicB, cyclicC]);
      expect(() => graph.topologicalSort(), throwsA(isA<StateError>()));
    });
  });
}

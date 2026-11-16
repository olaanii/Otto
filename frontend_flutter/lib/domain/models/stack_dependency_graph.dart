import 'atomic_commit_unit.dart';

/// Represents the Directed Acyclic Graph (DAG) of stacked atomic PR commits.
/// Uses Kahn's algorithm for topological sorting and cycle detection.
class StackDependencyGraph {
  final List<AtomicCommitUnit> commits;
  final Map<String, List<String>> adjacencyList; // parentId -> [childIds]

  StackDependencyGraph({
    required this.commits,
    Map<String, List<String>>? adjacencyList,
  }) : adjacencyList = adjacencyList ?? _buildAdjacencyList(commits);

  static Map<String, List<String>> _buildAdjacencyList(List<AtomicCommitUnit> commits) {
    final adj = <String, List<String>>{};
    for (final c in commits) {
      adj.putIfAbsent(c.id, () => []);
      if (c.parentCommitId != null) {
        adj.putIfAbsent(c.parentCommitId!, () => []);
        if (!adj[c.parentCommitId!]!.contains(c.id)) {
          adj[c.parentCommitId!]!.add(c.id);
        }
      }
    }
    return adj;
  }

  /// Kahn's algorithm for topological sorting.
  /// Returns topologically sorted list of commits.
  /// Throws [StateError] if a cyclic dependency is detected.
  List<AtomicCommitUnit> topologicalSort() {
    final commitMap = {for (final c in commits) c.id: c};
    final inDegree = <String, int>{};

    for (final c in commits) {
      inDegree[c.id] = 0;
    }

    for (final entry in adjacencyList.entries) {
      for (final childId in entry.value) {
        if (inDegree.containsKey(childId)) {
          inDegree[childId] = (inDegree[childId] ?? 0) + 1;
        }
      }
    }

    // Queue of nodes with zero in-degree
    final queue = <String>[];
    for (final c in commits) {
      if ((inDegree[c.id] ?? 0) == 0) {
        queue.add(c.id);
      }
    }

    final sortedResult = <AtomicCommitUnit>[];

    while (queue.isNotEmpty) {
      final currentId = queue.removeAt(0);
      final commit = commitMap[currentId];
      if (commit != null) {
        sortedResult.add(commit);
      }

      final neighbors = adjacencyList[currentId] ?? [];
      for (final neighborId in neighbors) {
        if (inDegree.containsKey(neighborId)) {
          inDegree[neighborId] = inDegree[neighborId]! - 1;
          if (inDegree[neighborId] == 0) {
            queue.add(neighborId);
          }
        }
      }
    }

    if (sortedResult.length != commits.length) {
      throw StateError('Cyclic dependency detected in stacked PR graph!');
    }

    return sortedResult;
  }

  /// Validates whether a proposed linear order satisfies parent-before-child constraints.
  bool isValidOrder(List<String> proposedCommitIds) {
    final indexMap = <String, int>{};
    for (int i = 0; i < proposedCommitIds.length; i++) {
      indexMap[proposedCommitIds[i]] = i;
    }

    for (final commit in commits) {
      if (commit.parentCommitId != null &&
          indexMap.containsKey(commit.id) &&
          indexMap.containsKey(commit.parentCommitId)) {
        final parentIdx = indexMap[commit.parentCommitId!]!;
        final childIdx = indexMap[commit.id]!;
        if (parentIdx >= childIdx) {
          return false;
        }
      }
    }
    return true;
  }

  StackDependencyGraph copyWith({
    List<AtomicCommitUnit>? commits,
    Map<String, List<String>>? adjacencyList,
  }) {
    return StackDependencyGraph(
      commits: commits ?? this.commits,
      adjacencyList: adjacencyList ?? this.adjacencyList,
    );
  }
}

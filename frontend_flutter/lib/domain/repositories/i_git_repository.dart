import '../models/atomic_commit_unit.dart';
import '../models/diff_hunk.dart';
import '../models/stack_dependency_graph.dart';
import '../../core/network/sse_client.dart';

/// Contract for Git operations, diff slicing, rebase canvas, and stack syncing.
abstract class IGitRepository {
  /// Fetches current git workspace status (working tree diffs, active branch, stacked commits).
  Future<({List<FileDiff> uncommittedDiffs, StackDependencyGraph stackGraph, String currentBranch})>
      fetchWorkspaceState();

  /// Gets uncommitted raw diff from daemon.
  Future<String> getRawDiff();

  /// Slices staged hunks and creates an atomic commit adhering to guardrails.
  Future<AtomicCommitUnit> createAtomicCommit({
    required String summary,
    String? description,
    required String type,
    String? scope,
    required List<DiffHunk> hunks,
  });

  /// Splits an existing large commit into multiple smaller atomic commits.
  Future<List<AtomicCommitUnit>> splitCommit({
    required String commitId,
    required List<List<DiffHunk>> partitionedHunks,
  });

  /// Reorders and rebases the stack according to the dependency graph.
  Future<StackDependencyGraph> rebaseAndReorderStack(List<String> orderedCommitIds);

  /// Pushes the atomic stack to upstream GitHub and opens or updates PR chain.
  Future<void> pushAtomicStack({
    required List<String> commitIds,
    bool openDraftPrs = true,
  });

  /// Subscribes to real-time git events emitted by the daemon.
  Stream<SseEvent> watchGitEvents();
}

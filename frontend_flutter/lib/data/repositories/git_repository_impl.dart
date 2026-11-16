import '../../core/errors/exceptions.dart';
import '../../core/errors/failure.dart';
import '../../core/isolates/diff_tokenizer_isolate.dart';
import '../../core/network/sse_client.dart';
import '../../domain/models/atomic_commit_unit.dart';
import '../../domain/models/diff_hunk.dart';
import '../../domain/models/stack_dependency_graph.dart';
import '../../domain/repositories/i_git_repository.dart';
import '../datasources/daemon_rest_datasource.dart';
import '../datasources/daemon_sse_datasource.dart';

class GitRepositoryImpl implements IGitRepository {
  final IDaemonRestDataSource restDataSource;
  final IDaemonSseDataSource sseDataSource;

  GitRepositoryImpl({
    required this.restDataSource,
    required this.sseDataSource,
  });

  @override
  Future<({List<FileDiff> uncommittedDiffs, StackDependencyGraph stackGraph, String currentBranch})>
      fetchWorkspaceState() async {
    try {
      final stateData = await restDataSource.getWorkspaceState();
      final branch = stateData['current_branch'] as String? ?? 'main';

      // Parse stacked commits into AtomicCommitUnits
      final rawCommits = stateData['commits'] as List<dynamic>? ?? [];
      final commits = rawCommits
          .map((item) => AtomicCommitUnit.fromJson(item as Map<String, dynamic>))
          .toList();

      final stackGraph = StackDependencyGraph(commits: commits);

      // Fetch uncommitted raw diff and parse in background isolate
      final rawDiff = await restDataSource.getRawDiff();
      List<FileDiff> uncommittedDiffs = const [];
      if (rawDiff.trim().isNotEmpty) {
        uncommittedDiffs = await DiffTokenizerIsolate.parseDiffAsync(
          DiffTokenizeRequest(rawUnifiedDiff: rawDiff),
        );
      }

      return (
        uncommittedDiffs: uncommittedDiffs,
        stackGraph: stackGraph,
        currentBranch: branch,
      );
    } on GitOperationException catch (e) {
      throw GitConflictFailure(e.message, conflictingFiles: e.conflictingFiles, cause: e);
    } on ServerException catch (e) {
      throw ServerFailure(e.message, statusCode: e.statusCode, cause: e);
    } catch (e) {
      throw ServerFailure('Failed to fetch workspace state: $e', cause: e);
    }
  }

  @override
  Future<String> getRawDiff() async {
    try {
      return await restDataSource.getRawDiff();
    } catch (e) {
      throw ServerFailure('Failed to retrieve raw diff: $e', cause: e);
    }
  }

  @override
  Future<AtomicCommitUnit> createAtomicCommit({
    required String summary,
    String? description,
    required String type,
    String? scope,
    required List<DiffHunk> hunks,
  }) async {
    try {
      final data = await restDataSource.createCommit(
        summary: summary,
        description: description,
        type: type,
        scope: scope,
        hunks: hunks,
      );
      final commitMap = data['commit'] as Map<String, dynamic>? ?? data;
      return AtomicCommitUnit.fromJson(commitMap);
    } on GitOperationException catch (e) {
      throw GitConflictFailure(e.message, conflictingFiles: e.conflictingFiles, cause: e);
    } catch (e) {
      throw ServerFailure('Failed to create atomic commit: $e', cause: e);
    }
  }

  @override
  Future<List<AtomicCommitUnit>> splitCommit({
    required String commitId,
    required List<List<DiffHunk>> partitionedHunks,
  }) async {
    try {
      final list = await restDataSource.splitCommit(
        commitId: commitId,
        partitionedHunks: partitionedHunks,
      );
      return list.map((m) => AtomicCommitUnit.fromJson(m)).toList();
    } on GitOperationException catch (e) {
      throw GitConflictFailure(e.message, conflictingFiles: e.conflictingFiles, cause: e);
    } catch (e) {
      throw ServerFailure('Failed to split commit: $e', cause: e);
    }
  }

  @override
  Future<StackDependencyGraph> rebaseAndReorderStack(List<String> orderedCommitIds) async {
    try {
      final data = await restDataSource.rebaseStack(orderedCommitIds);
      final rawCommits = data['commits'] as List<dynamic>? ?? [];
      final commits = rawCommits
          .map((item) => AtomicCommitUnit.fromJson(item as Map<String, dynamic>))
          .toList();
      return StackDependencyGraph(commits: commits);
    } on GitOperationException catch (e) {
      throw GitConflictFailure(e.message, conflictingFiles: e.conflictingFiles, cause: e);
    } catch (e) {
      throw ServerFailure('Rebase failed: $e', cause: e);
    }
  }

  @override
  Future<void> pushAtomicStack({
    required List<String> commitIds,
    bool openDraftPrs = true,
  }) async {
    try {
      await restDataSource.pushStack(
        commitIds: commitIds,
        openDraftPrs: openDraftPrs,
      );
    } on GitOperationException catch (e) {
      throw GitConflictFailure(e.message, conflictingFiles: e.conflictingFiles, cause: e);
    } catch (e) {
      throw ServerFailure('Failed to push atomic stack: $e', cause: e);
    }
  }

  @override
  Stream<SseEvent> watchGitEvents() {
    return sseDataSource.eventStream;
  }
}

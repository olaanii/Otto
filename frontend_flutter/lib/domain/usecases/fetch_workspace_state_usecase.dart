import '../models/diff_hunk.dart';
import '../models/stack_dependency_graph.dart';
import '../repositories/i_git_repository.dart';

class FetchWorkspaceStateUseCase {
  final IGitRepository gitRepository;

  FetchWorkspaceStateUseCase(this.gitRepository);

  Future<({List<FileDiff> uncommittedDiffs, StackDependencyGraph stackGraph, String currentBranch})>
      call() async {
    return gitRepository.fetchWorkspaceState();
  }
}

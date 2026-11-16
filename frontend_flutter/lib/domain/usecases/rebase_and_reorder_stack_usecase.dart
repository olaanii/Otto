import '../models/stack_dependency_graph.dart';
import '../repositories/i_git_repository.dart';
import '../../core/errors/failure.dart';

class RebaseAndReorderStackUseCase {
  final IGitRepository gitRepository;

  RebaseAndReorderStackUseCase(this.gitRepository);

  Future<StackDependencyGraph> call({
    required StackDependencyGraph currentGraph,
    required List<String> proposedCommitOrder,
  }) async {
    // Validate order against DAG rules
    if (!currentGraph.isValidOrder(proposedCommitOrder)) {
      throw const GitConflictFailure(
        'Invalid reorder: Child commits cannot precede their parents in the stack.',
      );
    }

    return gitRepository.rebaseAndReorderStack(proposedCommitOrder);
  }
}

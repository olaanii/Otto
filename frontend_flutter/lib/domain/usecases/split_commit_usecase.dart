import '../models/atomic_commit_unit.dart';
import '../models/diff_hunk.dart';
import '../repositories/i_git_repository.dart';

class SplitCommitUseCase {
  final IGitRepository gitRepository;

  SplitCommitUseCase(this.gitRepository);

  Future<List<AtomicCommitUnit>> call({
    required String commitId,
    required List<List<DiffHunk>> targetPartitions,
  }) async {
    if (targetPartitions.isEmpty) {
      throw ArgumentError('At least one hunk partition must be provided to split commit');
    }
    return gitRepository.splitCommit(
      commitId: commitId,
      partitionedHunks: targetPartitions,
    );
  }
}

import '../repositories/i_git_repository.dart';

class PushAtomicStackUseCase {
  final IGitRepository gitRepository;

  PushAtomicStackUseCase(this.gitRepository);

  Future<void> call({
    required List<String> commitIds,
    bool openDraftPrs = true,
  }) async {
    if (commitIds.isEmpty) {
      throw ArgumentError('Commit ID list cannot be empty');
    }
    await gitRepository.pushAtomicStack(
      commitIds: commitIds,
      openDraftPrs: openDraftPrs,
    );
  }
}

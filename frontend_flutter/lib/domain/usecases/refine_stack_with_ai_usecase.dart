import '../models/atomic_commit_unit.dart';
import '../models/diff_hunk.dart';
import '../models/llm_provider_config.dart';
import '../repositories/i_llm_repository.dart';

class RefineStackWithAiUseCase {
  final ILlmRepository llmRepository;

  RefineStackWithAiUseCase(this.llmRepository);

  Future<List<AtomicCommitUnit>> call({
    required List<FileDiff> diffs,
    required LlmProviderConfig provider,
    String? promptInstructions,
  }) async {
    if (diffs.isEmpty) return const [];
    return llmRepository.refineStackWithAi(
      diffs: diffs,
      provider: provider,
      additionalContext: promptInstructions,
    );
  }
}

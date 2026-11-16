import '../models/atomic_commit_unit.dart';
import '../models/diff_hunk.dart';
import '../models/llm_provider_config.dart';

/// Contract for AI-assisted diff slicing, stack refinement, and conventional commit generation.
abstract class ILlmRepository {
  /// Fetches available and configured LLM providers.
  Future<List<LlmProviderConfig>> getProviders();

  /// Suggests optimal atomic commit decomposition for a large set of diff hunks.
  Future<List<AtomicCommitUnit>> refineStackWithAi({
    required List<FileDiff> diffs,
    required LlmProviderConfig provider,
    String? additionalContext,
  });

  /// Generates a conventional commit message from selected diff hunks.
  Future<({String summary, String description, String type, String? scope})>
      generateConventionalCommit({
    required List<DiffHunk> hunks,
    required LlmProviderConfig provider,
  });
}

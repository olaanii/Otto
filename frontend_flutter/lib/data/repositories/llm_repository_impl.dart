import '../../core/errors/failure.dart';
import '../../domain/models/atomic_commit_unit.dart';
import '../../domain/models/diff_hunk.dart';
import '../../domain/models/llm_provider_config.dart';
import '../../domain/repositories/i_llm_repository.dart';
import '../datasources/daemon_rest_datasource.dart';

class LlmRepositoryImpl implements ILlmRepository {
  final IDaemonRestDataSource restDataSource;

  LlmRepositoryImpl(this.restDataSource);

  @override
  Future<List<LlmProviderConfig>> getProviders() async {
    try {
      final list = await restDataSource.getLlmProviders();
      if (list.isEmpty) {
        return LlmProviderConfig.standardProviders;
      }
      return list.map((m) => LlmProviderConfig.fromJson(m)).toList();
    } catch (_) {
      return LlmProviderConfig.standardProviders;
    }
  }

  @override
  Future<List<AtomicCommitUnit>> refineStackWithAi({
    required List<FileDiff> diffs,
    required LlmProviderConfig provider,
    String? additionalContext,
  }) async {
    try {
      final list = await restDataSource.refineStackWithAi(
        diffs: diffs,
        provider: provider,
        additionalContext: additionalContext,
      );
      return list.map((m) => AtomicCommitUnit.fromJson(m)).toList();
    } catch (e) {
      throw ServerFailure('AI stack refinement failed: $e', cause: e);
    }
  }

  @override
  Future<({String summary, String description, String type, String? scope})>
      generateConventionalCommit({
    required List<DiffHunk> hunks,
    required LlmProviderConfig provider,
  }) async {
    try {
      final data = await restDataSource.generateConventionalCommit(
        hunks: hunks,
        provider: provider,
      );
      return (
        summary: data['summary'] as String? ?? 'update code changes',
        description: data['description'] as String? ?? '',
        type: data['type'] as String? ?? 'feat',
        scope: data['scope'] as String?,
      );
    } catch (e) {
      // Graceful heuristic fallback if LLM request fails
      final firstFile = hunks.isNotEmpty ? hunks.first.filePath : 'code';
      final fileName = firstFile.split('/').last.split('.').first;
      return (
        summary: 'update $fileName implementation',
        description: 'Atomic change containing ${hunks.length} hunks.',
        type: 'feat',
        scope: fileName,
      );
    }
  }
}

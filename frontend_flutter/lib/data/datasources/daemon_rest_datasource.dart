import '../../core/constants/api_endpoints.dart';
import '../../core/network/api_client.dart';
import '../../domain/models/atomic_commit_unit.dart';
import '../../domain/models/diff_hunk.dart';
import '../../domain/models/llm_provider_config.dart';

abstract class IDaemonRestDataSource {
  Future<Map<String, dynamic>> getWorkspaceState();
  Future<String> getRawDiff();
  Future<Map<String, dynamic>> createCommit({
    required String summary,
    String? description,
    required String type,
    String? scope,
    required List<DiffHunk> hunks,
  });
  Future<List<Map<String, dynamic>>> splitCommit({
    required String commitId,
    required List<List<DiffHunk>> partitionedHunks,
  });
  Future<Map<String, dynamic>> rebaseStack(List<String> orderedCommitIds);
  Future<void> pushStack({
    required List<String> commitIds,
    required bool openDraftPrs,
  });
  Future<List<Map<String, dynamic>>> getLlmProviders();
  Future<List<Map<String, dynamic>>> refineStackWithAi({
    required List<FileDiff> diffs,
    required LlmProviderConfig provider,
    String? additionalContext,
  });
  Future<Map<String, dynamic>> generateConventionalCommit({
    required List<DiffHunk> hunks,
    required LlmProviderConfig provider,
  });
}

class DaemonRestDataSource implements IDaemonRestDataSource {
  final ApiClient apiClient;

  DaemonRestDataSource(this.apiClient);

  @override
  Future<Map<String, dynamic>> getWorkspaceState() async {
    final response = await apiClient.get<Map<String, dynamic>>(
      ApiEndpoints.state,
    );
    return response.data ?? {};
  }

  @override
  Future<String> getRawDiff() async {
    final response = await apiClient.get<dynamic>(
      ApiEndpoints.analyzeDiff,
    );
    if (response.data is String) {
      return response.data as String;
    }
    return response.data?['diff'] as String? ?? '';
  }

  @override
  Future<Map<String, dynamic>> createCommit({
    required String summary,
    String? description,
    required String type,
    String? scope,
    required List<DiffHunk> hunks,
  }) async {
    final response = await apiClient.post<Map<String, dynamic>>(
      ApiEndpoints.createCommit,
      data: {
        'summary': summary,
        'description': description,
        'type': type,
        'scope': scope,
        'hunks': hunks.map((h) => h.toJson()).toList(),
      },
    );
    return response.data ?? {};
  }

  @override
  Future<List<Map<String, dynamic>>> splitCommit({
    required String commitId,
    required List<List<DiffHunk>> partitionedHunks,
  }) async {
    final response = await apiClient.post<Map<String, dynamic>>(
      ApiEndpoints.splitCommit,
      data: {
        'commit_id': commitId,
        'partitions': partitionedHunks
            .map((list) => list.map((h) => h.toJson()).toList())
            .toList(),
      },
    );
    final list = response.data?['commits'] as List<dynamic>? ?? [];
    return list.whereType<Map<String, dynamic>>().toList();
  }

  @override
  Future<Map<String, dynamic>> rebaseStack(List<String> orderedCommitIds) async {
    final response = await apiClient.post<Map<String, dynamic>>(
      ApiEndpoints.rebase,
      data: {'ordered_commit_ids': orderedCommitIds},
    );
    return response.data ?? {};
  }

  @override
  Future<void> pushStack({
    required List<String> commitIds,
    required bool openDraftPrs,
  }) async {
    await apiClient.post<void>(
      ApiEndpoints.pushStack,
      data: {
        'commit_ids': commitIds,
        'open_draft_prs': openDraftPrs,
      },
    );
  }

  @override
  Future<List<Map<String, dynamic>>> getLlmProviders() async {
    try {
      final response = await apiClient.get<Map<String, dynamic>>(
        ApiEndpoints.providers,
      );
      final list = response.data?['providers'] as List<dynamic>? ?? [];
      return list.whereType<Map<String, dynamic>>().toList();
    } catch (_) {
      return [];
    }
  }

  @override
  Future<List<Map<String, dynamic>>> refineStackWithAi({
    required List<FileDiff> diffs,
    required LlmProviderConfig provider,
    String? additionalContext,
  }) async {
    final response = await apiClient.post<Map<String, dynamic>>(
      ApiEndpoints.refineStack,
      data: {
        'provider_id': provider.id,
        'additional_context': additionalContext,
        'diffs': diffs
            .map((f) => {
                  'filePath': f.filePath,
                  'hunks': f.hunks.map((h) => h.toJson()).toList(),
                })
            .toList(),
      },
    );
    final list = response.data?['refined_commits'] as List<dynamic>? ?? [];
    return list.whereType<Map<String, dynamic>>().toList();
  }

  @override
  Future<Map<String, dynamic>> generateConventionalCommit({
    required List<DiffHunk> hunks,
    required LlmProviderConfig provider,
  }) async {
    final response = await apiClient.post<Map<String, dynamic>>(
      '/llm/commit-message',
      data: {
        'provider_id': provider.id,
        'hunks': hunks.map((h) => h.toJson()).toList(),
      },
    );
    return response.data ?? {};
  }
}

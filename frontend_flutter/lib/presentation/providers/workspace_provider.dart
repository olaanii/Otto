import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/api_endpoints.dart';
import '../../core/network/sse_client.dart';
import '../../data/datasources/daemon_rest_datasource.dart';
import '../../data/datasources/daemon_sse_datasource.dart';
import '../../data/repositories/git_repository_impl.dart';
import '../../domain/models/atomic_commit_unit.dart';
import '../../domain/models/diff_hunk.dart';
import '../../domain/models/guardrail_policy.dart';
import '../../domain/models/ide_agent_profile.dart';
import '../../domain/models/stack_dependency_graph.dart';
import '../../domain/repositories/i_git_repository.dart';
import '../../domain/usecases/fetch_workspace_state_usecase.dart';
import '../../domain/usecases/push_atomic_stack_usecase.dart';
import '../../domain/usecases/slice_diff_usecase.dart';
import 'auth_state_provider.dart';

final sseClientProvider = Provider<SseClient>((ref) {
  final storage = ref.watch(secureStorageProvider);
  final client = SseClient(
    url: ApiEndpoints.sseStreamUrl,
    secureStorage: storage,
  );
  ref.onDispose(client.dispose);
  return client;
});

final daemonRestDataSourceProvider = Provider<IDaemonRestDataSource>((ref) {
  final client = ref.watch(apiClientProvider);
  return DaemonRestDataSource(client);
});

final daemonSseDataSourceProvider = Provider<IDaemonSseDataSource>((ref) {
  final sse = ref.watch(sseClientProvider);
  return DaemonSseDataSource(sse);
});

final gitRepositoryProvider = Provider<IGitRepository>((ref) {
  final rest = ref.watch(daemonRestDataSourceProvider);
  final sse = ref.watch(daemonSseDataSourceProvider);
  return GitRepositoryImpl(restDataSource: rest, sseDataSource: sse);
});

final fetchWorkspaceStateUseCaseProvider = Provider<FetchWorkspaceStateUseCase>((ref) {
  final repo = ref.watch(gitRepositoryProvider);
  return FetchWorkspaceStateUseCase(repo);
});

final sliceDiffUseCaseProvider = Provider<SliceDiffUseCase>((ref) {
  final repo = ref.watch(gitRepositoryProvider);
  return SliceDiffUseCase(repo);
});

final pushAtomicStackUseCaseProvider = Provider<PushAtomicStackUseCase>((ref) {
  final repo = ref.watch(gitRepositoryProvider);
  return PushAtomicStackUseCase(repo);
});

final gitEventsStreamProvider = StreamProvider<SseEvent>((ref) {
  final repo = ref.watch(gitRepositoryProvider);
  return repo.watchGitEvents();
});

class WorkspaceState {
  final bool isLoading;
  final List<FileDiff> uncommittedDiffs;
  final StackDependencyGraph stackGraph;
  final String currentBranch;
  final String? selectedCommitId;
  final String? errorMessage;
  final List<IdeAgentProfile> activeAgents;
  final GuardrailPolicy guardrailPolicy;

  WorkspaceState({
    this.isLoading = false,
    this.uncommittedDiffs = const [],
    StackDependencyGraph? stackGraph,
    this.currentBranch = 'main',
    this.selectedCommitId,
    this.errorMessage,
    List<IdeAgentProfile>? activeAgents,
    this.guardrailPolicy = const GuardrailPolicy(),
  })  : stackGraph = stackGraph ?? StackDependencyGraph(commits: []),
        activeAgents = activeAgents ?? IdeAgentProfile.defaults;

  WorkspaceState copyWith({
    bool? isLoading,
    List<FileDiff>? uncommittedDiffs,
    StackDependencyGraph? stackGraph,
    String? currentBranch,
    String? selectedCommitId,
    String? errorMessage,
    List<IdeAgentProfile>? activeAgents,
    GuardrailPolicy? guardrailPolicy,
  }) {
    return WorkspaceState(
      isLoading: isLoading ?? this.isLoading,
      uncommittedDiffs: uncommittedDiffs ?? this.uncommittedDiffs,
      stackGraph: stackGraph ?? this.stackGraph,
      currentBranch: currentBranch ?? this.currentBranch,
      selectedCommitId: selectedCommitId ?? this.selectedCommitId,
      errorMessage: errorMessage,
      activeAgents: activeAgents ?? this.activeAgents,
      guardrailPolicy: guardrailPolicy ?? this.guardrailPolicy,
    );
  }
}

class WorkspaceNotifier extends StateNotifier<WorkspaceState> {
  final FetchWorkspaceStateUseCase _fetchStateUseCase;
  final SliceDiffUseCase _sliceDiffUseCase;
  final PushAtomicStackUseCase _pushStackUseCase;

  WorkspaceNotifier({
    required FetchWorkspaceStateUseCase fetchStateUseCase,
    required SliceDiffUseCase sliceDiffUseCase,
    required PushAtomicStackUseCase pushStackUseCase,
  })  : _fetchStateUseCase = fetchStateUseCase,
        _sliceDiffUseCase = sliceDiffUseCase,
        _pushStackUseCase = pushStackUseCase,
        super(WorkspaceState()) {
    refreshWorkspace();
  }

  Future<void> refreshWorkspace() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final res = await _fetchStateUseCase();
      state = state.copyWith(
        isLoading: false,
        uncommittedDiffs: res.uncommittedDiffs,
        stackGraph: res.stackGraph,
        currentBranch: res.currentBranch,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
      );
    }
  }

  void selectCommit(String? commitId) {
    state = state.copyWith(selectedCommitId: commitId);
  }

  void updateGuardrailPolicy(GuardrailPolicy policy) {
    state = state.copyWith(guardrailPolicy: policy);
  }

  Future<AtomicCommitUnit?> commitSelectedHunks({
    required String summary,
    String? description,
    required String type,
    String? scope,
    required List<DiffHunk> hunks,
  }) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final commit = await _sliceDiffUseCase(
        summary: summary,
        description: description,
        type: type,
        scope: scope,
        selectedHunks: hunks,
        policy: state.guardrailPolicy,
      );
      await refreshWorkspace();
      return commit;
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
      return null;
    }
  }

  Future<bool> pushStack() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final ids = state.stackGraph.commits.map((c) => c.id).toList();
      await _pushStackUseCase(commitIds: ids);
      await refreshWorkspace();
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
      return false;
    }
  }
}

final workspaceProvider = StateNotifierProvider<WorkspaceNotifier, WorkspaceState>((ref) {
  final fetch = ref.watch(fetchWorkspaceStateUseCaseProvider);
  final slice = ref.watch(sliceDiffUseCaseProvider);
  final push = ref.watch(pushAtomicStackUseCaseProvider);

  final notifier = WorkspaceNotifier(
    fetchStateUseCase: fetch,
    sliceDiffUseCase: slice,
    pushStackUseCase: push,
  );

  // Auto-refresh when SSE events arrive (named events or generic state JSON payloads)
  ref.listen<AsyncValue<SseEvent>>(gitEventsStreamProvider, (_, next) {
    next.whenData((event) {
      if (event.isWorkspaceUpdate ||
          event.event == 'workspace_changed' ||
          event.event == 'file_changed' ||
          event.event == 'git_diff') {
        notifier.refreshWorkspace();
      }
    });
  });

  return notifier;
});

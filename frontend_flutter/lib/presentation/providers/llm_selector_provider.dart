import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/llm_repository_impl.dart';
import '../../domain/models/atomic_commit_unit.dart';
import '../../domain/models/diff_hunk.dart';
import '../../domain/models/llm_provider_config.dart';
import '../../domain/repositories/i_llm_repository.dart';
import '../../domain/usecases/refine_stack_with_ai_usecase.dart';
import 'workspace_provider.dart';

final llmRepositoryProvider = Provider<ILlmRepository>((ref) {
  final rest = ref.watch(daemonRestDataSourceProvider);
  return LlmRepositoryImpl(rest);
});

final refineStackWithAiUseCaseProvider =
    Provider<RefineStackWithAiUseCase>((ref) {
  final repo = ref.watch(llmRepositoryProvider);
  return RefineStackWithAiUseCase(repo);
});

class LlmSelectorState {
  final List<LlmProviderConfig> providers;
  final LlmProviderConfig selectedProvider;
  final bool isRefining;
  final List<AtomicCommitUnit> suggestedCommits;
  final String? activeStreamingText;
  final String? errorMessage;

  LlmSelectorState({
    this.providers = const [],
    LlmProviderConfig? selectedProvider,
    this.isRefining = false,
    this.suggestedCommits = const [],
    this.activeStreamingText,
    this.errorMessage,
  }) : selectedProvider = selectedProvider ??
            (providers.isNotEmpty
                ? providers.first
                : LlmProviderConfig.standardProviders.first);

  LlmSelectorState copyWith({
    List<LlmProviderConfig>? providers,
    LlmProviderConfig? selectedProvider,
    bool? isRefining,
    List<AtomicCommitUnit>? suggestedCommits,
    String? activeStreamingText,
    String? errorMessage,
  }) {
    return LlmSelectorState(
      providers: providers ?? this.providers,
      selectedProvider: selectedProvider ?? this.selectedProvider,
      isRefining: isRefining ?? this.isRefining,
      suggestedCommits: suggestedCommits ?? this.suggestedCommits,
      activeStreamingText: activeStreamingText ?? this.activeStreamingText,
      errorMessage: errorMessage,
    );
  }
}

class LlmSelectorNotifier extends StateNotifier<LlmSelectorState> {
  final ILlmRepository _llmRepository;
  final Ref _ref;

  LlmSelectorNotifier({
    required ILlmRepository llmRepository,
    required Ref ref,
  })  : _llmRepository = llmRepository,
        _ref = ref,
        super(LlmSelectorState(providers: LlmProviderConfig.standardProviders)) {
    loadProviders();
  }

  Future<void> loadProviders() async {
    try {
      final list = await _llmRepository.getProviders();
      final defaultProv = list.firstWhere(
        (p) => p.isDefault,
        orElse: () => list.first,
      );
      state = state.copyWith(providers: list, selectedProvider: defaultProv);
    } catch (_) {}
  }

  void selectProvider(LlmProviderConfig provider) {
    state = state.copyWith(selectedProvider: provider);
  }

  Future<List<AtomicCommitUnit>> refineUncommittedDiffs({
    String? instructions,
  }) async {
    state = state.copyWith(
      isRefining: true,
      errorMessage: null,
      activeStreamingText: 'Analyzing working tree with ${state.selectedProvider.name}...',
    );

    try {
      final workspace = _ref.read(workspaceProvider);
      final diffs = workspace.uncommittedDiffs;

      final refineUseCase = _ref.read(refineStackWithAiUseCaseProvider);
      final suggestions = await refineUseCase(
        diffs: diffs,
        provider: state.selectedProvider,
        promptInstructions: instructions,
      );

      state = state.copyWith(
        isRefining: false,
        suggestedCommits: suggestions,
        activeStreamingText: 'Refinement completed. ${suggestions.length} atomic commits proposed.',
      );
      return suggestions;
    } catch (e) {
      state = state.copyWith(
        isRefining: false,
        errorMessage: e.toString(),
        activeStreamingText: null,
      );
      return const [];
    }
  }

  Future<({String summary, String description, String type, String? scope})>
      generateConventionalCommit(List<DiffHunk> hunks) async {
    return _llmRepository.generateConventionalCommit(
      hunks: hunks,
      provider: state.selectedProvider,
    );
  }
}

final llmSelectorProvider =
    StateNotifierProvider<LlmSelectorNotifier, LlmSelectorState>((ref) {
  final repo = ref.watch(llmRepositoryProvider);
  return LlmSelectorNotifier(llmRepository: repo, ref: ref);
});

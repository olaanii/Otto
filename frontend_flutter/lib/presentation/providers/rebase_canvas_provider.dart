import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/stack_dependency_graph.dart';
import '../../domain/usecases/rebase_and_reorder_stack_usecase.dart';
import 'workspace_provider.dart';

final rebaseAndReorderStackUseCaseProvider =
    Provider<RebaseAndReorderStackUseCase>((ref) {
  final repo = ref.watch(gitRepositoryProvider);
  return RebaseAndReorderStackUseCase(repo);
});

class RebaseCanvasState {
  final List<String> orderedCommitIds;
  final bool isDirty;
  final bool isRebasing;
  final bool isValid;
  final String? errorMessage;

  const RebaseCanvasState({
    this.orderedCommitIds = const [],
    this.isDirty = false,
    this.isRebasing = false,
    this.isValid = true,
    this.errorMessage,
  });

  RebaseCanvasState copyWith({
    List<String>? orderedCommitIds,
    bool? isDirty,
    bool? isRebasing,
    bool? isValid,
    String? errorMessage,
  }) {
    return RebaseCanvasState(
      orderedCommitIds: orderedCommitIds ?? this.orderedCommitIds,
      isDirty: isDirty ?? this.isDirty,
      isRebasing: isRebasing ?? this.isRebasing,
      isValid: isValid ?? this.isValid,
      errorMessage: errorMessage,
    );
  }
}

class RebaseCanvasNotifier extends StateNotifier<RebaseCanvasState> {
  final RebaseAndReorderStackUseCase _rebaseUseCase;
  final Ref _ref;

  RebaseCanvasNotifier({
    required RebaseAndReorderStackUseCase rebaseUseCase,
    required Ref ref,
  })  : _rebaseUseCase = rebaseUseCase,
        _ref = ref,
        super(const RebaseCanvasState()) {
    _syncWithWorkspace();
  }

  void _syncWithWorkspace() {
    final workspace = _ref.read(workspaceProvider);
    final ids = workspace.stackGraph.commits.map((c) => c.id).toList();
    state = state.copyWith(orderedCommitIds: ids, isDirty: false, isValid: true);
  }

  void reorderCommit(int oldIndex, int newIndex) {
    if (oldIndex == newIndex) return;

    final updated = List<String>.from(state.orderedCommitIds);
    if (newIndex > oldIndex) {
      newIndex -= 1;
    }
    final item = updated.removeAt(oldIndex);
    updated.insert(newIndex, item);

    final workspace = _ref.read(workspaceProvider);
    final isValid = workspace.stackGraph.isValidOrder(updated);

    state = state.copyWith(
      orderedCommitIds: updated,
      isDirty: true,
      isValid: isValid,
      errorMessage: isValid ? null : 'Reorder violation: Parent commit cannot follow its child.',
    );
  }

  Future<bool> executeRebase() async {
    if (!state.isValid) return false;

    state = state.copyWith(isRebasing: true, errorMessage: null);
    try {
      final workspace = _ref.read(workspaceProvider);
      await _rebaseUseCase(
        currentGraph: workspace.stackGraph,
        proposedCommitOrder: state.orderedCommitIds,
      );

      await _ref.read(workspaceProvider.notifier).refreshWorkspace();
      state = state.copyWith(isRebasing: false, isDirty: false);
      return true;
    } catch (e) {
      state = state.copyWith(isRebasing: false, errorMessage: e.toString());
      return false;
    }
  }

  void reset() {
    _syncWithWorkspace();
  }
}

final rebaseCanvasProvider =
    StateNotifierProvider<RebaseCanvasNotifier, RebaseCanvasState>((ref) {
  final useCase = ref.watch(rebaseAndReorderStackUseCaseProvider);
  return RebaseCanvasNotifier(rebaseUseCase: useCase, ref: ref);
});

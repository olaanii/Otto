import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/diff_hunk.dart';

enum DiffViewMode {
  unified,
  split,
}

class DiffViewerState {
  final DiffViewMode mode;
  final String? activeFilePath;
  final Set<String> selectedHunkIds;
  final Set<String> selectedLineIds;
  final bool showSyntaxHighlighting;

  const DiffViewerState({
    this.mode = DiffViewMode.unified,
    this.activeFilePath,
    this.selectedHunkIds = const {},
    this.selectedLineIds = const {},
    this.showSyntaxHighlighting = true,
  });

  DiffViewerState copyWith({
    DiffViewMode? mode,
    String? activeFilePath,
    Set<String>? selectedHunkIds,
    Set<String>? selectedLineIds,
    bool? showSyntaxHighlighting,
  }) {
    return DiffViewerState(
      mode: mode ?? this.mode,
      activeFilePath: activeFilePath ?? this.activeFilePath,
      selectedHunkIds: selectedHunkIds ?? this.selectedHunkIds,
      selectedLineIds: selectedLineIds ?? this.selectedLineIds,
      showSyntaxHighlighting: showSyntaxHighlighting ?? this.showSyntaxHighlighting,
    );
  }
}

class DiffViewerNotifier extends StateNotifier<DiffViewerState> {
  DiffViewerNotifier() : super(const DiffViewerState());

  void setMode(DiffViewMode mode) {
    state = state.copyWith(mode: mode);
  }

  void setActiveFile(String filePath) {
    state = state.copyWith(activeFilePath: filePath);
  }

  void toggleHunkSelection(DiffHunk hunk) {
    final updatedHunks = Set<String>.from(state.selectedHunkIds);
    final updatedLines = Set<String>.from(state.selectedLineIds);

    if (updatedHunks.contains(hunk.id)) {
      updatedHunks.remove(hunk.id);
      for (final l in hunk.lines) {
        updatedLines.remove(l.id);
      }
    } else {
      updatedHunks.add(hunk.id);
      for (final l in hunk.lines) {
        updatedLines.add(l.id);
      }
    }

    state = state.copyWith(
      selectedHunkIds: updatedHunks,
      selectedLineIds: updatedLines,
    );
  }

  void toggleLineSelection(String hunkId, DiffLine line) {
    final updatedLines = Set<String>.from(state.selectedLineIds);
    if (updatedLines.contains(line.id)) {
      updatedLines.remove(line.id);
    } else {
      updatedLines.add(line.id);
    }

    // Auto-include hunk if at least one line is selected
    final updatedHunks = Set<String>.from(state.selectedHunkIds);
    if (updatedLines.contains(line.id)) {
      updatedHunks.add(hunkId);
    }

    state = state.copyWith(
      selectedHunkIds: updatedHunks,
      selectedLineIds: updatedLines,
    );
  }

  void selectAllHunks(List<DiffHunk> hunks) {
    final hunkIds = hunks.map((h) => h.id).toSet();
    final lineIds = hunks.expand((h) => h.lines.map((l) => l.id)).toSet();

    state = state.copyWith(
      selectedHunkIds: hunkIds,
      selectedLineIds: lineIds,
    );
  }

  void clearSelection() {
    state = state.copyWith(
      selectedHunkIds: const {},
      selectedLineIds: const {},
    );
  }

  void reset() {
    state = const DiffViewerState();
  }

  void toggleSyntaxHighlighting() {
    state = state.copyWith(
      showSyntaxHighlighting: !state.showSyntaxHighlighting,
    );
  }
}

final diffViewerProvider =
    StateNotifierProvider<DiffViewerNotifier, DiffViewerState>((ref) {
  return DiffViewerNotifier();
});

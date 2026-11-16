import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/platform/hotkey_service.dart';
import '../../core/platform/window_manager_service.dart';

class HotkeyHudState {
  final bool isHudVisible;
  final bool isPinned;
  final String quickCommitSummary;
  final String quickCommitType;

  const HotkeyHudState({
    this.isHudVisible = false,
    this.isPinned = false,
    this.quickCommitSummary = '',
    this.quickCommitType = 'feat',
  });

  HotkeyHudState copyWith({
    bool? isHudVisible,
    bool? isPinned,
    String? quickCommitSummary,
    String? quickCommitType,
  }) {
    return HotkeyHudState(
      isHudVisible: isHudVisible ?? this.isHudVisible,
      isPinned: isPinned ?? this.isPinned,
      quickCommitSummary: quickCommitSummary ?? this.quickCommitSummary,
      quickCommitType: quickCommitType ?? this.quickCommitType,
    );
  }
}

class HotkeyHudNotifier extends StateNotifier<HotkeyHudState> {
  final WindowManagerService _windowManager;
  final HotkeyService _hotkeyService;

  HotkeyHudNotifier({
    WindowManagerService? windowManager,
    HotkeyService? hotkeyService,
  })  : _windowManager = windowManager ?? WindowManagerService.instance,
        _hotkeyService = hotkeyService ?? HotkeyService.instance,
        super(const HotkeyHudState()) {
    _initHotkey();
  }

  void _initHotkey() {
    _hotkeyService.initialize(
      onHudToggle: toggleHud,
    );
  }

  Future<void> toggleHud() async {
    final nextState = !state.isHudVisible;
    state = state.copyWith(isHudVisible: nextState);
    await _windowManager.setHudOverlayMode(enabled: nextState);
  }

  void setQuickCommitSummary(String summary) {
    state = state.copyWith(quickCommitSummary: summary);
  }

  void setQuickCommitType(String type) {
    state = state.copyWith(quickCommitType: type);
  }

  void togglePinned() {
    final nextPinned = !state.isPinned;
    state = state.copyWith(isPinned: nextPinned);
  }
}

final hotkeyHudProvider =
    StateNotifierProvider<HotkeyHudNotifier, HotkeyHudState>((ref) {
  return HotkeyHudNotifier();
});

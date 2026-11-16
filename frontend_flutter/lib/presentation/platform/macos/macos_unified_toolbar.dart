import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/platform/window_manager_service.dart';
import '../../providers/auth_state_provider.dart';
import '../../providers/hotkey_hud_provider.dart';
import '../../providers/llm_selector_provider.dart';
import '../../providers/workspace_provider.dart';
import 'macos_hig_theme.dart';

/// Workspace views available in the macOS segmented toolbar switcher.
enum MacOSWorkspaceView {
  slicedDiff('Sliced Diff', Icons.data_array_rounded),
  rebasePlayground('Rebase Playground', Icons.alt_route_rounded),
  stackedPipeline('Stacked Pipeline', Icons.account_tree_outlined);

  final String label;
  final IconData icon;
  const MacOSWorkspaceView(this.label, this.icon);
}

/// Unified AppKit window toolbar compliant with macOS Sonoma & Sequoia HIG.
/// Features traffic lights clearance (close, minimize, zoom), window titlebar dragging,
/// centered animated NSSegmentedControl, and Apple Intelligence / GitHub sync actions.
class MacOSUnifiedToolbar extends ConsumerStatefulWidget implements PreferredSizeWidget {
  final MacOSWorkspaceView currentView;
  final ValueChanged<MacOSWorkspaceView> onViewChanged;
  final VoidCallback? onOpenSettings;
  final VoidCallback? onOpenClerkAuth;
  final VoidCallback? onToggleSidebar;
  final bool isSidebarVisible;

  const MacOSUnifiedToolbar({
    super.key,
    required this.currentView,
    required this.onViewChanged,
    this.onOpenSettings,
    this.onOpenClerkAuth,
    this.onToggleSidebar,
    this.isSidebarVisible = true,
  });

  @override
  Size get preferredSize => const Size.fromHeight(52.0);

  @override
  ConsumerState<MacOSUnifiedToolbar> createState() => _MacOSUnifiedToolbarState();
}

class _MacOSUnifiedToolbarState extends ConsumerState<MacOSUnifiedToolbar> {
  bool _isHoveringTrafficLights = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final workspace = ref.watch(workspaceProvider);
    final workspaceNotifier = ref.read(workspaceProvider.notifier);
    final llmState = ref.watch(llmSelectorProvider);
    final authState = ref.watch(authStateProvider);
    final hudNotifier = ref.read(hotkeyHudProvider.notifier);
    final wm = WindowManagerService.instance;

    final isMac = !kIsWeb && Platform.isMacOS;

    return MacOSVisualEffectBox(
      blur: 24.0,
      backgroundColor: MacOSTheme.toolbarBackground(isDark),
      border: Border(
        bottom: BorderSide(
          color: MacOSTheme.border(isDark),
          width: 0.5,
        ),
      ),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onPanStart: (_) {
          if (wm.isDesktop) wm.startDragging();
        },
        child: SizedBox(
          height: 52,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // 1. Traffic Lights Area (Left, ~82px clearance)
              _buildTrafficLightsCluster(context, wm, isMac),

              // Sidebar toggle button (Mac sidebar icon: sidebar.left)
              _buildMacIconButton(
                icon: Icons.view_sidebar_outlined,
                tooltip: widget.isSidebarVisible
                    ? 'Hide Sidebar (⌘S)'
                    : 'Show Sidebar (⌘S)',
                isActive: widget.isSidebarVisible,
                onPressed: widget.onToggleSidebar,
              ),

              const SizedBox(width: 8),

              // Window Proxy Icon & Repository/Branch Context
              _buildWindowProxyTitle(context, workspace.currentBranch, isDark),

              const Spacer(),

              // 2. Centered Apple Segmented Control View Switcher
              _MacOSSegmentedControl(
                selectedView: widget.currentView,
                onViewChanged: widget.onViewChanged,
              ),

              const Spacer(),

              // 3. Right Toolbar Actions
              // AI Slice / Refine Button (Iridescent Siri Glow / Apple Intelligence feel)
              _buildAppleIntelligenceButton(context, ref, llmState),

              const SizedBox(width: 8),

              // Push Stack Button
              _buildPushStackButton(context, workspace, workspaceNotifier, isDark),

              const SizedBox(width: 8),

              // HUD Popover Trigger
              _buildMacIconButton(
                icon: Icons.picture_in_picture_alt_outlined,
                tooltip: 'Toggle Quick HUD (⌃⇧K)',
                onPressed: () => hudNotifier.toggleHud(),
              ),

              const SizedBox(width: 6),

              // Clerk User Avatar / Sign-In Button
              _buildClerkProfilePill(context, authState, isDark),

              const SizedBox(width: 6),

              // Settings Gear Icon Button
              _buildMacIconButton(
                icon: Icons.settings_outlined,
                tooltip: 'Preferences & Guardrails (⌘,)',
                onPressed: widget.onOpenSettings,
              ),

              const SizedBox(width: 14),
            ],
          ),
        ),
      ),
    );
  }

  /// Authentic macOS traffic light buttons (Close, Minimize, Zoom) with hover symbols.
  Widget _buildTrafficLightsCluster(
    BuildContext context,
    WindowManagerService wm,
    bool isMac,
  ) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHoveringTrafficLights = true),
      onExit: (_) => setState(() => _isHoveringTrafficLights = false),
      child: Container(
        width: MacOSTheme.trafficLightToolbarWidth,
        padding: const EdgeInsets.only(left: MacOSTheme.trafficLightLeftMargin),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Close (Red)
            _TrafficLightButton(
              color: MacOSTheme.trafficLightClose,
              borderColor: MacOSTheme.trafficLightCloseBorder,
              symbol: Icons.close,
              isHovered: _isHoveringTrafficLights,
              onPressed: () => wm.close(),
            ),
            const SizedBox(width: MacOSTheme.trafficLightSpacing),

            // Minimize (Yellow)
            _TrafficLightButton(
              color: MacOSTheme.trafficLightMinimize,
              borderColor: MacOSTheme.trafficLightMinimizeBorder,
              symbol: Icons.remove,
              isHovered: _isHoveringTrafficLights,
              onPressed: () => wm.minimize(),
            ),
            const SizedBox(width: MacOSTheme.trafficLightSpacing),

            // Zoom / Fullscreen (Green)
            _TrafficLightButton(
              color: MacOSTheme.trafficLightZoom,
              borderColor: MacOSTheme.trafficLightZoomBorder,
              symbol: Icons.add,
              isHovered: _isHoveringTrafficLights,
              onPressed: () => wm.maximizeOrRestore(),
            ),
          ],
        ),
      ),
    );
  }

  /// Window proxy title showing repository name and branch badge.
  Widget _buildWindowProxyTitle(
    BuildContext context,
    String currentBranch,
    bool isDark,
  ) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Repository Proxy Icon (macOS document/folder proxy icon)
        Container(
          width: 20,
          height: 20,
          decoration: BoxDecoration(
            color: MacOSTheme.systemBlue(isDark).withOpacity(0.16),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Icon(
            Icons.folder_special_rounded,
            size: 13,
            color: MacOSTheme.systemBlue(isDark),
          ),
        ),
        const SizedBox(width: 7),

        // Repo Title
        Text(
          'otto',
          style: MacOSTheme.headline(isDark: isDark).copyWith(
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(width: 6),

        // Branch Pill Badge
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
          decoration: BoxDecoration(
            color: isDark ? const Color(0x28FFFFFF) : const Color(0x14000000),
            borderRadius: BorderRadius.circular(5),
            border: Border.all(
              color: MacOSTheme.subtleBorder(isDark),
              width: 0.5,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.fork_right_rounded,
                size: 11,
                color: MacOSTheme.secondaryLabel(isDark),
              ),
              const SizedBox(width: 3),
              Text(
                currentBranch,
                style: MacOSTheme.code(
                  isDark: isDark,
                  fontSize: 10.5,
                  fontWeight: FontWeight.w500,
                  color: MacOSTheme.secondaryLabel(isDark),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Siri / Apple Intelligence inspired slice & refine button.
  Widget _buildAppleIntelligenceButton(
    BuildContext context,
    WidgetRef ref,
    LlmSelectorState llmState,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: llmState.isRefining
            ? null
            : () {
                ref.read(llmSelectorProvider.notifier).refineUncommittedDiffs(
                      instructions: 'Smart-slice uncommitted diffs into atomic commits',
                    );
              },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: llmState.isRefining
                  ? [
                      MacOSTheme.systemPurple(isDark),
                      MacOSTheme.systemBlue(isDark),
                    ]
                  : [
                      MacOSTheme.systemPurple(isDark).withOpacity(0.18),
                      MacOSTheme.systemBlue(isDark).withOpacity(0.18),
                    ],
            ),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: MacOSTheme.systemPurple(isDark).withOpacity(0.4),
              width: 0.5,
            ),
            boxShadow: llmState.isRefining
                ? [
                    BoxShadow(
                      color: MacOSTheme.systemPurple(isDark).withOpacity(0.35),
                      blurRadius: 10,
                      spreadRadius: 1,
                    )
                  ]
                : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (llmState.isRefining)
                const SizedBox(
                  width: 12,
                  height: 12,
                  child: CircularProgressIndicator(
                    strokeWidth: 1.8,
                    color: Colors.white,
                  ),
                )
              else
                Icon(
                  Icons.auto_awesome_rounded,
                  size: 13,
                  color: MacOSTheme.systemPurple(isDark),
                ),
              const SizedBox(width: 5),
              Text(
                llmState.isRefining ? 'AI Slicing...' : 'AI Refine',
                style: MacOSTheme.subheadline(isDark: isDark).copyWith(
                  fontWeight: FontWeight.w600,
                  fontSize: 11.5,
                  color: llmState.isRefining
                      ? Colors.white
                      : (isDark ? const Color(0xFFF0F0FF) : const Color(0xFF2B2245)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Primary push button for syncing atomic stacked branch to GitHub.
  Widget _buildPushStackButton(
    BuildContext context,
    WorkspaceState workspace,
    WorkspaceNotifier notifier,
    bool isDark,
  ) {
    final isLoading = workspace.isLoading;

    return MouseRegion(
      cursor: isLoading ? SystemMouseCursors.basic : SystemMouseCursors.click,
      child: GestureDetector(
        onTap: isLoading ? null : () => notifier.pushStack(),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 5.5),
          decoration: BoxDecoration(
            color: MacOSTheme.systemBlue(isDark),
            borderRadius: BorderRadius.circular(6),
            boxShadow: [
              BoxShadow(
                color: MacOSTheme.systemBlue(isDark).withOpacity(0.25),
                blurRadius: 4,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isLoading)
                const SizedBox(
                  width: 11,
                  height: 11,
                  child: CircularProgressIndicator(
                    strokeWidth: 1.8,
                    color: Colors.white,
                  ),
                )
              else
                const Icon(
                  Icons.arrow_upward_rounded,
                  size: 13,
                  color: Colors.white,
                ),
              const SizedBox(width: 5),
              const Text(
                'Push Stack',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// AppKit-style icon button with hover feedback.
  Widget _buildMacIconButton({
    required IconData icon,
    required String tooltip,
    required VoidCallback? onPressed,
    bool isActive = false,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Tooltip(
      message: tooltip,
      waitDuration: const Duration(milliseconds: 600),
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: onPressed,
          child: Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: isActive
                  ? (isDark ? const Color(0x33FFFFFF) : const Color(0x1F000000))
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(
              icon,
              size: 16,
              color: isActive
                  ? MacOSTheme.systemBlue(isDark)
                  : MacOSTheme.secondaryLabel(isDark),
            ),
          ),
        ),
      ),
    );
  }

  /// Clerk User Profile pill or sign-in trigger.
  Widget _buildClerkProfilePill(
    BuildContext context,
    AuthState authState,
    bool isDark,
  ) {
    final isAuthenticated = authState.isAuthenticated;
    final userName = authState.session?.email.split('@').first ?? 'Guest';

    return Tooltip(
      message: isAuthenticated ? 'Clerk Session Active: $userName' : 'Sign In with Clerk',
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: widget.onOpenClerkAuth,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
            decoration: BoxDecoration(
              color: isDark ? const Color(0x24FFFFFF) : const Color(0x14000000),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: MacOSTheme.subtleBorder(isDark),
                width: 0.5,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Avatar circle
                Container(
                  width: 18,
                  height: 18,
                  decoration: BoxDecoration(
                    color: isAuthenticated
                        ? MacOSTheme.systemGreen(isDark)
                        : MacOSTheme.systemOrange(isDark),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      userName.substring(0, 1).toUpperCase(),
                      style: const TextStyle(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 5),
                Text(
                  userName,
                  style: MacOSTheme.footnote(isDark: isDark).copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// AppKit NSSegmentedControl styled 3-view switcher with smooth sliding indicator.
class _MacOSSegmentedControl extends StatelessWidget {
  final MacOSWorkspaceView selectedView;
  final ValueChanged<MacOSWorkspaceView> onViewChanged;

  const _MacOSSegmentedControl({
    required this.selectedView,
    required this.onViewChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final views = MacOSWorkspaceView.values;

    return Container(
      height: 28,
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: MacOSTheme.segmentedControlTrack(isDark),
        borderRadius: BorderRadius.circular(7),
        border: Border.all(
          color: MacOSTheme.subtleBorder(isDark),
          width: 0.5,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: views.map((view) {
          final isSelected = view == selectedView;

          return MouseRegion(
            cursor: SystemMouseCursors.click,
            child: GestureDetector(
              onTap: () => onViewChanged(view),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 160),
                curve: Curves.easeOutCubic,
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3.5),
                decoration: BoxDecoration(
                  color: isSelected
                      ? MacOSTheme.segmentedControlPill(isDark)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(5.5),
                  boxShadow: isSelected ? MacOSTheme.segmentedPillShadow : null,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      view.icon,
                      size: 13,
                      color: isSelected
                          ? (isDark ? Colors.white : const Color(0xFF1D1D1F))
                          : MacOSTheme.secondaryLabel(isDark),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      view.label,
                      style: MacOSTheme.subheadline(isDark: isDark).copyWith(
                        fontSize: 11.5,
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                        color: isSelected
                            ? (isDark ? Colors.white : const Color(0xFF1D1D1F))
                            : MacOSTheme.secondaryLabel(isDark),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

/// Single AppKit traffic light circle button.
class _TrafficLightButton extends StatelessWidget {
  final Color color;
  final Color borderColor;
  final IconData symbol;
  final bool isHovered;
  final VoidCallback onPressed;

  const _TrafficLightButton({
    required this.color,
    required this.borderColor,
    required this.symbol,
    required this.isHovered,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onPressed,
        child: Container(
          width: MacOSTheme.trafficLightDiameter,
          height: MacOSTheme.trafficLightDiameter,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            border: Border.all(color: borderColor, width: 0.5),
          ),
          child: isHovered
              ? Center(
                  child: Icon(
                    symbol,
                    size: 8,
                    color: const Color(0xBF000000),
                  ),
                )
              : null,
        ),
      ),
    );
  }
}

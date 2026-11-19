import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../domain/models/clerk_user_session.dart';
import 'windows_fluent_theme.dart';

/// Top CommandBar in Windows 11 Fluent style.
/// Contains Sync Now, Refine with AI, Auto-Pilot toggle, Git branch indicator,
/// and Clerk User profile pill with flyout.
class WindowsCommandBar extends StatefulWidget {
  final String currentBranch;
  final int pendingCommitCount;
  final bool isSyncing;
  final bool isRefining;
  final bool isAutoPilot;
  final ClerkUserSession? userSession;
  final VoidCallback? onSyncNow;
  final VoidCallback? onRefineWithAi;
  final ValueChanged<bool>? onAutoPilotChanged;
  final VoidCallback? onOpenRebase;
  final VoidCallback? onToggleHud;
  final VoidCallback? onOpenSettings;
  final VoidCallback? onOpenShortcuts;
  final VoidCallback? onSignOut;

  const WindowsCommandBar({
    super.key,
    required this.currentBranch,
    this.pendingCommitCount = 0,
    this.isSyncing = false,
    this.isRefining = false,
    this.isAutoPilot = false,
    this.userSession,
    this.onSyncNow,
    this.onRefineWithAi,
    this.onAutoPilotChanged,
    this.onOpenRebase,
    this.onToggleHud,
    this.onOpenSettings,
    this.onOpenShortcuts,
    this.onSignOut,
  });

  @override
  State<WindowsCommandBar> createState() => _WindowsCommandBarState();
}

class _WindowsCommandBarState extends State<WindowsCommandBar>
    with SingleTickerProviderStateMixin {
  late AnimationController _syncRotateController;

  @override
  void initState() {
    super.initState();
    _syncRotateController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    if (widget.isSyncing) {
      _syncRotateController.repeat();
    }
  }

  @override
  void didUpdateWidget(WindowsCommandBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isSyncing && !_syncRotateController.isAnimating) {
      _syncRotateController.repeat();
    } else if (!widget.isSyncing && _syncRotateController.isAnimating) {
      _syncRotateController.stop();
      _syncRotateController.reset();
    }
  }

  @override
  void dispose() {
    _syncRotateController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: const BoxDecoration(
        color: Color(0xFF202020),
        border: Border(
          bottom: BorderSide(
            color: Color(0xFF3A3A3A),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          // 1. Figma Input/ComboBox: Current Branch
          _BranchPill(
            branch: widget.currentBranch,
            tooltip: 'Active Git Branch: ${widget.currentBranch}',
          ),

          const SizedBox(width: 8),

          // 2. Figma Button/Default: Sync now
          FluentButton(
            onPressed: widget.isSyncing ? null : widget.onSyncNow,
            style: FluentButtonStyle.standard,
            height: 32,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            tooltip: 'Push ${widget.pendingCommitCount} stacked commits to GitHub remote',
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                AnimatedBuilder(
                  animation: _syncRotateController,
                  builder: (_, child) {
                    return Transform.rotate(
                      angle: _syncRotateController.value * 2 * math.pi,
                      child: child,
                    );
                  },
                  child: const Icon(
                    Icons.sync_rounded,
                    size: 14,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  widget.isSyncing ? 'Syncing...' : 'Sync now',
                  style: const TextStyle(
                    fontFamily: FluentTypography.fontFamily,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: Colors.white,
                  ),
                ),
                if (widget.pendingCommitCount > 0) ...[
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                    decoration: BoxDecoration(
                      color: const Color(0xFF60CDFF).withOpacity(0.2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '${widget.pendingCommitCount}',
                      style: FluentTypography.captionStrong.copyWith(
                        fontSize: 10,
                        color: const Color(0xFF60CDFF),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(width: 8),

          // 3. Figma Button/Primary: Refine with AI
          FluentButton(
            onPressed: widget.isRefining ? null : widget.onRefineWithAi,
            style: FluentButtonStyle.accent,
            height: 32,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            tooltip: 'AI-assisted atomic diff slicing and Conventional Commit generator',
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (widget.isRefining)
                  const SizedBox(
                    width: 12,
                    height: 12,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
                    ),
                  )
                else
                  const Icon(Icons.auto_awesome_rounded, size: 14, color: Colors.black),
                const SizedBox(width: 6),
                Text(
                  widget.isRefining ? 'AI Refining...' : 'Refine with AI',
                  style: const TextStyle(
                    fontFamily: FluentTypography.fontFamily,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                  ),
                ),
              ],
            ),
          ),

          const Spacer(),

          // 4. Figma Auto-Pilot Label & Switch
          const Text(
            'Auto-Pilot',
            style: TextStyle(
              fontFamily: FluentTypography.fontFamily,
              fontSize: 12,
              fontWeight: FontWeight.w400,
              color: Color(0xFFB3B3B3),
            ),
          ),
          const SizedBox(width: 8),
          FluentToggleSwitch(
            value: widget.isAutoPilot,
            onChanged: (val) => widget.onAutoPilotChanged?.call(val),
            tooltip: 'Automatically slice diffs as IDE agents generate code',
          ),

          const SizedBox(width: 16),

          // 5. Overflow Commands ('...')
          _OverflowMenuButton(
            onOpenRebase: widget.onOpenRebase,
            onToggleHud: widget.onToggleHud,
            onOpenSettings: widget.onOpenSettings,
            onOpenShortcuts: widget.onOpenShortcuts,
          ),

          const SizedBox(width: 8),

          // 6. User Profile Pill
          _ClerkUserPill(
            userSession: widget.userSession,
            onOpenSettings: widget.onOpenSettings,
            onSignOut: widget.onSignOut,
          ),
        ],
      ),
    );
  }
}

/// Figma Input/ComboBox: Active Git Branch selector.
class _BranchPill extends StatelessWidget {
  final String branch;
  final String tooltip;

  const _BranchPill({required this.branch, required this.tooltip});

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Container(
        height: 32,
        width: 128,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: const Color(0xFF3A3A3A),
          borderRadius: BorderRadius.circular(4),
          border: Border.all(
            color: const Color(0xFF484848),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                branch,
                style: const TextStyle(
                  fontFamily: FluentTypography.fontFamily,
                  fontSize: 13,
                  fontWeight: FontWeight.w400,
                  color: Colors.white,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const Icon(
              Icons.keyboard_arrow_down_rounded,
              size: 14,
              color: Color(0xFFB3B3B3),
            ),
          ],
        ),
      ),
    );
  }
}

/// Windows 11 Clerk User Pill with popover flyout.
class _ClerkUserPill extends StatelessWidget {
  final ClerkUserSession? userSession;
  final VoidCallback? onOpenSettings;
  final VoidCallback? onSignOut;

  const _ClerkUserPill({
    required this.userSession,
    this.onOpenSettings,
    this.onSignOut,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final user = userSession;

    if (user == null) {
      return const SizedBox.shrink();
    }

    final avatarText = user.fullName.isNotEmpty
        ? user.fullName.substring(0, 1).toUpperCase()
        : 'U';

    return PopupMenuButton<String>(
      tooltip: 'Clerk User Profile (${user.fullName})',
      offset: const Offset(0, 36),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(
          color: isDark
              ? FluentMicaColors.cardStrokeDark
              : FluentMicaColors.cardStrokeLight,
        ),
      ),
      color: isDark
          ? FluentMicaColors.layerBackgroundDark
          : FluentMicaColors.layerBackgroundLight,
      itemBuilder: (context) => [
        PopupMenuItem(
          enabled: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                user.fullName,
                style: FluentTypography.bodyStrong.copyWith(
                  fontSize: 13,
                  color: isDark
                      ? FluentMicaColors.textPrimaryDark
                      : FluentMicaColors.textPrimaryLight,
                ),
              ),
              Text(
                user.email,
                style: FluentTypography.caption.copyWith(
                  fontSize: 11,
                  color: isDark
                      ? FluentMicaColors.textSecondaryDark
                      : FluentMicaColors.textSecondaryLight,
                ),
              ),
              if (user.isGithubConnected) ...[
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(Icons.link_rounded, size: 12, color: FluentMicaColors.gitAdded),
                    const SizedBox(width: 4),
                    Text(
                      '@${user.githubUsername ?? "github"}',
                      style: FluentTypography.captionStrong.copyWith(
                        fontSize: 11,
                        color: FluentMicaColors.gitAdded,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
        const PopupMenuDivider(),
        PopupMenuItem(
          value: 'settings',
          child: Row(
            children: [
              const Icon(Icons.tune_rounded, size: 14),
              const SizedBox(width: 8),
              Text('Git Guardrail Settings', style: FluentTypography.body.copyWith(fontSize: 12.5)),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'signout',
          child: Row(
            children: [
              const Icon(Icons.logout_rounded, size: 14, color: FluentMicaColors.gitRemoved),
              const SizedBox(width: 8),
              Text(
                'Sign Out',
                style: FluentTypography.body.copyWith(
                  fontSize: 12.5,
                  color: FluentMicaColors.gitRemoved,
                ),
              ),
            ],
          ),
        ),
      ],
      onSelected: (val) {
        if (val == 'settings') onOpenSettings?.call();
        if (val == 'signout') onSignOut?.call();
      },
      child: Container(
        height: 30,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: isDark
              ? FluentMicaColors.layerBackgroundDark
              : FluentMicaColors.layerBackgroundLight,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(
            color: isDark
                ? FluentMicaColors.cardStrokeDark
                : FluentMicaColors.cardStrokeLight,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: 10,
              backgroundColor: isDark
                  ? FluentMicaColors.accentLight
                  : FluentMicaColors.accentIndigo,
              child: Text(
                avatarText,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.black : Colors.white,
                ),
              ),
            ),
            const SizedBox(width: 6),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 100),
              child: Text(
                user.fullName,
                style: FluentTypography.bodyStrong.copyWith(
                  fontSize: 11.5,
                  color: isDark
                      ? FluentMicaColors.textPrimaryDark
                      : FluentMicaColors.textPrimaryLight,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              Icons.keyboard_arrow_down_rounded,
              size: 14,
              color: isDark
                  ? FluentMicaColors.textTertiaryDark
                  : FluentMicaColors.textTertiaryLight,
            ),
          ],
        ),
      ),
    );
  }
}

/// Overflow Command Menu button ('...').
class _OverflowMenuButton extends StatelessWidget {
  final VoidCallback? onOpenRebase;
  final VoidCallback? onToggleHud;
  final VoidCallback? onOpenSettings;
  final VoidCallback? onOpenShortcuts;

  const _OverflowMenuButton({
    this.onOpenRebase,
    this.onToggleHud,
    this.onOpenSettings,
    this.onOpenShortcuts,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return PopupMenuButton<String>(
      tooltip: 'More actions',
      offset: const Offset(0, 36),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(
          color: isDark
              ? FluentMicaColors.cardStrokeDark
              : FluentMicaColors.cardStrokeLight,
        ),
      ),
      color: isDark
          ? FluentMicaColors.layerBackgroundDark
          : FluentMicaColors.layerBackgroundLight,
      itemBuilder: (context) => [
        PopupMenuItem(
          value: 'rebase',
          child: Row(
            children: [
              const Icon(Icons.tune_rounded, size: 14),
              const SizedBox(width: 8),
              Text('Interactive Rebase Canvas', style: FluentTypography.body.copyWith(fontSize: 12.5)),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'hud',
          child: Row(
            children: [
              const Icon(Icons.picture_in_picture_alt_rounded, size: 14),
              const SizedBox(width: 8),
              Text('Toggle Floating HUD Overlay', style: FluentTypography.body.copyWith(fontSize: 12.5)),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'shortcuts',
          child: Row(
            children: [
              const Icon(Icons.keyboard_outlined, size: 14),
              const SizedBox(width: 8),
              Text('Keyboard Shortcuts (Ctrl+/)', style: FluentTypography.body.copyWith(fontSize: 12.5)),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'settings',
          child: Row(
            children: [
              const Icon(Icons.settings_outlined, size: 14),
              const SizedBox(width: 8),
              Text('Workspace & LLM Settings', style: FluentTypography.body.copyWith(fontSize: 12.5)),
            ],
          ),
        ),
      ],
      onSelected: (val) {
        if (val == 'rebase') onOpenRebase?.call();
        if (val == 'hud') onToggleHud?.call();
        if (val == 'shortcuts') onOpenShortcuts?.call();
        if (val == 'settings') onOpenSettings?.call();
      },
      child: Container(
        width: 30,
        height: 28,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(4),
          color: isDark
              ? FluentMicaColors.subtleFillSecondaryDark
              : FluentMicaColors.subtleFillSecondaryLight,
        ),
        child: Icon(
          Icons.more_horiz_rounded,
          size: 16,
          color: isDark
              ? FluentMicaColors.textPrimaryDark
              : FluentMicaColors.textPrimaryLight,
        ),
      ),
    );
  }
}

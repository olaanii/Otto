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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      height: 46,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: isDark
            ? FluentMicaColors.micaBaseDark.withOpacity(0.85)
            : FluentMicaColors.micaBaseLight.withOpacity(0.85),
        border: Border(
          bottom: BorderSide(
            color: isDark
                ? FluentMicaColors.dividerStrokeDark
                : FluentMicaColors.dividerStrokeLight,
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          // 1. Current Branch Pill
          _BranchPill(
            branch: widget.currentBranch,
            tooltip: 'Active Git Branch: ${widget.currentBranch}',
          ),

          const SizedBox(width: 8),
          _VerticalDivider(isDark: isDark),
          const SizedBox(width: 8),

          // 2. Sync Now Button
          FluentButton(
            onPressed: widget.isSyncing ? null : widget.onSyncNow,
            style: FluentButtonStyle.standard,
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
                  child: Icon(
                    Icons.sync_rounded,
                    size: 14,
                    color: isDark
                        ? FluentMicaColors.accentLight
                        : FluentMicaColors.accentDefault,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  widget.isSyncing ? 'Syncing...' : 'Sync Now',
                  style: const TextStyle(fontSize: 12),
                ),
                if (widget.pendingCommitCount > 0) ...[
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                    decoration: BoxDecoration(
                      color: isDark
                          ? FluentMicaColors.accentLight.withOpacity(0.2)
                          : FluentMicaColors.accentDefault.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '${widget.pendingCommitCount}',
                      style: FluentTypography.captionStrong.copyWith(
                        fontSize: 10,
                        color: isDark
                            ? FluentMicaColors.accentLight
                            : FluentMicaColors.accentDefault,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(width: 8),

          // 3. Refine with AI Button
          FluentButton(
            onPressed: widget.isRefining ? null : widget.onRefineWithAi,
            style: FluentButtonStyle.accent,
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
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                else
                  const Icon(Icons.auto_awesome_rounded, size: 14),
                const SizedBox(width: 6),
                Text(
                  widget.isRefining ? 'AI Refining Stack...' : 'Refine with AI',
                  style: const TextStyle(fontSize: 12),
                ),
              ],
            ),
          ),

          const SizedBox(width: 12),
          _VerticalDivider(isDark: isDark),
          const SizedBox(width: 12),

          // 4. Auto-Pilot Toggle
          FluentToggleSwitch(
            value: widget.isAutoPilot,
            onChanged: (val) => widget.onAutoPilotChanged?.call(val),
            label: 'Auto-Pilot',
            tooltip: 'Automatically slice diffs as IDE agents generate code',
          ),

          const Spacer(),

          // 5. Overflow Commands ('...')
          _OverflowMenuButton(
            onOpenRebase: widget.onOpenRebase,
            onToggleHud: widget.onToggleHud,
            onOpenSettings: widget.onOpenSettings,
          ),

          const SizedBox(width: 8),
          _VerticalDivider(isDark: isDark),
          const SizedBox(width: 8),

          // 6. Clerk User Profile Pill
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

/// Active Git Branch pill with fork glyph.
class _BranchPill extends StatelessWidget {
  final String branch;
  final String tooltip;

  const _BranchPill({required this.branch, required this.tooltip});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Tooltip(
      message: tooltip,
      child: Container(
        height: 28,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(
          color: isDark
              ? FluentMicaColors.layerBackgroundDark
              : FluentMicaColors.layerBackgroundLight,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(
            color: isDark
                ? FluentMicaColors.cardStrokeDark
                : FluentMicaColors.cardStrokeLight,
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.fork_right_rounded,
              size: 14,
              color: isDark
                  ? FluentMicaColors.accentLight
                  : FluentMicaColors.accentIndigo,
            ),
            const SizedBox(width: 6),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 140),
              child: Text(
                branch,
                style: FluentTypography.bodyStrong.copyWith(
                  fontSize: 11.5,
                  fontFamily: FluentTypography.monoFamily,
                  color: isDark
                      ? FluentMicaColors.textPrimaryDark
                      : FluentMicaColors.textPrimaryLight,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
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

  const _OverflowMenuButton({
    this.onOpenRebase,
    this.onToggleHud,
    this.onOpenSettings,
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

class _VerticalDivider extends StatelessWidget {
  final bool isDark;
  const _VerticalDivider({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 18,
      color: isDark
          ? FluentMicaColors.dividerStrokeDark
          : FluentMicaColors.dividerStrokeLight,
    );
  }
}

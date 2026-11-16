import 'package:flutter/material.dart';
import '../../../core/platform/window_manager_service.dart';
import 'linux_adwaita_theme.dart';

/// Authentic GNOME Libadwaita Header Bar widget.
/// Implements GNOME HIG specification for top window chrome, window dragging,
/// centered view switcher / title, search toggles, and native Adwaita window controls.
class AdwHeaderBar extends StatelessWidget implements PreferredSizeWidget {
  final Widget? titleWidget;
  final String? title;
  final String? subtitle;
  final Widget? leading;
  final List<Widget>? actions;
  final String? currentBranch;
  final bool isDaemonConnected;
  final bool isSearchActive;
  final VoidCallback? onToggleSearch;
  final VoidCallback? onOpenSettings;
  final VoidCallback? onPushStack;
  final bool isPushing;
  final bool showWindowControls;

  const AdwHeaderBar({
    super.key,
    this.titleWidget,
    this.title,
    this.subtitle,
    this.leading,
    this.actions,
    this.currentBranch,
    this.isDaemonConnected = true,
    this.isSearchActive = false,
    this.onToggleSearch,
    this.onOpenSettings,
    this.onPushStack,
    this.isPushing = false,
    this.showWindowControls = true,
  });

  @override
  Size get preferredSize => const Size.fromHeight(48.0);

  @override
  Widget build(BuildContext context) {
    final tokens = context.adwaita;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final wm = WindowManagerService.instance;

    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onPanStart: (_) {
        if (wm.isDesktop) {
          wm.startDragging();
        }
      },
      onDoubleTap: () {
        if (wm.isDesktop) {
          wm.maximizeOrRestore();
        }
      },
      child: Container(
        height: preferredSize.height,
        decoration: BoxDecoration(
          color: tokens.headerBarBg,
          border: Border(
            bottom: BorderSide(
              color: tokens.border,
              width: 1.0,
            ),
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 10),
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Center title or centered switcher
            Center(
              child: titleWidget ??
                  (title != null
                      ? Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              title!,
                              style: AdwaitaTypography.cantarell.copyWith(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w700,
                                color: tokens.textPrimary,
                              ),
                            ),
                            if (subtitle != null)
                              Text(
                                subtitle!,
                                style: AdwaitaTypography.cantarell.copyWith(
                                  fontSize: 10.5,
                                  color: tokens.textMuted,
                                ),
                              ),
                          ],
                        )
                      : const SizedBox.shrink()),
            ),

            // Left and Right content row
            Row(
              children: [
                // Left section
                if (leading != null)
                  leading!
                else ...[
                  // GNOME App Icon Badge
                  Container(
                    width: 26,
                    height: 26,
                    decoration: BoxDecoration(
                      color: tokens.accent,
                      borderRadius: BorderRadius.circular(7),
                      boxShadow: [
                        BoxShadow(
                          color: tokens.accent.withOpacity(0.3),
                          blurRadius: 4,
                          offset: const Offset(0, 1),
                        ),
                      ],
                    ),
                    child: const Center(
                      child: Text(
                        'O',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),

                  Text(
                    'Otto',
                    style: AdwaitaTypography.cantarell.copyWith(
                      fontWeight: FontWeight.w700,
                      fontSize: 14.5,
                      color: tokens.textPrimary,
                    ),
                  ),

                  // Branch context pill
                  if (currentBranch != null) ...[
                    const SizedBox(width: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: isDark
                            ? Colors.white.withOpacity(0.06)
                            : Colors.black.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: tokens.border,
                          width: 0.5,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.fork_right_rounded,
                            size: 13,
                            color: tokens.textSecondary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            currentBranch!,
                            style: AdwaitaTypography.monospace.copyWith(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: tokens.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  // Sync Status Indicator
                  const SizedBox(width: 10),
                  Tooltip(
                    message: isDaemonConnected
                        ? 'Otto Git Daemon Active & Synced'
                        : 'Daemon Offline',
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: isDaemonConnected
                            ? tokens.success
                            : tokens.destructive,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: (isDaemonConnected
                                    ? tokens.success
                                    : tokens.destructive)
                                .withOpacity(0.4),
                            blurRadius: 4,
                            spreadRadius: 0.5,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],

                const Spacer(),

                // Actions section
                if (actions != null) ...actions!,

                // Search toggle button
                if (onToggleSearch != null) ...[
                  AdwHeaderButton(
                    icon: Icons.search_rounded,
                    tooltip: 'Search Stack & Diffs (Ctrl+F)',
                    isActive: isSearchActive,
                    onPressed: onToggleSearch,
                  ),
                  const SizedBox(width: 4),
                ],

                // Push Stack button (Adwaita Suggested Action)
                if (onPushStack != null) ...[
                  FilledButton(
                    onPressed: isPushing ? null : onPushStack,
                    style: FilledButton.styleFrom(
                      backgroundColor: tokens.accent,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      minimumSize: const Size(0, 30),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                    child: isPushing
                        ? const SizedBox(
                            width: 13,
                            height: 13,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.arrow_upward_rounded, size: 14),
                              const SizedBox(width: 4),
                              Text(
                                'Push Stack',
                                style: AdwaitaTypography.cantarell.copyWith(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                  ),
                  const SizedBox(width: 6),
                ],

                // Settings button
                if (onOpenSettings != null) ...[
                  AdwHeaderButton(
                    icon: Icons.tune_rounded,
                    tooltip: 'Preferences & Guardrails',
                    onPressed: onOpenSettings,
                  ),
                  const SizedBox(width: 6),
                ],

                // Native Libadwaita Window Controls (Minimize, Maximize, Close)
                if (showWindowControls && wm.isDesktop) ...[
                  const _AdwWindowControls(),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Libadwaita flat header button with subtle hover & toggle states.
class AdwHeaderButton extends StatefulWidget {
  final IconData icon;
  final String? tooltip;
  final bool isActive;
  final VoidCallback? onPressed;
  final double size;

  const AdwHeaderButton({
    super.key,
    required this.icon,
    this.tooltip,
    this.isActive = false,
    this.onPressed,
    this.size = 28.0,
  });

  @override
  State<AdwHeaderButton> createState() => _AdwHeaderButtonState();
}

class _AdwHeaderButtonState extends State<AdwHeaderButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final tokens = context.adwaita;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final Color bgColor = widget.isActive
        ? (isDark ? Colors.white.withOpacity(0.16) : Colors.black.withOpacity(0.12))
        : _isHovered
            ? (isDark ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.06))
            : Colors.transparent;

    final button = MouseRegion(
      cursor: widget.onPressed != null
          ? SystemMouseCursors.click
          : SystemMouseCursors.basic,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onPressed,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 140),
          width: widget.size,
          height: widget.size,
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Icon(
            widget.icon,
            size: 16,
            color: widget.isActive
                ? tokens.accent
                : tokens.textPrimary,
          ),
        ),
      ),
    );

    if (widget.tooltip != null) {
      return Tooltip(
        message: widget.tooltip!,
        child: button,
      );
    }
    return button;
  }
}

/// Native GNOME Libadwaita Window Title Controls (Minimize, Maximize, Close).
/// Features official GNOME circular title buttons with close highlight.
class _AdwWindowControls extends StatelessWidget {
  const _AdwWindowControls();

  @override
  Widget build(BuildContext context) {
    final wm = WindowManagerService.instance;
    final tokens = context.adwaita;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          height: 16,
          width: 1,
          margin: const EdgeInsets.symmetric(horizontal: 6),
          color: tokens.border,
        ),
        _AdwTitleButton(
          icon: Icons.remove_rounded,
          tooltip: 'Minimize',
          onTap: wm.minimize,
        ),
        const SizedBox(width: 4),
        _AdwTitleButton(
          icon: Icons.crop_square_rounded,
          tooltip: 'Maximize / Restore',
          onTap: wm.maximizeOrRestore,
        ),
        const SizedBox(width: 4),
        _AdwTitleButton(
          icon: Icons.close_rounded,
          tooltip: 'Close',
          isClose: true,
          onTap: wm.close,
        ),
      ],
    );
  }
}

class _AdwTitleButton extends StatefulWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;
  final bool isClose;

  const _AdwTitleButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
    this.isClose = false,
  });

  @override
  State<_AdwTitleButton> createState() => _AdwTitleButtonState();
}

class _AdwTitleButtonState extends State<_AdwTitleButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final tokens = context.adwaita;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    Color bg;
    Color iconColor;

    if (widget.isClose && _isHovered) {
      bg = tokens.destructive;
      iconColor = Colors.white;
    } else if (_isHovered) {
      bg = isDark ? Colors.white.withOpacity(0.12) : Colors.black.withOpacity(0.08);
      iconColor = tokens.textPrimary;
    } else {
      bg = isDark ? Colors.white.withOpacity(0.06) : Colors.black.withOpacity(0.04);
      iconColor = tokens.textSecondary;
    }

    return Tooltip(
      message: widget.tooltip,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        child: GestureDetector(
          onTap: widget.onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 140),
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: bg,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Icon(
                widget.icon,
                size: 13,
                color: iconColor,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

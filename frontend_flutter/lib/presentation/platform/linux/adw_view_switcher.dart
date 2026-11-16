import 'package:flutter/material.dart';
import 'linux_adwaita_theme.dart';

/// Active workspace views for the Otto GNOME Libadwaita desktop experience.
enum OttoLinuxView {
  slicedDiff('Sliced Diff', Icons.call_split_rounded),
  rebasePlayground('Rebase Playground', Icons.swap_vert_rounded),
  stackPipeline('Stack Pipeline', Icons.account_tree_rounded);

  final String title;
  final IconData icon;
  const OttoLinuxView(this.title, this.icon);
}

/// Metadata item for custom view switcher tabs.
class AdwViewSwitcherItem {
  final OttoLinuxView view;
  final String label;
  final IconData icon;
  final int? badgeCount;
  final String? tooltip;

  const AdwViewSwitcherItem({
    required this.view,
    required this.label,
    required this.icon,
    this.badgeCount,
    this.tooltip,
  });
}

/// Authentic GNOME Libadwaita Pill-Shaped View Switcher.
/// Follows GNOME Libadwaita `AdwViewSwitcher` specifications with smooth pill selection,
/// badge indicators, and high-contrast dark/light styling.
class AdwViewSwitcher extends StatelessWidget {
  final OttoLinuxView activeView;
  final ValueChanged<OttoLinuxView> onViewChanged;
  final int? diffBadgeCount;
  final int? rebaseBadgeCount;
  final int? stackBadgeCount;
  final bool compact;

  const AdwViewSwitcher({
    super.key,
    required this.activeView,
    required this.onViewChanged,
    this.diffBadgeCount,
    this.rebaseBadgeCount,
    this.stackBadgeCount,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = context.adwaita;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final items = [
      AdwViewSwitcherItem(
        view: OttoLinuxView.slicedDiff,
        label: 'Sliced Diff',
        icon: Icons.call_split_rounded,
        badgeCount: diffBadgeCount,
        tooltip: 'Sliced Diff Viewer & Hunk Staging',
      ),
      AdwViewSwitcherItem(
        view: OttoLinuxView.rebasePlayground,
        label: 'Rebase Playground',
        icon: Icons.swap_vert_rounded,
        badgeCount: rebaseBadgeCount,
        tooltip: 'Visual DAG Rebase & Squash Canvas',
      ),
      AdwViewSwitcherItem(
        view: OttoLinuxView.stackPipeline,
        label: 'Stack Pipeline',
        icon: Icons.account_tree_rounded,
        badgeCount: stackBadgeCount,
        tooltip: 'Stacked PR Branch Graph & Policy',
      ),
    ];

    return Container(
      height: 32,
      padding: const EdgeInsets.all(2.5),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.black.withOpacity(0.24)
            : Colors.black.withOpacity(0.06),
        borderRadius: BorderRadius.circular(8.0),
        border: Border.all(
          color: tokens.border,
          width: 0.5,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: items.map((item) {
          final isSelected = item.view == activeView;
          return _AdwViewSwitcherPill(
            item: item,
            isSelected: isSelected,
            compact: compact,
            onTap: () => onViewChanged(item.view),
          );
        }).toList(),
      ),
    );
  }
}

class _AdwViewSwitcherPill extends StatefulWidget {
  final AdwViewSwitcherItem item;
  final bool isSelected;
  final bool compact;
  final VoidCallback onTap;

  const _AdwViewSwitcherPill({
    required this.item,
    required this.isSelected,
    required this.compact,
    required this.onTap,
  });

  @override
  State<_AdwViewSwitcherPill> createState() => _AdwViewSwitcherPillState();
}

class _AdwViewSwitcherPillState extends State<_AdwViewSwitcherPill> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final tokens = context.adwaita;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    Color bg;
    Border? border;
    List<BoxShadow>? shadows;

    if (widget.isSelected) {
      bg = isDark ? tokens.cardBg : Colors.white;
      border = Border.all(
        color: isDark ? tokens.borderCrisp : Colors.black.withOpacity(0.12),
        width: 1.0,
      );
      shadows = [
        BoxShadow(
          color: Colors.black.withOpacity(isDark ? 0.35 : 0.08),
          blurRadius: 4,
          offset: const Offset(0, 1),
        ),
      ];
    } else if (_isHovered) {
      bg = isDark
          ? Colors.white.withOpacity(0.06)
          : Colors.black.withOpacity(0.04);
      border = null;
      shadows = null;
    } else {
      bg = Colors.transparent;
      border = null;
      shadows = null;
    }

    final Color contentColor = widget.isSelected
        ? tokens.textPrimary
        : (_isHovered ? tokens.textPrimary : tokens.textSecondary);

    final pillWidget = MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          curve: Curves.easeOutCubic,
          padding: EdgeInsets.symmetric(
            horizontal: widget.compact ? 8 : 12,
            vertical: 3,
          ),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(6.0),
            border: border,
            boxShadow: shadows,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                widget.item.icon,
                size: 14,
                color: widget.isSelected ? tokens.accent : contentColor,
              ),
              if (!widget.compact) ...[
                const SizedBox(width: 6),
                Text(
                  widget.item.label,
                  style: AdwaitaTypography.cantarell.copyWith(
                    fontSize: 12,
                    fontWeight:
                        widget.isSelected ? FontWeight.w700 : FontWeight.w500,
                    color: contentColor,
                  ),
                ),
              ],
              if (widget.item.badgeCount != null && widget.item.badgeCount! > 0) ...[
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                  decoration: BoxDecoration(
                    color: widget.isSelected
                        ? tokens.accent
                        : (isDark
                            ? Colors.white.withOpacity(0.12)
                            : Colors.black.withOpacity(0.08)),
                    borderRadius: BorderRadius.circular(tokens.pillRadius),
                  ),
                  child: Text(
                    '${widget.item.badgeCount}',
                    style: AdwaitaTypography.monospace.copyWith(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: widget.isSelected ? Colors.white : tokens.textPrimary,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );

    if (widget.item.tooltip != null) {
      return Tooltip(
        message: widget.item.tooltip!,
        child: pillWidget,
      );
    }

    return pillWidget;
  }
}

/// Libadwaita View Switcher Bar for compact / bottom mobile-desktop navigation.
class AdwViewSwitcherBar extends StatelessWidget {
  final OttoLinuxView activeView;
  final ValueChanged<OttoLinuxView> onViewChanged;
  final int? diffBadgeCount;
  final int? rebaseBadgeCount;
  final int? stackBadgeCount;

  const AdwViewSwitcherBar({
    super.key,
    required this.activeView,
    required this.onViewChanged,
    this.diffBadgeCount,
    this.rebaseBadgeCount,
    this.stackBadgeCount,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = context.adwaita;

    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: tokens.headerBarBg,
        border: Border(
          top: BorderSide(color: tokens.border, width: 1.0),
        ),
      ),
      child: Center(
        child: AdwViewSwitcher(
          activeView: activeView,
          onViewChanged: onViewChanged,
          diffBadgeCount: diffBadgeCount,
          rebaseBadgeCount: rebaseBadgeCount,
          stackBadgeCount: stackBadgeCount,
          compact: false,
        ),
      ),
    );
  }
}

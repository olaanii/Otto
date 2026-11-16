import 'package:flutter/material.dart';
import '../../../domain/models/ide_agent_profile.dart';
import '../../widgets/agent/agent_icon_avatar.dart';
import 'windows_fluent_theme.dart';

/// Navigation item definition for Fluent NavigationView.
class FluentNavigationItem {
  final String label;
  final IconData icon;
  final IconData? selectedIcon;
  final int? badgeCount;
  final String? badgeText;
  final Color? badgeColor;

  const FluentNavigationItem({
    required this.label,
    required this.icon,
    this.selectedIcon,
    this.badgeCount,
    this.badgeText,
    this.badgeColor,
  });
}

/// Windows 11 Fluent NavigationView supporting collapsible pane (Expanded ~260px, Compact ~52px),
/// live search box, active agent selector with status indicators, and Fluent selection indicators.
class WindowsNavigationView extends StatefulWidget {
  final int selectedIndex;
  final ValueChanged<int> onIndexChanged;
  final List<FluentNavigationItem> items;
  final List<IdeAgentProfile> activeAgents;
  final ValueChanged<IdeAgentProfile>? onAgentSelected;
  final ValueChanged<IdeAgentProfile>? onSliceAgentChanges;
  final ValueChanged<String>? onSearchChanged;
  final VoidCallback? onOpenSettings;
  final bool initialCollapsed;

  const WindowsNavigationView({
    super.key,
    required this.selectedIndex,
    required this.onIndexChanged,
    required this.items,
    this.activeAgents = const [],
    this.onAgentSelected,
    this.onSliceAgentChanges,
    this.onSearchChanged,
    this.onOpenSettings,
    this.initialCollapsed = false,
  });

  @override
  State<WindowsNavigationView> createState() => _WindowsNavigationViewState();
}

class _WindowsNavigationViewState extends State<WindowsNavigationView> {
  late bool _isCollapsed;
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _isCollapsed = widget.initialCollapsed;
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _toggleCollapsed() {
    setState(() => _isCollapsed = !_isCollapsed);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final paneWidth = _isCollapsed ? 52.0 : 260.0;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
      width: paneWidth,
      decoration: BoxDecoration(
        color: isDark
            ? FluentMicaColors.micaAltDark.withOpacity(0.92)
            : FluentMicaColors.micaAltLight.withOpacity(0.92),
        border: Border(
          right: BorderSide(
            color: isDark
                ? FluentMicaColors.dividerStrokeDark
                : FluentMicaColors.dividerStrokeLight,
            width: 1,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. Pane Header & Collapse Button
          Padding(
            padding: const EdgeInsets.only(top: 8.0, left: 6.0, right: 6.0, bottom: 4.0),
            child: Row(
              children: [
                _NavIconButton(
                  icon: Icons.menu_rounded,
                  tooltip: _isCollapsed ? 'Expand Navigation Pane' : 'Collapse Navigation Pane',
                  onTap: _toggleCollapsed,
                ),
                if (!_isCollapsed) ...[
                  const SizedBox(width: 8),
                  Text(
                    'Workspace',
                    style: FluentTypography.bodyStrong.copyWith(
                      fontSize: 13,
                      color: isDark
                          ? FluentMicaColors.textPrimaryDark
                          : FluentMicaColors.textPrimaryLight,
                    ),
                  ),
                ],
              ],
            ),
          ),

          // 2. Fluent Search Box
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
            child: _isCollapsed
                ? _NavIconButton(
                    icon: Icons.search_rounded,
                    tooltip: 'Search (Expand to view)',
                    onTap: _toggleCollapsed,
                  )
                : _FluentSearchBox(
                    controller: _searchController,
                    focusNode: _searchFocusNode,
                    onChanged: (val) {
                      widget.onSearchChanged?.call(val);
                      setState(() {});
                    },
                  ),
          ),

          const SizedBox(height: 6),

          // 3. Primary Navigation Items
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 6.0),
              children: [
                for (int i = 0; i < widget.items.length; i++)
                  _NavTile(
                    item: widget.items[i],
                    isSelected: widget.selectedIndex == i,
                    isCollapsed: _isCollapsed,
                    onTap: () => widget.onIndexChanged(i),
                  ),

                const SizedBox(height: 12),

                // 4. Active IDE AI Agents Section
                if (widget.activeAgents.isNotEmpty) ...[
                  if (!_isCollapsed)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 6.0),
                      child: Row(
                        children: [
                          Icon(
                            Icons.smart_toy_outlined,
                            size: 13,
                            color: isDark
                                ? FluentMicaColors.accentLight
                                : FluentMicaColors.accentIndigo,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Active IDE Agents',
                            style: FluentTypography.captionStrong.copyWith(
                              fontSize: 11,
                              color: isDark
                                  ? FluentMicaColors.textSecondaryDark
                                  : FluentMicaColors.textSecondaryLight,
                              letterSpacing: 0.3,
                            ),
                          ),
                          const Spacer(),
                          Text(
                            '${widget.activeAgents.where((a) => a.isActive).length} online',
                            style: FluentTypography.caption.copyWith(
                              fontSize: 10,
                              color: FluentMicaColors.gitAdded,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4.0),
                      child: Divider(
                        height: 1,
                        color: isDark
                            ? FluentMicaColors.dividerStrokeDark
                            : FluentMicaColors.dividerStrokeLight,
                      ),
                    ),

                  // Agent Rows
                  for (final agent in widget.activeAgents)
                    _AgentNavRow(
                      agent: agent,
                      isCollapsed: _isCollapsed,
                      onTap: () => widget.onAgentSelected?.call(agent),
                      onSlice: () => widget.onSliceAgentChanges?.call(agent),
                    ),
                ],
              ],
            ),
          ),

          // 5. Pane Footer (Settings & Collapse Toggle)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6.0, vertical: 8.0),
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(
                  color: isDark
                      ? FluentMicaColors.dividerStrokeDark
                      : FluentMicaColors.dividerStrokeLight,
                  width: 1,
                ),
              ),
            ),
            child: _NavTile(
              item: const FluentNavigationItem(
                label: 'Settings & Policy',
                icon: Icons.settings_outlined,
                selectedIcon: Icons.settings,
              ),
              isSelected: false,
              isCollapsed: _isCollapsed,
              onTap: widget.onOpenSettings,
            ),
          ),
        ],
      ),
    );
  }
}

/// Navigation Tile with Windows 11 pill selection indicator.
class _NavTile extends StatefulWidget {
  final FluentNavigationItem item;
  final bool isSelected;
  final bool isCollapsed;
  final VoidCallback? onTap;

  const _NavTile({
    required this.item,
    required this.isSelected,
    required this.isCollapsed,
    this.onTap,
  });

  @override
  State<_NavTile> createState() => _NavTileState();
}

class _NavTileState extends State<_NavTile> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final accent = isDark ? FluentMicaColors.accentLight : FluentMicaColors.accentDefault;

    Color bg;
    if (widget.isSelected) {
      bg = isDark
          ? FluentMicaColors.subtleFillTertiaryDark
          : FluentMicaColors.subtleFillTertiaryLight;
    } else if (_isHovered) {
      bg = isDark
          ? FluentMicaColors.subtleFillSecondaryDark
          : FluentMicaColors.subtleFillSecondaryLight;
    } else {
      bg = Colors.transparent;
    }

    final fg = widget.isSelected
        ? (isDark ? FluentMicaColors.textPrimaryDark : FluentMicaColors.textPrimaryLight)
        : (isDark ? FluentMicaColors.textSecondaryDark : FluentMicaColors.textSecondaryLight);

    final tileContent = MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 140),
          height: 38,
          margin: const EdgeInsets.symmetric(vertical: 2.0),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(4),
          ),
          child: Stack(
            alignment: Alignment.centerLeft,
            children: [
              // Left Selection Indicator Pill
              if (widget.isSelected)
                Positioned(
                  left: 0,
                  top: 10,
                  bottom: 10,
                  child: Container(
                    width: 3.5,
                    decoration: BoxDecoration(
                      color: accent,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),

              // Content Row
              Padding(
                padding: EdgeInsets.only(
                  left: widget.isCollapsed ? 12.0 : 14.0,
                  right: 10.0,
                ),
                child: Row(
                  children: [
                    Icon(
                      widget.isSelected
                          ? (widget.item.selectedIcon ?? widget.item.icon)
                          : widget.item.icon,
                      size: 16,
                      color: widget.isSelected ? accent : fg,
                    ),
                    if (!widget.isCollapsed) ...[
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          widget.item.label,
                          style: FluentTypography.body.copyWith(
                            fontSize: 12.5,
                            fontWeight:
                                widget.isSelected ? FontWeight.w600 : FontWeight.w400,
                            color: fg,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (widget.item.badgeCount != null && widget.item.badgeCount! > 0)
                        Container(
                          padding:
                              const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                          decoration: BoxDecoration(
                            color: widget.item.badgeColor ??
                                (isDark ? const Color(0xFF333333) : const Color(0xFFE5E5E5)),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '${widget.item.badgeCount}',
                            style: FluentTypography.captionStrong.copyWith(
                              fontSize: 10,
                              fontFeatures: const [FontFeature.tabularFigures()],
                              color: isDark ? Colors.white : Colors.black87,
                            ),
                          ),
                        )
                      else if (widget.item.badgeText != null)
                        Container(
                          padding:
                              const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                          decoration: BoxDecoration(
                            color: widget.item.badgeColor ?? accent.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            widget.item.badgeText!,
                            style: FluentTypography.captionStrong.copyWith(
                              fontSize: 9.5,
                              color: widget.item.badgeColor != null ? Colors.white : accent,
                            ),
                          ),
                        ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );

    if (widget.isCollapsed) {
      return Tooltip(
        message: widget.item.label,
        waitDuration: const Duration(milliseconds: 400),
        child: tileContent,
      );
    }

    return tileContent;
  }
}

/// Agent row item with online status dot and AI change slicing action.
class _AgentNavRow extends StatefulWidget {
  final IdeAgentProfile agent;
  final bool isCollapsed;
  final VoidCallback? onTap;
  final VoidCallback? onSlice;

  const _AgentNavRow({
    required this.agent,
    required this.isCollapsed,
    this.onTap,
    this.onSlice,
  });

  @override
  State<_AgentNavRow> createState() => _AgentNavRowState();
}

class _AgentNavRowState extends State<_AgentNavRow> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final bg = _isHovered
        ? (isDark
            ? FluentMicaColors.subtleFillSecondaryDark
            : FluentMicaColors.subtleFillSecondaryLight)
        : Colors.transparent;

    final statusColor = widget.agent.isActive
        ? FluentMicaColors.gitAdded
        : (isDark ? const Color(0xFF71717A) : const Color(0xFFA1A1AA));

    final rowWidget = MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 140),
          height: 38,
          margin: const EdgeInsets.symmetric(vertical: 2.0),
          padding: EdgeInsets.symmetric(
            horizontal: widget.isCollapsed ? 12.0 : 10.0,
          ),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(4),
          ),
          child: Row(
            children: [
              // Agent Icon with status badge
              Stack(
                clipBehavior: Clip.none,
                children: [
                  AgentIconAvatar(agent: widget.agent, size: 20),
                  Positioned(
                    bottom: -1,
                    right: -1,
                    child: Container(
                      width: 7,
                      height: 7,
                      decoration: BoxDecoration(
                        color: statusColor,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isDark ? const Color(0xFF202020) : Colors.white,
                          width: 1.5,
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              if (!widget.isCollapsed) ...[
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.agent.name,
                        style: FluentTypography.bodyStrong.copyWith(
                          fontSize: 12,
                          color: isDark
                              ? FluentMicaColors.textPrimaryDark
                              : FluentMicaColors.textPrimaryLight,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        widget.agent.isActive ? 'Active changes' : 'Idle',
                        style: TextStyle(
                          fontSize: 10,
                          color: statusColor,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                if (_isHovered && widget.onSlice != null)
                  Tooltip(
                    message: 'Slice ${widget.agent.name} diffs into atomic commit',
                    child: GestureDetector(
                      onTap: widget.onSlice,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: isDark
                              ? FluentMicaColors.accentLight.withOpacity(0.18)
                              : FluentMicaColors.accentDefault.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(3),
                        ),
                        child: Text(
                          'Slice',
                          style: FluentTypography.captionStrong.copyWith(
                            fontSize: 10,
                            color: isDark
                                ? FluentMicaColors.accentLight
                                : FluentMicaColors.accentDefault,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ],
          ),
        ),
      ),
    );

    if (widget.isCollapsed) {
      return Tooltip(
        message: '${widget.agent.name} (${widget.agent.isActive ? "Active" : "Idle"})',
        child: rowWidget,
      );
    }

    return rowWidget;
  }
}

/// Fluent Navigation Icon Button.
class _NavIconButton extends StatefulWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  const _NavIconButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  @override
  State<_NavIconButton> createState() => _NavIconButtonState();
}

class _NavIconButtonState extends State<_NavIconButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Tooltip(
      message: widget.tooltip,
      waitDuration: const Duration(milliseconds: 500),
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() => _isHovered = false),
        child: GestureDetector(
          onTap: widget.onTap,
          child: Container(
            width: 36,
            height: 32,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: _isHovered
                  ? (isDark
                      ? FluentMicaColors.subtleFillSecondaryDark
                      : FluentMicaColors.subtleFillSecondaryLight)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Icon(
              widget.icon,
              size: 16,
              color: isDark
                  ? FluentMicaColors.textPrimaryDark
                  : FluentMicaColors.textPrimaryLight,
            ),
          ),
        ),
      ),
    );
  }
}

/// Windows 11 Fluent Search Box with clear button and focus ring.
class _FluentSearchBox extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final ValueChanged<String>? onChanged;

  const _FluentSearchBox({
    required this.controller,
    required this.focusNode,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      height: 32,
      decoration: BoxDecoration(
        color: isDark
            ? FluentMicaColors.layerBackgroundDark
            : FluentMicaColors.layerBackgroundLight,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: focusNode.hasFocus
              ? (isDark ? FluentMicaColors.accentLight : FluentMicaColors.accentDefault)
              : (isDark ? FluentMicaColors.cardStrokeDark : FluentMicaColors.cardStrokeLight),
          width: focusNode.hasFocus ? 1.5 : 1.0,
        ),
      ),
      child: Row(
        children: [
          const SizedBox(width: 8),
          Icon(
            Icons.search_rounded,
            size: 14,
            color: isDark
                ? FluentMicaColors.textTertiaryDark
                : FluentMicaColors.textTertiaryLight,
          ),
          const SizedBox(width: 6),
          Expanded(
            child: TextField(
              controller: controller,
              focusNode: focusNode,
              onChanged: onChanged,
              style: FluentTypography.body.copyWith(
                fontSize: 12,
                color: isDark
                    ? FluentMicaColors.textPrimaryDark
                    : FluentMicaColors.textPrimaryLight,
              ),
              decoration: InputDecoration(
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 8),
                border: InputBorder.none,
                hintText: 'Search commits, diffs...',
                hintStyle: FluentTypography.body.copyWith(
                  fontSize: 12,
                  color: isDark
                      ? FluentMicaColors.textTertiaryDark
                      : FluentMicaColors.textTertiaryLight,
                ),
              ),
            ),
          ),
          if (controller.text.isNotEmpty)
            GestureDetector(
              onTap: () {
                controller.clear();
                onChanged?.call('');
              },
              child: Padding(
                padding: const EdgeInsets.only(right: 6.0),
                child: Icon(
                  Icons.close_rounded,
                  size: 14,
                  color: isDark
                      ? FluentMicaColors.textTertiaryDark
                      : FluentMicaColors.textTertiaryLight,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'linux_adwaita_theme.dart';

/// Authentic Libadwaita Preferences Group.
/// Encloses related preference rows inside a unified card with 12px border radius,
/// crisp outlines, and optional section title & description.
class AdwPreferencesGroup extends StatelessWidget {
  final String? title;
  final String? description;
  final Widget? headerSuffix;
  final List<Widget> children;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry margin;

  const AdwPreferencesGroup({
    super.key,
    this.title,
    this.description,
    this.headerSuffix,
    required this.children,
    this.padding = EdgeInsets.zero,
    this.margin = const EdgeInsets.only(bottom: 20),
  });

  @override
  Widget build(BuildContext context) {
    final tokens = context.adwaita;

    return Padding(
      padding: margin,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Section title & description
          if (title != null || description != null)
            Padding(
              padding: const EdgeInsets.only(left: 6, bottom: 8),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (title != null)
                          Text(
                            title!,
                            style: AdwaitaTypography.cantarell.copyWith(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w700,
                              color: tokens.textSecondary,
                              letterSpacing: 0.1,
                            ),
                          ),
                        if (description != null) ...[
                          const SizedBox(height: 2),
                          Text(
                            description!,
                            style: AdwaitaTypography.cantarell.copyWith(
                              fontSize: 11.5,
                              color: tokens.textMuted,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  if (headerSuffix != null) headerSuffix!,
                ],
              ),
            ),

          // Enclosed group card
          Container(
            decoration: BoxDecoration(
              color: tokens.cardBg,
              borderRadius: BorderRadius.circular(tokens.cardRadius),
              border: Border.all(
                color: tokens.border,
                width: 1.0,
              ),
            ),
            clipBehavior: Clip.antiAlias,
            child: ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: padding,
              itemCount: children.length,
              separatorBuilder: (context, index) => Divider(
                height: 1,
                thickness: 1,
                color: tokens.border,
              ),
              itemBuilder: (context, index) => children[index],
            ),
          ),
        ],
      ),
    );
  }
}

/// Libadwaita Action Row for preferences and list items.
/// Conforms to GNOME HIG specs: Leading icon, Title, Subtitle, and Trailing controls.
class AdwActionRow extends StatefulWidget {
  final Widget? icon;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  final bool enabled;
  final EdgeInsetsGeometry padding;

  const AdwActionRow({
    super.key,
    this.icon,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
    this.enabled = true,
    this.padding = const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
  });

  @override
  State<AdwActionRow> createState() => _AdwActionRowState();
}

class _AdwActionRowState extends State<AdwActionRow> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final tokens = context.adwaita;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final isClickable = widget.enabled && widget.onTap != null;

    final Color rowBg = (_isHovered && isClickable)
        ? (isDark ? Colors.white.withOpacity(0.04) : Colors.black.withOpacity(0.03))
        : Colors.transparent;

    return MouseRegion(
      cursor: isClickable ? SystemMouseCursors.click : SystemMouseCursors.basic,
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: isClickable ? widget.onTap : null,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 140),
          color: rowBg,
          padding: widget.padding,
          child: Row(
            children: [
              // Leading Icon
              if (widget.icon != null) ...[
                widget.icon!,
                const SizedBox(width: 14),
              ],

              // Title and Subtitle
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      widget.title,
                      style: AdwaitaTypography.cantarell.copyWith(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: widget.enabled
                            ? tokens.textPrimary
                            : tokens.textMuted,
                      ),
                    ),
                    if (widget.subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        widget.subtitle!,
                        style: AdwaitaTypography.cantarell.copyWith(
                          fontSize: 11.5,
                          color: tokens.textSecondary,
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              // Trailing Widget
              if (widget.trailing != null) ...[
                const SizedBox(width: 12),
                widget.trailing!,
              ] else if (isClickable) ...[
                const SizedBox(width: 12),
                Icon(
                  Icons.chevron_right_rounded,
                  size: 18,
                  color: tokens.textMuted,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Libadwaita Action Row with an integrated Switch.
class AdwSwitchRow extends StatelessWidget {
  final Widget? icon;
  final String title;
  final String? subtitle;
  final bool value;
  final ValueChanged<bool>? onChanged;
  final bool enabled;

  const AdwSwitchRow({
    super.key,
    this.icon,
    required this.title,
    this.subtitle,
    required this.value,
    this.onChanged,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = context.adwaita;

    return AdwActionRow(
      icon: icon,
      title: title,
      subtitle: subtitle,
      enabled: enabled,
      onTap: enabled && onChanged != null ? () => onChanged!(!value) : null,
      trailing: Transform.scale(
        scale: 0.85,
        child: Switch(
          value: value,
          activeColor: tokens.accent,
          onChanged: enabled ? onChanged : null,
        ),
      ),
    );
  }
}

/// Libadwaita Action Row with an inline Text Field / Entry.
class AdwEntryRow extends StatelessWidget {
  final Widget? icon;
  final String title;
  final String? value;
  final String? hintText;
  final ValueChanged<String>? onChanged;
  final TextEditingController? controller;

  const AdwEntryRow({
    super.key,
    this.icon,
    required this.title,
    this.value,
    this.hintText,
    this.onChanged,
    this.controller,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = context.adwaita;

    return AdwActionRow(
      icon: icon,
      title: title,
      trailing: SizedBox(
        width: 180,
        height: 32,
        child: TextField(
          controller: controller,
          onChanged: onChanged,
          style: AdwaitaTypography.cantarell.copyWith(
            fontSize: 12,
            color: tokens.textPrimary,
          ),
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: AdwaitaTypography.cantarell.copyWith(
              fontSize: 12,
              color: tokens.textMuted,
            ),
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            filled: true,
            fillColor: Theme.of(context).brightness == Brightness.dark
                ? Colors.black.withOpacity(0.2)
                : Colors.black.withOpacity(0.04),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(6),
              borderSide: BorderSide(color: tokens.border, width: 0.5),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(6),
              borderSide: BorderSide(color: tokens.accent, width: 1.0),
            ),
          ),
        ),
      ),
    );
  }
}

/// Flat Libadwaita Card widget with 12px border radius, subtle outline,
/// and optional header, body, and action footer.
class AdwCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry margin;
  final VoidCallback? onTap;
  final Color? backgroundColor;
  final Border? customBorder;

  const AdwCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(14),
    this.margin = EdgeInsets.zero,
    this.onTap,
    this.backgroundColor,
    this.customBorder,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = context.adwaita;

    final card = Container(
      margin: margin,
      padding: padding,
      decoration: BoxDecoration(
        color: backgroundColor ?? tokens.cardBg,
        borderRadius: BorderRadius.circular(tokens.cardRadius),
        border: customBorder ?? Border.all(
          color: tokens.border,
          width: 1.0,
        ),
      ),
      child: child,
    );

    if (onTap != null) {
      return MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: onTap,
          child: card,
        ),
      );
    }

    return card;
  }
}

/// Libadwaita Pill Badge widget for conventional commit types,
/// LOC indicators, and active status tags.
enum AdwBadgeVariant {
  accent,
  success,
  warning,
  destructive,
  neutral,
}

class AdwBadge extends StatelessWidget {
  final String label;
  final IconData? icon;
  final AdwBadgeVariant variant;
  final VoidCallback? onTap;

  const AdwBadge({
    super.key,
    required this.label,
    this.icon,
    this.variant = AdwBadgeVariant.neutral,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = context.adwaita;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final (Color bg, Color fg) = switch (variant) {
      AdwBadgeVariant.accent => (
          tokens.accent.withOpacity(isDark ? 0.2 : 0.12),
          tokens.accent,
        ),
      AdwBadgeVariant.success => (
          tokens.success.withOpacity(isDark ? 0.2 : 0.12),
          tokens.success,
        ),
      AdwBadgeVariant.warning => (
          tokens.warning.withOpacity(isDark ? 0.2 : 0.14),
          isDark ? tokens.warning : const Color(0xFF9E6C00),
        ),
      AdwBadgeVariant.destructive => (
          tokens.destructive.withOpacity(isDark ? 0.2 : 0.12),
          tokens.destructive,
        ),
      AdwBadgeVariant.neutral => (
          isDark ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.06),
          tokens.textSecondary,
        ),
    };

    final content = Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(tokens.pillRadius),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 11, color: fg),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: AdwaitaTypography.cantarell.copyWith(
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
              color: fg,
            ),
          ),
        ],
      ),
    );

    if (onTap != null) {
      return MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: onTap,
          child: content,
        ),
      );
    }

    return content;
  }
}

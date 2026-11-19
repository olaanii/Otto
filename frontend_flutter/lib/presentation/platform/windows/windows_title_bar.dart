import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';
import '../../../core/platform/window_manager_service.dart';
import 'windows_fluent_theme.dart';

/// Authentic Windows 11 Custom Window Titlebar with caption controls,
/// Mica/Acrylic tint, drag region, double-click maximize, and app branding.
class WindowsTitleBar extends StatefulWidget implements PreferredSizeWidget {
  final String title;
  final String? subtitle;
  final Widget? leading;
  final List<Widget>? customActions;
  final double height;

  const WindowsTitleBar({
    super.key,
    this.title = 'Otto',
    this.subtitle,
    this.leading,
    this.customActions,
    this.height = 32.0,
  });

  @override
  Size get preferredSize => Size.fromHeight(height);

  @override
  State<WindowsTitleBar> createState() => _WindowsTitleBarState();
}

class _WindowsTitleBarState extends State<WindowsTitleBar> with WindowListener {
  bool _isMaximized = false;
  final WindowManagerService _wm = WindowManagerService.instance;

  @override
  void initState() {
    super.initState();
    if (_wm.isDesktop) {
      windowManager.addListener(this);
      _checkMaximizedState();
    }
  }

  @override
  void dispose() {
    if (_wm.isDesktop) {
      windowManager.removeListener(this);
    }
    super.dispose();
  }

  Future<void> _checkMaximizedState() async {
    if (!_wm.isDesktop) return;
    try {
      final isMax = await windowManager.isMaximized();
      if (mounted) setState(() => _isMaximized = isMax);
    } catch (_) {}
  }

  @override
  void onWindowMaximize() {
    if (mounted) setState(() => _isMaximized = true);
  }

  @override
  void onWindowUnmaximize() {
    if (mounted) setState(() => _isMaximized = false);
  }

  @override
  void onWindowRestore() {
    if (mounted) setState(() => _isMaximized = false);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      height: widget.height,
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
          // Left: App Brand & Icon
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onPanStart: (_) => _wm.startDragging(),
            onDoubleTap: () => _wm.maximizeOrRestore(),
            child: Padding(
              padding: const EdgeInsets.only(left: 12.0, right: 8.0),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  widget.leading ??
                      Container(
                        width: 16,
                        height: 16,
                        decoration: BoxDecoration(
                          color: const Color(0xFF60CDFF),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                  const SizedBox(width: 8),
                  Text(
                    widget.title,
                    style: const TextStyle(
                      fontFamily: FluentTypography.fontFamily,
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                      color: Colors.white,
                    ),
                  ),
                  if (widget.subtitle != null) ...[
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 6.0),
                      child: Text(
                        '—',
                        style: TextStyle(
                          color: isDark
                              ? FluentMicaColors.textTertiaryDark
                              : FluentMicaColors.textTertiaryLight,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    Text(
                      widget.subtitle!,
                      style: FluentTypography.caption.copyWith(
                        color: isDark
                            ? FluentMicaColors.textSecondaryDark
                            : FluentMicaColors.textSecondaryLight,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),

          // Center: Flexible Draggable Area
          Expanded(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onPanStart: (_) => _wm.startDragging(),
              onDoubleTap: () => _wm.maximizeOrRestore(),
              child: const SizedBox.expand(),
            ),
          ),

          // Custom Actions (e.g. quick search or settings shortcut)
          if (widget.customActions != null) ...widget.customActions!,

          // Right: Windows 11 Caption Buttons
          if (!kIsWeb && (Platform.isWindows || Platform.isMacOS || Platform.isLinux))
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _CaptionButton(
                  tooltip: 'Minimize',
                  height: widget.height,
                  icon: const _MinimizeIcon(),
                  onPressed: () => _wm.minimize(),
                ),
                _CaptionButton(
                  tooltip: _isMaximized ? 'Restore Down' : 'Maximize',
                  height: widget.height,
                  icon: _isMaximized
                      ? const _RestoreIcon()
                      : const _MaximizeIcon(),
                  onPressed: () => _wm.maximizeOrRestore(),
                ),
                _CaptionButton(
                  tooltip: 'Close',
                  height: widget.height,
                  isClose: true,
                  icon: const _CloseIcon(),
                  onPressed: () => _wm.close(),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

/// Windows 11 Caption Button with precise hover physics.
class _CaptionButton extends StatefulWidget {
  final VoidCallback onPressed;
  final Widget icon;
  final double height;
  final bool isClose;
  final String tooltip;

  const _CaptionButton({
    required this.onPressed,
    required this.icon,
    required this.height,
    this.isClose = false,
    required this.tooltip,
  });

  @override
  State<_CaptionButton> createState() => _CaptionButtonState();
}

class _CaptionButtonState extends State<_CaptionButton> {
  bool _isHovered = false;
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    Color bg;
    if (widget.isClose) {
      if (_isPressed) {
        bg = FluentMicaColors.closeButtonPressed;
      } else if (_isHovered) {
        bg = FluentMicaColors.closeButtonHover;
      } else {
        bg = Colors.transparent;
      }
    } else {
      if (_isPressed) {
        bg = isDark ? const Color(0x1AFFFFFF) : const Color(0x14000000);
      } else if (_isHovered) {
        bg = isDark ? FluentMicaColors.captionHoverDark : FluentMicaColors.captionHoverLight;
      } else {
        bg = Colors.transparent;
      }
    }

    final iconColor = (widget.isClose && _isHovered)
        ? Colors.white
        : (isDark
            ? FluentMicaColors.textPrimaryDark
            : FluentMicaColors.textPrimaryLight);

    return Tooltip(
      message: widget.tooltip,
      waitDuration: const Duration(milliseconds: 700),
      child: MouseRegion(
        cursor: SystemMouseCursors.basic,
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) => setState(() {
          _isHovered = false;
          _isPressed = false;
        }),
        child: GestureDetector(
          onTapDown: (_) => setState(() => _isPressed = true),
          onTapUp: (_) => setState(() => _isPressed = false),
          onTapCancel: () => setState(() => _isPressed = false),
          onTap: widget.onPressed,
          child: Container(
            width: 46,
            height: widget.height,
            color: bg,
            alignment: Alignment.center,
            child: IconTheme(
              data: IconThemeData(color: iconColor, size: 10),
              child: widget.icon,
            ),
          ),
        ),
      ),
    );
  }
}

/// Precise custom painted Windows 11 Minimize glyph (`—`).
class _MinimizeIcon extends StatelessWidget {
  const _MinimizeIcon();

  @override
  Widget build(BuildContext context) {
    final color = IconTheme.of(context).color ?? Colors.grey;
    return CustomPaint(
      size: const Size(10, 1),
      painter: _SolidLinePainter(color),
    );
  }
}

class _SolidLinePainter extends CustomPainter {
  final Color color;
  _SolidLinePainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.0;
    canvas.drawLine(const Offset(0, 0.5), Offset(size.width, 0.5), paint);
  }

  @override
  bool shouldRepaint(_SolidLinePainter oldDelegate) => oldDelegate.color != color;
}

/// Precise custom painted Windows 11 Maximize glyph (`□`).
class _MaximizeIcon extends StatelessWidget {
  const _MaximizeIcon();

  @override
  Widget build(BuildContext context) {
    final color = IconTheme.of(context).color ?? Colors.grey;
    return CustomPaint(
      size: const Size(10, 10),
      painter: _SquarePainter(color),
    );
  }
}

class _SquarePainter extends CustomPainter {
  final Color color;
  _SquarePainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    canvas.drawRect(Rect.fromLTWH(0.5, 0.5, size.width - 1.0, size.height - 1.0), paint);
  }

  @override
  bool shouldRepaint(_SquarePainter oldDelegate) => oldDelegate.color != color;
}

/// Precise custom painted Windows 11 Restore glyph (`🗗` - two overlapping rectangles).
class _RestoreIcon extends StatelessWidget {
  const _RestoreIcon();

  @override
  Widget build(BuildContext context) {
    final color = IconTheme.of(context).color ?? Colors.grey;
    return CustomPaint(
      size: const Size(10, 10),
      painter: _RestorePainter(color),
    );
  }
}

class _RestorePainter extends CustomPainter {
  final Color color;
  _RestorePainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    // Background rectangle (top-right)
    canvas.drawRect(const Rect.fromLTWH(2.5, 0.5, 7.0, 7.0), paint);
    // Foreground rectangle (bottom-left)
    canvas.drawRect(const Rect.fromLTWH(0.5, 2.5, 7.0, 7.0), paint);
  }

  @override
  bool shouldRepaint(_RestorePainter oldDelegate) => oldDelegate.color != color;
}

/// Precise custom painted Windows 11 Close glyph (`✕`).
class _CloseIcon extends StatelessWidget {
  const _CloseIcon();

  @override
  Widget build(BuildContext context) {
    final color = IconTheme.of(context).color ?? Colors.grey;
    return CustomPaint(
      size: const Size(10, 10),
      painter: _CrossPainter(color),
    );
  }
}

class _CrossPainter extends CustomPainter {
  final Color color;
  _CrossPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.0;
    canvas.drawLine(Offset.zero, Offset(size.width, size.height), paint);
    canvas.drawLine(Offset(size.width, 0), Offset(0, size.height), paint);
  }

  @override
  bool shouldRepaint(_CrossPainter oldDelegate) => oldDelegate.color != color;
}

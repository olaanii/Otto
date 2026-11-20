import 'package:flutter/material.dart';

/// Navigation arrow button for Windows 11 title bar.
class TitleNavArrow extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onPressed;
  final String tooltip;

  const TitleNavArrow({
    super.key,
    required this.icon,
    this.onPressed,
    required this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(
        icon,
        size: 14,
        color: onPressed != null ? const Color(0xFFCCCCCC) : const Color(0xFF555555),
      ),
      onPressed: onPressed,
      tooltip: tooltip,
      splashRadius: 12,
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(minWidth: 22, minHeight: 22),
    );
  }
}

/// Menu button (File, Edit, View, Help) for Windows 11 title bar.
class TitleMenuButton extends StatelessWidget {
  final String title;
  final List<PopupMenuEntry<String>> items;

  const TitleMenuButton({
    super.key,
    required this.title,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      tooltip: '',
      offset: const Offset(0, 26),
      color: const Color(0xFF2B2B2B),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(6),
        side: const BorderSide(color: Color(0xFF3A3A3A)),
      ),
      itemBuilder: (_) => items,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6.0, vertical: 4.0),
        child: Text(
          title,
          style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.normal),
        ),
      ),
    );
  }
}

/// Centered search pill for Command Search (Ctrl+K).
class CommandSearchPill extends StatelessWidget {
  final VoidCallback? onTap;

  const CommandSearchPill({super.key, this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        height: 24,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(
          color: const Color(0xFF2B2B2B),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: const Color(0xFF3A3A3A)),
        ),
        child: const Row(
          children: [
            Icon(Icons.search_rounded, size: 14, color: Color(0xFF8A8A8A)),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                'Search commits, diffs, stacks…',
                style: TextStyle(color: Color(0xFF8A8A8A), fontSize: 11),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Text(
              'Ctrl+K',
              style: TextStyle(color: Color(0xFF8A8A8A), fontSize: 10, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
    );
  }
}

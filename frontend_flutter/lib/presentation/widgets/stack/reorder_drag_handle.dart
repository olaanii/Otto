import 'package:flutter/material.dart';
import '../../../core/constants/colors.dart';

/// Interactive grip handle for reordering commits in the rebase stack.
class ReorderDragHandle extends StatelessWidget {
  final int index;

  const ReorderDragHandle({super.key, required this.index});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ReorderableDragStartListener(
      index: index,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
        child: Icon(
          Icons.drag_indicator,
          size: 18,
          color: isDark ? AppColors.zinc500 : AppColors.zinc400,
        ),
      ),
    );
  }
}

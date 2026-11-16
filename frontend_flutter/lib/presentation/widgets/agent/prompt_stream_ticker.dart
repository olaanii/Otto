import 'package:flutter/material.dart';
import '../../../core/constants/colors.dart';
import '../../../core/theme/typography.dart';

/// Real-time ticker streaming the AI agent's active reasoning and prompt context.
class PromptStreamTicker extends StatelessWidget {
  final String text;
  final bool isStreaming;
  final VoidCallback? onDismiss;

  const PromptStreamTicker({
    super.key,
    required this.text,
    this.isStreaming = false,
    this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.cardLight,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: isStreaming
              ? AppColors.indigo500.withOpacity(0.5)
              : (isDark ? AppColors.borderDark : AppColors.borderLight),
        ),
      ),
      child: Row(
        children: [
          if (isStreaming)
            const SizedBox(
              width: 12,
              height: 12,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppColors.indigo500,
              ),
            )
          else
            Icon(Icons.terminal, size: 14, color: AppColors.zinc400),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.codeFont.copyWith(
                fontSize: 11.5,
                color: isDark ? AppColors.zinc300 : AppColors.zinc700,
              ),
            ),
          ),
          if (onDismiss != null)
            InkWell(
              onTap: onDismiss,
              child: Icon(Icons.close, size: 14, color: AppColors.zinc400),
            ),
        ],
      ),
    );
  }
}

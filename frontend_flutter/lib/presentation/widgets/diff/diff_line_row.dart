import 'package:flutter/material.dart';
import '../../../core/constants/colors.dart';
import '../../../core/theme/typography.dart';
import '../../../domain/models/diff_hunk.dart';

/// Single line renderer in a diff viewer with gutter numbers and syntax tokens.
class DiffLineRow extends StatelessWidget {
  final DiffLine line;
  final bool isSelected;
  final bool showSyntax;
  final VoidCallback? onToggleSelect;

  const DiffLineRow({
    super.key,
    required this.line,
    this.isSelected = true,
    this.showSyntax = true,
    this.onToggleSelect,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final (bgColor, textColor, sign) = switch (line.type) {
      DiffLineType.addition => (
          isDark ? AppColors.diffAddedBgDark : AppColors.diffAddedBgLight,
          isDark ? AppColors.diffAddedLineDark : AppColors.diffAddedLineLight,
          '+',
        ),
      DiffLineType.deletion => (
          isDark ? AppColors.diffRemovedBgDark : AppColors.diffRemovedBgLight,
          isDark ? AppColors.diffRemovedLineDark : AppColors.diffRemovedLineLight,
          '-',
        ),
      DiffLineType.context => (
          Colors.transparent,
          isDark ? AppColors.zinc300 : AppColors.zinc800,
          ' ',
        ),
      DiffLineType.hunkHeader => (
          isDark ? AppColors.diffHunkHeaderDark : AppColors.diffHunkHeaderBgLight,
          isDark ? AppColors.indigo400 : AppColors.indigo600,
          '@',
        ),
      DiffLineType.fileHeader => (
          isDark ? AppColors.zinc800 : AppColors.zinc200,
          isDark ? AppColors.zinc100 : AppColors.zinc900,
          '#',
        ),
    };

    return InkWell(
      onTap: onToggleSelect,
      hoverColor: isDark ? AppColors.zinc800.withOpacity(0.4) : AppColors.zinc100,
      child: Container(
        color: isSelected ? bgColor : bgColor.withOpacity(0.3),
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1.5),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Checkbox indicator for hunk/line level staging
            if (line.type == DiffLineType.addition || line.type == DiffLineType.deletion)
              SizedBox(
                width: 20,
                child: Icon(
                  isSelected ? Icons.check_box : Icons.check_box_outline_blank,
                  size: 13,
                  color: isSelected ? AppColors.indigo500 : AppColors.zinc400,
                ),
              )
            else
              const SizedBox(width: 20),

            // Old Line Number
            SizedBox(
              width: 36,
              child: Text(
                line.oldLineNumber?.toString() ?? '',
                textAlign: TextAlign.right,
                style: AppTypography.diffGutterStyle(isDark: isDark),
              ),
            ),
            const SizedBox(width: 8),

            // New Line Number
            SizedBox(
              width: 36,
              child: Text(
                line.newLineNumber?.toString() ?? '',
                textAlign: TextAlign.right,
                style: AppTypography.diffGutterStyle(isDark: isDark),
              ),
            ),
            const SizedBox(width: 8),

            // Sign (+, -, @)
            SizedBox(
              width: 14,
              child: Text(
                sign,
                textAlign: TextAlign.center,
                style: AppTypography.diffLineStyle(
                  isDark: isDark,
                  color: textColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(width: 6),

            // Line Content with Syntax Tokens
            Expanded(
              child: showSyntax && line.syntaxTokens.isNotEmpty
                  ? _buildSyntaxHighlightedText(isDark, textColor)
                  : Text(
                      line.content,
                      style: AppTypography.diffLineStyle(
                        isDark: isDark,
                        color: textColor,
                      ),
                      softWrap: false,
                      overflow: TextOverflow.visible,
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSyntaxHighlightedText(bool isDark, Color defaultColor) {
    return Text.rich(
      TextSpan(
        children: line.syntaxTokens.map((token) {
          Color? tokenColor;
          if (token.colorHex != null) {
            final hex = token.colorHex!.replaceAll('#', '');
            if (hex.length == 6) {
              tokenColor = Color(int.parse('FF$hex', radix: 16));
            }
          }
          tokenColor ??= defaultColor;

          return TextSpan(
            text: token.text,
            style: AppTypography.diffLineStyle(
              isDark: isDark,
              color: tokenColor,
              fontWeight: token.isKeyword ? FontWeight.w600 : FontWeight.w400,
            ),
          );
        }).toList(),
      ),
      softWrap: false,
      overflow: TextOverflow.visible,
    );
  }
}

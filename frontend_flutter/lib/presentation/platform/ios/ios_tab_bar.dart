import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'ios_cupertino_theme.dart';

/// Enum representing the 4 primary tabs in Otto's iOS companion application.
enum OttoIosTab {
  diffReview,
  stackedPrs,
  rebasePlayground,
  aiRefiner,
}

/// Authentic iOS 17/18 Cupertino Tab Bar supporting 4 core Otto workflows,
/// dynamic system colors, badge counts, and tactile haptic feedback.
class IosTabBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTabSelected;
  final int? diffCount;
  final int? stackCount;
  final bool hasRebaseChanges;

  const IosTabBar({
    super.key,
    required this.currentIndex,
    required this.onTabSelected,
    this.diffCount,
    this.stackCount,
    this.hasRebaseChanges = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = IosCupertinoTheme.isDark(context);

    return CupertinoTabBar(
      currentIndex: currentIndex,
      onTap: (index) {
        if (index != currentIndex) {
          HapticFeedback.selectionClick();
          onTabSelected(index);
        }
      },
      backgroundColor: isDark
          ? const Color(0xD9121212)
          : const Color(0xD9F8F8F8),
      activeColor: IosColors.resolve(IosColors.systemIndigo, context),
      inactiveColor: IosColors.resolve(IosColors.secondaryLabel, context),
      border: Border(
        top: BorderSide(
          color: IosColors.resolve(IosColors.separator, context),
          width: 0.5,
        ),
      ),
      items: [
        // Tab 0: Diff Review
        BottomNavigationBarItem(
          icon: _buildIconWithBadge(
            icon: CupertinoIcons.doc_text_search,
            badgeCount: diffCount,
            context: context,
          ),
          activeIcon: _buildIconWithBadge(
            icon: CupertinoIcons.doc_text_fill,
            badgeCount: diffCount,
            context: context,
          ),
          label: 'Diff Review',
        ),

        // Tab 1: Stacked PRs
        BottomNavigationBarItem(
          icon: _buildIconWithBadge(
            icon: CupertinoIcons.square_stack_3d_up,
            badgeCount: stackCount,
            context: context,
          ),
          activeIcon: _buildIconWithBadge(
            icon: CupertinoIcons.square_stack_3d_up_fill,
            badgeCount: stackCount,
            context: context,
          ),
          label: 'Stacked PRs',
        ),

        // Tab 2: Rebase Playground
        BottomNavigationBarItem(
          icon: _buildIconWithDot(
            icon: CupertinoIcons.arrow_2_squarepath,
            hasDot: hasRebaseChanges,
            context: context,
          ),
          activeIcon: _buildIconWithDot(
            icon: CupertinoIcons.arrow_2_squarepath,
            hasDot: hasRebaseChanges,
            context: context,
          ),
          label: 'Rebase',
        ),

        // Tab 3: AI Refiner
        const BottomNavigationBarItem(
          icon: Icon(CupertinoIcons.sparkles),
          activeIcon: Icon(CupertinoIcons.sparkles),
          label: 'AI Refiner',
        ),
      ],
    );
  }

  Widget _buildIconWithBadge({
    required IconData icon,
    int? badgeCount,
    required BuildContext context,
  }) {
    if (badgeCount == null || badgeCount <= 0) {
      return Icon(icon);
    }

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Icon(icon),
        Positioned(
          top: -2,
          right: -8,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
            constraints: const BoxConstraints(minWidth: 16, minHeight: 14),
            decoration: BoxDecoration(
              color: IosColors.systemIndigo.color,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Text(
                badgeCount > 99 ? '99+' : '$badgeCount',
                style: const TextStyle(
                  color: CupertinoColors.white,
                  fontSize: 9.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildIconWithDot({
    required IconData icon,
    required bool hasDot,
    required BuildContext context,
  }) {
    if (!hasDot) return Icon(icon);

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Icon(icon),
        Positioned(
          top: -1,
          right: -3,
          child: Container(
            width: 7,
            height: 7,
            decoration: const BoxDecoration(
              color: IosColors.systemOrange,
              shape: BoxShape.circle,
            ),
          ),
        ),
      ],
    );
  }
}

/// Reusable Cupertino Sliding Segmented Control styled to iOS 17/18 standards.
class IosSegmentedControl<T extends Object> extends StatelessWidget {
  final T groupValue;
  final Map<T, Widget> children;
  final ValueChanged<T?> onValueChanged;

  const IosSegmentedControl({
    super.key,
    required this.groupValue,
    required this.children,
    required this.onValueChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = IosCupertinoTheme.isDark(context);

    return CupertinoSlidingSegmentedControl<T>(
      groupValue: groupValue,
      children: children,
      onValueChanged: (val) {
        if (val != null && val != groupValue) {
          HapticFeedback.selectionClick();
          onValueChanged(val);
        }
      },
      backgroundColor: IosColors.resolve(IosColors.systemFill, context),
      thumbColor: isDark
          ? const Color(0xFF3A3A3C)
          : const Color(0xFFFFFFFF),
      padding: const EdgeInsets.all(2.5),
    );
  }
}

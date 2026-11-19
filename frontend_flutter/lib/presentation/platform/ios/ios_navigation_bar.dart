import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../domain/models/clerk_user_session.dart';
import '../../providers/auth_state_provider.dart';
import 'ios_cupertino_theme.dart';

/// Authentic iOS 17/18 Cupertino Navigation Bar with dynamic collapsible large titles,
/// Clerk profile avatar button, and git branch status badge.
class IosSliverNavigationBar extends StatelessWidget {
  final String title;
  final Widget? leading;
  final Widget? trailing;
  final bool automaticallyImplyLeading;
  final VoidCallback? onAvatarTap;
  final String? branchName;
  final bool isSyncing;
  final VoidCallback? onSyncTap;

  const IosSliverNavigationBar({
    super.key,
    required this.title,
    this.leading,
    this.trailing,
    this.automaticallyImplyLeading = true,
    this.onAvatarTap,
    this.branchName,
    this.isSyncing = false,
    this.onSyncTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = IosCupertinoTheme.isDark(context);

    return CupertinoSliverNavigationBar(
      automaticallyImplyLeading: automaticallyImplyLeading,
      backgroundColor: isDark
          ? const Color(0xCC121212)
          : const Color(0xCCF8F8F8),
      border: Border(
        bottom: BorderSide(
          color: IosColors.resolve(IosColors.separator, context),
          width: 0.5,
        ),
      ),
      leading: leading ??
          (branchName != null
              ? IosBranchPill(branchName: branchName!)
              : const IosBrandLogoBadge()),
      largeTitle: Text(
        title,
        style: IosTypography.largeTitle.copyWith(
          color: IosColors.resolve(IosColors.label, context),
        ),
      ),
      trailing: trailing ??
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (onSyncTap != null) ...[
                CupertinoButton(
                  padding: EdgeInsets.zero,
                  minSize: 32,
                  onPressed: isSyncing
                      ? null
                      : () {
                          HapticFeedback.lightImpact();
                          onSyncTap?.call();
                        },
                  child: isSyncing
                      ? const CupertinoActivityIndicator(radius: 8)
                      : Icon(
                          CupertinoIcons.arrow_up_circle_fill,
                          size: 22,
                          color: IosColors.resolve(IosColors.systemIndigo, context),
                        ),
                ),
                const SizedBox(width: 8),
              ],
              IosClerkAvatarButton(onTap: onAvatarTap),
            ],
          ),
    );
  }
}

/// Standard fixed Cupertino navigation bar with authentic iOS 17/18 styling.
class IosNavigationBar extends StatelessWidget implements ObstructingPreferredSizeWidget {
  final String title;
  final Widget? leading;
  final Widget? trailing;
  final String? previousPageTitle;
  final VoidCallback? onAvatarTap;
  final String? branchName;

  const IosNavigationBar({
    super.key,
    required this.title,
    this.leading,
    this.trailing,
    this.previousPageTitle,
    this.onAvatarTap,
    this.branchName,
  });

  @override
  Size get preferredSize => const Size.fromHeight(44.0);

  @override
  bool shouldFullyObstruct(BuildContext context) => true;

  @override
  Widget build(BuildContext context) {
    final isDark = IosCupertinoTheme.isDark(context);

    return CupertinoNavigationBar(
      backgroundColor: isDark
          ? const Color(0xCC121212)
          : const Color(0xCCF8F8F8),
      border: Border(
        bottom: BorderSide(
          color: IosColors.resolve(IosColors.separator, context),
          width: 0.5,
        ),
      ),
      previousPageTitle: previousPageTitle,
      leading: leading ??
          (branchName != null
              ? IosBranchPill(branchName: branchName!)
              : const IosBrandLogoBadge()),
      middle: Text(
        title,
        style: IosTypography.headline.copyWith(
          color: IosColors.resolve(IosColors.label, context),
        ),
      ),
      trailing: trailing ?? IosClerkAvatarButton(onTap: onAvatarTap),
    );
  }
}

/// Clerk Profile Avatar Button with status ring and tap interaction.
class IosClerkAvatarButton extends ConsumerWidget {
  final VoidCallback? onTap;

  const IosClerkAvatarButton({super.key, this.onTap});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);
    final session = authState.session;

    return CupertinoButton(
      padding: EdgeInsets.zero,
      minSize: 32,
      onPressed: () {
        HapticFeedback.selectionClick();
        onTap?.call();
      },
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: IosColors.resolve(IosColors.systemFill, context),
              border: Border.all(
                color: IosColors.resolve(IosColors.systemIndigo, context).withOpacity(0.5),
                width: 1.5,
              ),
            ),
            child: ClipOval(
              child: session?.avatarUrl != null && session!.avatarUrl!.isNotEmpty
                  ? Image.network(
                      session.avatarUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _buildInitials(session),
                    )
                  : _buildInitials(session),
            ),
          ),
          // Active Online Status Dot
          Positioned(
            right: -1,
            bottom: -1,
            child: Container(
              width: 9,
              height: 9,
              decoration: BoxDecoration(
                color: authState.isAuthenticated
                    ? IosColors.systemGreen.color
                    : IosColors.systemOrange.color,
                shape: BoxShape.circle,
                border: Border.all(
                  color: IosColors.resolve(IosColors.systemBackground, context),
                  width: 1.5,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInitials(ClerkUserSession? session) {
    final name = session?.fullName ?? 'Dev';
    final initial = name.trim().isNotEmpty ? name.trim()[0].toUpperCase() : 'O';

    return Center(
      child: Text(
        initial,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: IosColors.systemIndigo,
        ),
      ),
    );
  }
}

/// Brand Logo Badge representing Otto in iOS Squircle format.
class IosBrandLogoBadge extends StatelessWidget {
  const IosBrandLogoBadge({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 26,
      height: 26,
      decoration: BoxDecoration(
        color: IosColors.resolve(IosColors.systemIndigo, context),
        borderRadius: BorderRadius.circular(6.5),
      ),
      child: const Center(
        child: Text(
          'O',
          style: TextStyle(
            color: CupertinoColors.white,
            fontSize: 14,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.2,
          ),
        ),
      ),
    );
  }
}

/// Sleek iOS Branch Pill displaying the current Git branch name with branch icon.
class IosBranchPill extends StatelessWidget {
  final String branchName;

  const IosBranchPill({super.key, required this.branchName});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: IosColors.resolve(IosColors.secondarySystemBackground, context),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: IosColors.resolve(IosColors.separator, context),
          width: 0.5,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            CupertinoIcons.arrow_branch,
            size: 11,
            color: IosColors.resolve(IosColors.systemIndigo, context),
          ),
          const SizedBox(width: 4),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 100),
            child: Text(
              branchName,
              overflow: TextOverflow.ellipsis,
              style: IosTypography.monoCode.copyWith(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: IosColors.resolve(IosColors.label, context),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import '../../../domain/models/clerk_user_session.dart';

/// GitHub Sync Status representation for the M3 TopAppBar.
enum GithubSyncStatus {
  synced,
  syncing,
  pendingPush,
  offline,
}

/// Official Android Material Design 3 Medium TopAppBar with collapsible scroll behavior,
/// embedded search mode, live GitHub sync pill, and Clerk user profile menu.
class M3SliverMediumTopAppBar extends StatefulWidget {
  final String title;
  final String currentBranch;
  final GithubSyncStatus syncStatus;
  final ClerkUserSession? clerkSession;
  final VoidCallback? onSyncTap;
  final VoidCallback? onBranchTap;
  final VoidCallback? onClerkProfileTap;
  final ValueChanged<String>? onSearchChanged;
  final VoidCallback? onSearchClosed;
  final String? searchHint;
  final List<Widget>? additionalActions;

  const M3SliverMediumTopAppBar({
    super.key,
    this.title = 'Otto Stacking',
    required this.currentBranch,
    this.syncStatus = GithubSyncStatus.synced,
    this.clerkSession,
    this.onSyncTap,
    this.onBranchTap,
    this.onClerkProfileTap,
    this.onSearchChanged,
    this.onSearchClosed,
    this.searchHint = 'Search commits, files, or agents...',
    this.additionalActions,
  });

  @override
  State<M3SliverMediumTopAppBar> createState() => _M3SliverMediumTopAppBarState();
}

class _M3SliverMediumTopAppBarState extends State<M3SliverMediumTopAppBar> {
  bool _isSearchOpen = false;
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _openSearch() {
    setState(() => _isSearchOpen = true);
    _searchFocusNode.requestFocus();
  }

  void _closeSearch() {
    setState(() {
      _isSearchOpen = false;
      _searchController.clear();
    });
    widget.onSearchChanged?.call('');
    widget.onSearchClosed?.call();
    _searchFocusNode.unfocus();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (_isSearchOpen) {
      return SliverAppBar(
        pinned: true,
        floating: false,
        scrolledUnderElevation: 3,
        backgroundColor: colorScheme.surface,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          tooltip: 'Close search',
          onPressed: _closeSearch,
        ),
        title: TextField(
          controller: _searchController,
          focusNode: _searchFocusNode,
          decoration: InputDecoration(
            hintText: widget.searchHint,
            border: InputBorder.none,
            enabledBorder: InputBorder.none,
            focusedBorder: InputBorder.none,
            fillColor: Colors.transparent,
            hintStyle: theme.textTheme.bodyLarge?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          style: theme.textTheme.bodyLarge?.copyWith(
            color: colorScheme.onSurface,
          ),
          onChanged: widget.onSearchChanged,
        ),
        actions: [
          if (_searchController.text.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.clear, size: 20),
              onPressed: () {
                _searchController.clear();
                widget.onSearchChanged?.call('');
              },
            ),
          const SizedBox(width: 8),
        ],
      );
    }

    return SliverAppBar.medium(
      pinned: true,
      floating: false,
      scrolledUnderElevation: 3,
      backgroundColor: colorScheme.surface,
      surfaceTintColor: colorScheme.surfaceTint,
      title: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Otto brand mark with M3 container
          Container(
            width: 26,
            height: 26,
            decoration: BoxDecoration(
              color: colorScheme.primary,
              borderRadius: BorderRadius.circular(7),
            ),
            child: Center(
              child: Text(
                'O',
                style: theme.textTheme.titleSmall?.copyWith(
                  color: colorScheme.onPrimary,
                  fontWeight: FontWeight.w800,
                  fontSize: 14,
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Flexible(
            child: Text(
              widget.title,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 8),
          // Active Branch M3 chip
          InkWell(
            onTap: widget.onBranchTap,
            borderRadius: BorderRadius.circular(8),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: colorScheme.outlineVariant.withOpacity(0.5),
                  width: 0.8,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.fork_right_rounded,
                    size: 14,
                    color: colorScheme.primary,
                  ),
                  const SizedBox(width: 4),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 100),
                    child: Text(
                      widget.currentBranch,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      actions: [
        // Live GitHub Sync Status Pill
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: _M3GithubSyncPill(
            status: widget.syncStatus,
            onTap: widget.onSyncTap,
          ),
        ),
        const SizedBox(width: 4),

        // Search trigger button
        IconButton(
          icon: const Icon(Icons.search_rounded),
          tooltip: 'Search stack & diffs',
          onPressed: _openSearch,
        ),

        // Clerk user avatar & profile menu button
        Padding(
          padding: const EdgeInsets.only(right: 12, left: 4),
          child: _M3ClerkAvatarButton(
            session: widget.clerkSession,
            onTap: widget.onClerkProfileTap,
          ),
        ),

        if (widget.additionalActions != null) ...widget.additionalActions!,
      ],
    );
  }
}

/// Standalone Material 3 Pinned TopAppBar for use in standard Scaffold `appBar` property.
class M3TopAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final String currentBranch;
  final GithubSyncStatus syncStatus;
  final ClerkUserSession? clerkSession;
  final VoidCallback? onSyncTap;
  final VoidCallback? onBranchTap;
  final VoidCallback? onClerkProfileTap;
  final VoidCallback? onSearchTap;
  final Widget? leading;
  final List<Widget>? actions;

  const M3TopAppBar({
    super.key,
    this.title = 'Otto',
    required this.currentBranch,
    this.syncStatus = GithubSyncStatus.synced,
    this.clerkSession,
    this.onSyncTap,
    this.onBranchTap,
    this.onClerkProfileTap,
    this.onSearchTap,
    this.leading,
    this.actions,
  });

  @override
  Size get preferredSize => const Size.fromHeight(64);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return AppBar(
      scrolledUnderElevation: 3,
      backgroundColor: colorScheme.surface,
      surfaceTintColor: colorScheme.surfaceTint,
      leading: leading,
      title: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: colorScheme.primary,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Center(
              child: Text(
                'O',
                style: theme.textTheme.labelMedium?.copyWith(
                  color: colorScheme.onPrimary,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            title,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 8),
          InkWell(
            onTap: onBranchTap,
            borderRadius: BorderRadius.circular(6),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.call_split_rounded, size: 12, color: colorScheme.primary),
                  const SizedBox(width: 4),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 90),
                    child: Text(
                      currentBranch,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: _M3GithubSyncPill(status: syncStatus, onTap: onSyncTap),
        ),
        if (onSearchTap != null)
          IconButton(
            icon: const Icon(Icons.search_rounded, size: 22),
            onPressed: onSearchTap,
            tooltip: 'Search',
          ),
        Padding(
          padding: const EdgeInsets.only(right: 12, left: 4),
          child: _M3ClerkAvatarButton(
            session: clerkSession,
            onTap: onClerkProfileTap,
          ),
        ),
        if (actions != null) ...actions!,
      ],
    );
  }
}

/// Pill indicator displaying GitHub connection and synchronization status.
class _M3GithubSyncPill extends StatelessWidget {
  final GithubSyncStatus status;
  final VoidCallback? onTap;

  const _M3GithubSyncPill({
    required this.status,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final (statusColor, label, icon) = switch (status) {
      GithubSyncStatus.synced => (
          const Color(0xFF137333),
          'Synced',
          Icons.cloud_done_rounded,
        ),
      GithubSyncStatus.syncing => (
          colorScheme.primary,
          'Syncing...',
          Icons.sync_rounded,
        ),
      GithubSyncStatus.pendingPush => (
          const Color(0xFFB06000),
          'Push Ready',
          Icons.cloud_upload_outlined,
        ),
      GithubSyncStatus.offline => (
          colorScheme.onSurfaceVariant,
          'Local Only',
          Icons.cloud_off_rounded,
        ),
    };

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: colorScheme.outlineVariant.withOpacity(0.5),
            width: 0.8,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (status == GithubSyncStatus.syncing)
              SizedBox(
                width: 12,
                height: 12,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: colorScheme.primary,
                ),
              )
            else
              Container(
                width: 7,
                height: 7,
                decoration: BoxDecoration(
                  color: statusColor,
                  shape: BoxShape.circle,
                ),
              ),
            const SizedBox(width: 6),
            Icon(icon, size: 13, color: colorScheme.onSurfaceVariant),
            const SizedBox(width: 4),
            Text(
              label,
              style: theme.textTheme.labelSmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Clerk Avatar Button with user monogram or network avatar.
class _M3ClerkAvatarButton extends StatelessWidget {
  final ClerkUserSession? session;
  final VoidCallback? onTap;

  const _M3ClerkAvatarButton({
    this.session,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final initial = (session?.fullName.isNotEmpty == true)
        ? session!.fullName[0].toUpperCase()
        : 'U';

    return InkWell(
      onTap: onTap,
      customBorder: const CircleBorder(),
      child: Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: colorScheme.secondaryContainer,
          border: Border.all(
            color: colorScheme.outlineVariant,
            width: 1,
          ),
        ),
        child: ClipOval(
          child: session?.avatarUrl != null && session!.avatarUrl!.isNotEmpty
              ? Image.network(
                  session!.avatarUrl!,
                  width: 34,
                  height: 34,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => _buildFallbackInitial(colorScheme, initial),
                )
              : _buildFallbackInitial(colorScheme, initial),
        ),
      ),
    );
  }

  Widget _buildFallbackInitial(ColorScheme colorScheme, String initial) {
    return Center(
      child: Text(
        initial,
        style: TextStyle(
          color: colorScheme.onSecondaryContainer,
          fontWeight: FontWeight.w700,
          fontSize: 14,
        ),
      ),
    );
  }
}

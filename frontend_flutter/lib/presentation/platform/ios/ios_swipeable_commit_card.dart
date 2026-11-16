import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import '../../../domain/models/atomic_commit_unit.dart';
import 'ios_cupertino_theme.dart';

/// Authentic iOS 17/18 swipeable commit card implementing Apple's contextual swipe actions.
///
/// Features:
/// - Swipe Right: reveals **Push** (System Blue) and **Stage** (System Green).
/// - Swipe Left: reveals **Split** (System Orange) and **Discard** (System Red).
/// - Tactile haptic feedback on swipe threshold pass (`HapticFeedback.mediumImpact()`).
/// - Authentic iOS Inset Grouped list cell appearance with LOC guardrail badges.
class IosSwipeableCommitCard extends StatefulWidget {
  final AtomicCommitUnit commit;
  final bool isSelected;
  final VoidCallback? onTap;
  final VoidCallback? onPush;
  final VoidCallback? onStage;
  final VoidCallback? onSplit;
  final VoidCallback? onDiscard;
  final VoidCallback? onLongPress;

  const IosSwipeableCommitCard({
    super.key,
    required this.commit,
    this.isSelected = false,
    this.onTap,
    this.onPush,
    this.onStage,
    this.onSplit,
    this.onDiscard,
    this.onLongPress,
  });

  @override
  State<IosSwipeableCommitCard> createState() => _IosSwipeableCommitCardState();
}

class _IosSwipeableCommitCardState extends State<IosSwipeableCommitCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late Animation<double> _animation;
  double _dragExtent = 0.0;
  bool _hasTriggeredHaptic = false;

  static const double _actionButtonWidth = 76.0;
  static const double _maxRightExtent = _actionButtonWidth * 2; // Push + Stage
  static const double _maxLeftExtent = -(_actionButtonWidth * 2); // Split + Discard

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );
    _animation = Tween<double>(begin: 0, end: 0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleHorizontalDragUpdate(DragUpdateDetails details) {
    setState(() {
      _dragExtent += details.primaryDelta!;
      // Apply rubber-band resistance beyond action limits
      if (_dragExtent > _maxRightExtent) {
        _dragExtent = _maxRightExtent + (_dragExtent - _maxRightExtent) * 0.2;
      } else if (_dragExtent < _maxLeftExtent) {
        _dragExtent = _maxLeftExtent + (_dragExtent - _maxLeftExtent) * 0.2;
      }

      // Haptic threshold pass
      if (!_hasTriggeredHaptic &&
          (_dragExtent.abs() >= _actionButtonWidth)) {
        HapticFeedback.mediumImpact();
        _hasTriggeredHaptic = true;
      }
    });
  }

  void _handleHorizontalDragEnd(DragEndDetails details) {
    _hasTriggeredHaptic = false;
    final velocity = details.primaryVelocity ?? 0;

    double targetExtent = 0.0;
    if (_dragExtent > _actionButtonWidth * 0.6 || velocity > 400) {
      targetExtent = _maxRightExtent;
    } else if (_dragExtent < -(_actionButtonWidth * 0.6) || velocity < -400) {
      targetExtent = _maxLeftExtent;
    } else {
      targetExtent = 0.0;
    }

    _animateTo(targetExtent);
  }

  void _animateTo(double target) {
    _animation = Tween<double>(begin: _dragExtent, end: target).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    )..addListener(() {
        setState(() {
          _dragExtent = _animation.value;
        });
      });
    _controller.forward(from: 0.0);
  }

  void _closeActions() {
    if (_dragExtent != 0.0) {
      _animateTo(0.0);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = IosCupertinoTheme.isDark(context);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: CupertinoColors.black.withOpacity(isDark ? 0.3 : 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Stack(
          children: [
            // Underlying Action Buttons (Revealed on Swipe)
            Positioned.fill(
              child: Row(
                children: [
                  // Left Side Actions (Revealed when swiping Right)
                  if (_dragExtent > 0) ...[
                    if (widget.onPush != null)
                      _buildActionButton(
                        icon: CupertinoIcons.arrow_up_circle_fill,
                        label: 'Push',
                        backgroundColor: IosColors.systemBlue.color,
                        onTap: () {
                          HapticFeedback.lightImpact();
                          _closeActions();
                          widget.onPush?.call();
                        },
                      ),
                    if (widget.onStage != null)
                      _buildActionButton(
                        icon: CupertinoIcons.checkmark_alt_circle_fill,
                        label: 'Stage',
                        backgroundColor: IosColors.systemGreen.color,
                        onTap: () {
                          HapticFeedback.lightImpact();
                          _closeActions();
                          widget.onStage?.call();
                        },
                      ),
                  ],

                  const Spacer(),

                  // Right Side Actions (Revealed when swiping Left)
                  if (_dragExtent < 0) ...[
                    if (widget.onSplit != null)
                      _buildActionButton(
                        icon: CupertinoIcons.scissors,
                        label: 'Split',
                        backgroundColor: IosColors.systemOrange.color,
                        onTap: () {
                          HapticFeedback.lightImpact();
                          _closeActions();
                          widget.onSplit?.call();
                        },
                      ),
                    if (widget.onDiscard != null)
                      _buildActionButton(
                        icon: CupertinoIcons.trash_fill,
                        label: 'Discard',
                        backgroundColor: IosColors.systemRed.color,
                        onTap: () {
                          HapticFeedback.mediumImpact();
                          _closeActions();
                          widget.onDiscard?.call();
                        },
                      ),
                  ],
                ],
              ),
            ),

            // Foreground Card Surface (Transforms on Drag)
            Transform.translate(
              offset: Offset(_dragExtent, 0),
              child: GestureDetector(
                onHorizontalDragUpdate: _handleHorizontalDragUpdate,
                onHorizontalDragEnd: _handleHorizontalDragEnd,
                onTap: () {
                  if (_dragExtent != 0.0) {
                    _closeActions();
                  } else {
                    HapticFeedback.selectionClick();
                    widget.onTap?.call();
                  }
                },
                onLongPress: () {
                  HapticFeedback.heavyImpact();
                  widget.onLongPress?.call();
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: widget.isSelected
                        ? (isDark
                            ? const Color(0xFF1E2433)
                            : const Color(0xFFEFF3FF))
                        : IosColors.resolve(
                            IosColors.secondarySystemGroupedBackground,
                            context,
                          ),
                    border: Border.all(
                      color: widget.isSelected
                          ? IosColors.resolve(IosColors.systemIndigo, context)
                          : IosColors.resolve(IosColors.separator, context).withOpacity(0.4),
                      width: widget.isSelected ? 1.5 : 0.5,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Top Row: Type Tag, Conventional Scope, Summary, PR status badge
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          _buildTypeBadge(widget.commit.type),
                          const SizedBox(width: 8),
                          if (widget.commit.scope != null && widget.commit.scope!.isNotEmpty) ...[
                            Text(
                              '(${widget.commit.scope}):',
                              style: IosTypography.footnote.copyWith(
                                fontWeight: FontWeight.w600,
                                color: IosColors.resolve(IosColors.secondaryLabel, context),
                              ),
                            ),
                            const SizedBox(width: 4),
                          ],
                          Expanded(
                            child: Text(
                              widget.commit.summary,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: IosTypography.headline.copyWith(
                                fontSize: 15,
                                color: IosColors.resolve(IosColors.label, context),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          _buildPrStatusBadge(widget.commit, context),
                        ],
                      ),

                      const SizedBox(height: 8),

                      // Bottom Row: Branch Name, Files Count, LOC stats, Guardrail Warning
                      Row(
                        children: [
                          Icon(
                            CupertinoIcons.arrow_branch,
                            size: 11,
                            color: IosColors.resolve(IosColors.secondaryLabel, context),
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              widget.commit.branchName,
                              overflow: TextOverflow.ellipsis,
                              style: IosTypography.monoCode.copyWith(
                                fontSize: 11.5,
                                color: IosColors.resolve(IosColors.secondaryLabel, context),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),

                          // Changed Files Count Pill
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: IosColors.resolve(IosColors.systemFill, context),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              '${widget.commit.changedFiles.length} files',
                              style: IosTypography.caption2.copyWith(
                                fontWeight: widget.commit.exceedsFileThreshold
                                    ? FontWeight.w700
                                    : FontWeight.w500,
                                color: widget.commit.exceedsFileThreshold
                                    ? IosColors.systemRed.color
                                    : IosColors.resolve(IosColors.secondaryLabel, context),
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),

                          // LOC Count Pill with Guardrail Detection
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: widget.commit.exceedsLocThreshold
                                  ? IosColors.systemRed.color.withOpacity(0.12)
                                  : IosColors.resolve(IosColors.systemFill, context),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  '+${widget.commit.additions}',
                                  style: IosTypography.caption2.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: IosColors.systemGreen.color,
                                  ),
                                ),
                                const SizedBox(width: 2),
                                Text(
                                  '-${widget.commit.deletions}',
                                  style: IosTypography.caption2.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: IosColors.systemRed.color,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color backgroundColor,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: _actionButtonWidth,
        color: backgroundColor,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: CupertinoColors.white, size: 22),
            const SizedBox(height: 3),
            Text(
              label,
              style: const TextStyle(
                color: CupertinoColors.white,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTypeBadge(String type) {
    final color = switch (type.toLowerCase()) {
      'feat' => IosColors.commitFeat,
      'fix' => IosColors.commitFix,
      'refactor' => IosColors.commitRefactor,
      'perf' => IosColors.commitPerf,
      _ => IosColors.commitChore,
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(5),
      ),
      child: Text(
        type.toUpperCase(),
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w800,
          color: color,
          letterSpacing: 0.2,
        ),
      ),
    );
  }

  Widget _buildPrStatusBadge(AtomicCommitUnit commit, BuildContext context) {
    final (label, color, icon) = switch (commit.status) {
      CommitStatus.pushed => ('Pushed', IosColors.systemBlue.color, CupertinoIcons.cloud_upload_fill),
      CommitStatus.inReview => ('Review', IosColors.systemPurple.color, CupertinoIcons.eye_fill),
      CommitStatus.readyToPush => ('Ready', IosColors.systemGreen.color, CupertinoIcons.checkmark_circle_fill),
      CommitStatus.merged => ('Merged', IosColors.systemMint.color, CupertinoIcons.arrow_merge),
      CommitStatus.conflicted => ('Conflict', IosColors.systemRed.color, CupertinoIcons.exclamationmark_triangle_fill),
      CommitStatus.draft => ('Draft', IosColors.resolve(IosColors.secondaryLabel, context), CupertinoIcons.pencil),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 10, color: color),
          const SizedBox(width: 3),
          Text(
            commit.prNumber != null ? '#${commit.prNumber}' : label,
            style: TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

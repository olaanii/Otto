import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../domain/models/atomic_commit_unit.dart';
import '../../../domain/models/llm_provider_config.dart';
import '../../providers/auth_state_provider.dart';
import '../../providers/llm_selector_provider.dart';
import '../../providers/workspace_provider.dart';
import 'ios_cupertino_theme.dart';
import 'ios_navigation_bar.dart';
import 'ios_tab_bar.dart';

/// Shows an authentic iOS 17/18 modal bottom sheet with top drag grabber bar,
/// rounded corners, and native pull-to-dismiss interaction.
Future<T?> showIosModalSheet<T>({
  required BuildContext context,
  required Widget Function(BuildContext) builder,
  bool isDismissible = true,
  bool enableDrag = true,
}) {
  HapticFeedback.lightImpact();

  return showCupertinoModalPopup<T>(
    context: context,
    barrierDismissible: isDismissible,
    builder: (context) => IosModalSheetContainer(
      enableDrag: enableDrag,
      child: builder(context),
    ),
  );
}

/// Container frame for iOS modal bottom sheets with drag grabber capsule and safe padding.
class IosModalSheetContainer extends StatelessWidget {
  final Widget child;
  final bool enableDrag;

  const IosModalSheetContainer({
    super.key,
    required this.child,
    this.enableDrag = true,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = IosCupertinoTheme.isDark(context);
    final mediaQuery = MediaQuery.of(context);

    return Container(
      constraints: BoxConstraints(
        maxHeight: mediaQuery.size.height * 0.9,
      ),
      decoration: BoxDecoration(
        color: IosColors.resolve(IosColors.systemBackground, context),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        boxShadow: [
          BoxShadow(
            color: CupertinoColors.black.withOpacity(isDark ? 0.5 : 0.15),
            blurRadius: 30,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Top Drag Grabber Bar (iOS HIG Standard)
            Padding(
              padding: const EdgeInsets.only(top: 8.0, bottom: 6.0),
              child: Center(
                child: Container(
                  width: 36,
                  height: 5,
                  decoration: BoxDecoration(
                    color: IosColors.resolve(IosColors.grabberColor, context),
                    borderRadius: BorderRadius.circular(2.5),
                  ),
                ),
              ),
            ),
            Flexible(child: child),
          ],
        ),
      ),
    );
  }
}

/// Interactive AI Refinement Modal Sheet allowing developers to slice diffs,
/// select LLM providers (Claude 3.5, GPT-4o, DeepSeek), and preview atomic commits.
class IosAiRefinerSheet extends ConsumerStatefulWidget {
  const IosAiRefinerSheet({super.key});

  @override
  ConsumerState<IosAiRefinerSheet> createState() => _IosAiRefinerSheetState();
}

class _IosAiRefinerSheetState extends ConsumerState<IosAiRefinerSheet> {
  final TextEditingController _promptController = TextEditingController();
  List<AtomicCommitUnit> _suggestedCommits = [];
  bool _isRefining = false;

  @override
  void dispose() {
    _promptController.dispose();
    super.dispose();
  }

  Future<void> _runRefinement() async {
    HapticFeedback.mediumImpact();
    setState(() => _isRefining = true);

    try {
      final results = await ref
          .read(llmSelectorProvider.notifier)
          .refineUncommittedDiffs(instructions: _promptController.text.trim());

      if (mounted) {
        setState(() {
          _suggestedCommits = results;
          _isRefining = false;
        });
        HapticFeedback.lightImpact();
      }
    } catch (_) {
      if (mounted) setState(() => _isRefining = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = IosCupertinoTheme.isDark(context);
    final llmState = ref.watch(llmSelectorProvider);
    final llmNotifier = ref.read(llmSelectorProvider.notifier);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header Row
            Row(
              children: [
                Icon(
                  CupertinoIcons.sparkles,
                  color: IosColors.resolve(IosColors.systemIndigo, context),
                  size: 22,
                ),
                const SizedBox(width: 8),
                Text(
                  'AI Stack Refiner',
                  style: IosTypography.title3.copyWith(
                    color: IosColors.resolve(IosColors.label, context),
                  ),
                ),
                const Spacer(),
                CupertinoButton(
                  padding: EdgeInsets.zero,
                  child: Text(
                    'Done',
                    style: TextStyle(
                      color: IosColors.resolve(IosColors.systemIndigo, context),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Segmented LLM Model Selector
            if (llmState.providers.isNotEmpty) ...[
              Text(
                'INFERENCE MODEL',
                style: IosTypography.caption2.copyWith(
                  fontWeight: FontWeight.w700,
                  color: IosColors.resolve(IosColors.secondaryLabel, context),
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 6),
              IosSegmentedControl<String>(
                groupValue: llmState.selectedProvider.id,
                children: {
                  for (final p in llmState.providers.take(3))
                    p.id: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                      child: Text(
                        p.name.split(' ').first,
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                      ),
                    ),
                },
                onValueChanged: (val) {
                  if (val != null) {
                    final prov = llmState.providers.firstWhere((p) => p.id == val);
                    llmNotifier.selectProvider(prov);
                  }
                },
              ),
              const SizedBox(height: 16),
            ],

            // Prompt Instructions Field
            Text(
              'SPECIAL REFINEMENT INSTRUCTIONS',
              style: IosTypography.caption2.copyWith(
                fontWeight: FontWeight.w700,
                color: IosColors.resolve(IosColors.secondaryLabel, context),
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 6),
            CupertinoTextField(
              controller: _promptController,
              placeholder: 'e.g. Separate UI changes from business logic...',
              placeholderStyle: IosTypography.subheadline.copyWith(
                color: IosColors.resolve(IosColors.tertiaryLabel, context),
              ),
              style: IosTypography.subheadline.copyWith(
                color: IosColors.resolve(IosColors.label, context),
              ),
              padding: const EdgeInsets.all(12),
              maxLines: 2,
              decoration: BoxDecoration(
                color: IosColors.resolve(IosColors.secondarySystemBackground, context),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: IosColors.resolve(IosColors.separator, context),
                  width: 0.5,
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Refine Action Button
            CupertinoButton.filled(
              onPressed: _isRefining ? null : _runRefinement,
              borderRadius: BorderRadius.circular(10),
              child: _isRefining
                  ? const CupertinoActivityIndicator(color: CupertinoColors.white)
                  : const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(CupertinoIcons.wand_stars, size: 18),
                        SizedBox(width: 8),
                        Text(
                          'Synthesize Atomic Commits',
                          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                        ),
                      ],
                    ),
            ),
            const SizedBox(height: 20),

            // Suggestions List or Streaming Text
            if (llmState.activeStreamingText != null) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: IosColors.resolve(IosColors.secondarySystemBackground, context),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    const CupertinoActivityIndicator(radius: 7),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        llmState.activeStreamingText!,
                        style: IosTypography.footnote.copyWith(
                          color: IosColors.resolve(IosColors.secondaryLabel, context),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
            ],

            if (_suggestedCommits.isNotEmpty) ...[
              Text(
                'PROPOSED ATOMIC COMMITS (${_suggestedCommits.length})',
                style: IosTypography.caption2.copyWith(
                  fontWeight: FontWeight.w700,
                  color: IosColors.resolve(IosColors.secondaryLabel, context),
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 8),
              ...List.generate(_suggestedCommits.length, (idx) {
                final commit = _suggestedCommits[idx];
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: IosColors.resolve(IosColors.secondarySystemGroupedBackground, context),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: IosColors.resolve(IosColors.separator, context),
                      width: 0.5,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                            decoration: BoxDecoration(
                              color: IosColors.systemIndigo.color.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              commit.type,
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: IosColors.systemIndigo,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              commit.summary,
                              style: IosTypography.headline.copyWith(
                                fontSize: 13.5,
                                color: IosColors.resolve(IosColors.label, context),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Branch: ${commit.branchName} • +${commit.additions} -${commit.deletions} LOC',
                        style: IosTypography.caption2.copyWith(
                          color: IosColors.resolve(IosColors.secondaryLabel, context),
                        ),
                      ),
                    ],
                  ),
                );
              }),
              const SizedBox(height: 10),
              CupertinoButton(
                color: IosColors.systemGreen.color,
                borderRadius: BorderRadius.circular(10),
                onPressed: () {
                  HapticFeedback.mediumImpact();
                  Navigator.of(context).pop();
                },
                child: const Text(
                  'Accept All & Stack Commits',
                  style: TextStyle(fontWeight: FontWeight.w600, color: CupertinoColors.white),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ],
        ),
      ),
    );
  }
}

/// Clerk Authentication & User Profile Modal Sheet.
class IosClerkProfileSheet extends ConsumerWidget {
  const IosClerkProfileSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);
    final authNotifier = ref.read(authStateProvider.notifier);
    final session = authState.session;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header with Done
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Developer Profile',
                style: IosTypography.title3.copyWith(
                  color: IosColors.resolve(IosColors.label, context),
                ),
              ),
              CupertinoButton(
                padding: EdgeInsets.zero,
                child: Text(
                  'Done',
                  style: TextStyle(
                    color: IosColors.resolve(IosColors.systemIndigo, context),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // User Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: IosColors.resolve(IosColors.secondarySystemGroupedBackground, context),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: IosColors.resolve(IosColors.separator, context),
                width: 0.5,
              ),
            ),
            child: Row(
              children: [
                IosClerkAvatarButton(onTap: () {}),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        session?.fullName ?? 'Authenticated Developer',
                        style: IosTypography.headline.copyWith(
                          fontSize: 16,
                          color: IosColors.resolve(IosColors.label, context),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        session?.email ?? 'developer@otto.stack',
                        style: IosTypography.footnote.copyWith(
                          color: IosColors.resolve(IosColors.secondaryLabel, context),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Clerk & GitHub Metadata Table
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: IosColors.resolve(IosColors.secondarySystemGroupedBackground, context),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: IosColors.resolve(IosColors.separator, context),
                width: 0.5,
              ),
            ),
            child: Column(
              children: [
                _buildInfoRow(
                  label: 'Auth Provider',
                  value: 'Clerk.dev JWT',
                  context: context,
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: CupertinoDivider(),
                ),
                _buildInfoRow(
                  label: 'GitHub Integration',
                  value: session?.isGithubConnected == true ? 'Connected' : 'Active Token',
                  context: context,
                  statusColor: IosColors.systemGreen.color,
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: CupertinoDivider(),
                ),
                _buildInfoRow(
                  label: 'User ID',
                  value: session?.userId.isNotEmpty == true
                      ? session!.userId.substring(0, 12) + '...'
                      : 'usr_clerk_active',
                  context: context,
                  isMonospace: true,
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Sign Out Action Button
          CupertinoButton(
            color: IosColors.systemRed.color.withOpacity(0.12),
            borderRadius: BorderRadius.circular(12),
            onPressed: () async {
              HapticFeedback.heavyImpact();
              Navigator.of(context).pop();
              await authNotifier.signOut();
            },
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(CupertinoIcons.arrow_right_square, color: IosColors.systemRed.color, size: 18),
                const SizedBox(width: 8),
                Text(
                  'Sign Out from Clerk',
                  style: TextStyle(
                    color: IosColors.systemRed.color,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildInfoRow({
    required String label,
    required String value,
    required BuildContext context,
    Color? statusColor,
    bool isMonospace = false,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: IosTypography.subheadline.copyWith(
            color: IosColors.resolve(IosColors.secondaryLabel, context),
          ),
        ),
        Text(
          value,
          style: isMonospace
              ? IosTypography.monoCode.copyWith(
                  fontWeight: FontWeight.w600,
                  color: statusColor ?? IosColors.resolve(IosColors.label, context),
                )
              : IosTypography.subheadline.copyWith(
                  fontWeight: FontWeight.w600,
                  color: statusColor ?? IosColors.resolve(IosColors.label, context),
                ),
        ),
      ],
    );
  }
}

/// Simple subtle hair-line divider for iOS modal lists.
class CupertinoDivider extends StatelessWidget {
  const CupertinoDivider({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 0.5,
      color: IosColors.resolve(IosColors.separator, context),
    );
  }
}

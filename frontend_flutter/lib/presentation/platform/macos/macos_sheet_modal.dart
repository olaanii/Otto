import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../domain/models/diff_hunk.dart';
import '../../../domain/models/guardrail_policy.dart';
import '../../providers/auth_state_provider.dart';
import '../../providers/llm_selector_provider.dart';
import '../../providers/workspace_provider.dart';
import 'macos_hig_theme.dart';

/// Imperatively display an authentic AppKit-style sheet modal sliding down from titlebar.
Future<T?> showMacOSSheet<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  bool barrierDismissible = true,
}) {
  return showGeneralDialog<T>(
    context: context,
    barrierDismissible: barrierDismissible,
    barrierLabel: 'Dismiss Sheet',
    barrierColor: const Color(0x33000000), // Soft macOS dimming
    transitionDuration: const Duration(milliseconds: 280),
    pageBuilder: (ctx, anim1, anim2) => builder(ctx),
    transitionBuilder: (ctx, anim1, anim2, child) {
      final curved = CurvedAnimation(
        parent: anim1,
        curve: Curves.easeOutCubic,
        reverseCurve: Curves.easeInCubic,
      );

      return SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, -0.15),
          end: Offset.zero,
        ).animate(curved),
        child: FadeTransition(
          opacity: curved,
          child: Align(
            alignment: Alignment.topCenter,
            child: Padding(
              padding: const EdgeInsets.only(top: 52.0), // Below unified toolbar
              child: Material(
                type: MaterialType.transparency,
                child: child,
              ),
            ),
          ),
        ),
      );
    },
  );
}

/// Generic AppKit sheet container replicating macOS Sonoma/Sequoia sheet geometry.
class MacOSSheetModal extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget child;
  final double width;
  final List<Widget>? actions;
  final VoidCallback? onClose;

  const MacOSSheetModal({
    super.key,
    required this.title,
    this.subtitle,
    required this.child,
    this.width = 540.0,
    this.actions,
    this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return MacOSVisualEffectBox(
      width: width,
      blur: 36.0,
      backgroundColor: MacOSTheme.sheetBackground(isDark),
      borderRadius: const BorderRadius.only(
        bottomLeft: Radius.circular(16),
        bottomRight: Radius.circular(16),
      ),
      shadows: MacOSTheme.sheetShadow,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. Sheet Header with Close Button
          Container(
            padding: const EdgeInsets.fromLTRB(20, 16, 16, 12),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: MacOSTheme.subtleBorder(isDark),
                  width: 0.5,
                ),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: MacOSTheme.title2(isDark: isDark).copyWith(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (subtitle != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          subtitle!,
                          style: MacOSTheme.footnote(isDark: isDark).copyWith(
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                // Close button (Mac small rounded icon)
                MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: GestureDetector(
                    onTap: onClose ?? () => Navigator.of(context).pop(),
                    child: Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0x33FFFFFF) : const Color(0x1A000000),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.close,
                        size: 13,
                        color: MacOSTheme.secondaryLabel(isDark),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // 2. Sheet Content Body
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: child,
            ),
          ),

          // 3. Sheet Actions Footer
          if (actions != null && actions!.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(
                    color: MacOSTheme.subtleBorder(isDark),
                    width: 0.5,
                  ),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: actions!,
              ),
            ),
        ],
      ),
    );
  }
}

// =============================================================================
// 1. MacOS Settings Sheet (Guardrails & LLM Provider Configuration)
// =============================================================================
class MacOSSettingsSheet extends ConsumerStatefulWidget {
  const MacOSSettingsSheet({super.key});

  @override
  ConsumerState<MacOSSettingsSheet> createState() => _MacOSSettingsSheetState();
}

class _MacOSSettingsSheetState extends ConsumerState<MacOSSettingsSheet> {
  late double _maxLoc;
  late int _maxFiles;
  late bool _enforceConventional;

  @override
  void initState() {
    super.initState();
    final policy = ref.read(workspaceProvider).guardrailPolicy;
    _maxLoc = policy.maxLocPerCommit.toDouble();
    _maxFiles = policy.maxFilesPerCommit;
    _enforceConventional = policy.enforceConventionalCommits;
  }

  void _saveSettings() {
    final updated = GuardrailPolicy(
      maxLocPerCommit: _maxLoc.toInt(),
      maxFilesPerCommit: _maxFiles,
      enforceConventionalCommits: _enforceConventional,
    );
    ref.read(workspaceProvider.notifier).updateGuardrailPolicy(updated);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final llmState = ref.watch(llmSelectorProvider);
    final llmNotifier = ref.read(llmSelectorProvider.notifier);

    return MacOSSheetModal(
      title: 'Otto Preferences',
      subtitle: 'Configure atomic git guardrails and AI slicing models',
      width: 560,
      actions: [
        // Cancel Button (AppKit Secondary Push Button)
        _buildMacButton(
          label: 'Cancel',
          isPrimary: false,
          isDark: isDark,
          onPressed: () => Navigator.of(context).pop(),
        ),
        const SizedBox(width: 10),
        // Save Changes (AppKit Primary Accent Push Button)
        _buildMacButton(
          label: 'Save Changes',
          isPrimary: true,
          isDark: isDark,
          onPressed: _saveSettings,
        ),
      ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // SECTION: Atomic Git Guardrails
          _buildMacSectionTitle('ATOMIC GIT GUARDRAILS', isDark),
          const SizedBox(height: 10),

          // Max LOC Slider
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Maximum LOC per Commit',
                style: MacOSTheme.body(isDark: isDark).copyWith(fontSize: 12.5),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: MacOSTheme.systemBlue(isDark).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  '${_maxLoc.toInt()} LOC',
                  style: MacOSTheme.code(
                    isDark: isDark,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: MacOSTheme.systemBlue(isDark),
                  ),
                ),
              ),
            ],
          ),
          Slider(
            value: _maxLoc,
            min: 30,
            max: 200,
            divisions: 17,
            activeColor: MacOSTheme.systemBlue(isDark),
            onChanged: (val) => setState(() => _maxLoc = val),
          ),

          const SizedBox(height: 8),

          // Max Files Dropdown
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Maximum Files per Commit',
                style: MacOSTheme.body(isDark: isDark).copyWith(fontSize: 12.5),
              ),
              DropdownButton<int>(
                value: _maxFiles,
                items: [1, 2, 3, 5, 8]
                    .map((n) => DropdownMenuItem(value: n, child: Text('$n files')))
                    .toList(),
                onChanged: (val) {
                  if (val != null) setState(() => _maxFiles = val);
                },
              ),
            ],
          ),

          const SizedBox(height: 8),

          // Conventional Commits Toggle
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(
              'Enforce Conventional Commits (feat, fix, refactor...)',
              style: MacOSTheme.body(isDark: isDark).copyWith(fontSize: 12.5),
            ),
            value: _enforceConventional,
            activeColor: MacOSTheme.systemBlue(isDark),
            onChanged: (val) => setState(() => _enforceConventional = val),
          ),

          const Divider(height: 24),

          // SECTION: AI Refinement Provider
          _buildMacSectionTitle('AI DIFF REFINEMENT PROVIDER', isDark),
          const SizedBox(height: 10),

          DropdownButtonFormField<String>(
            value: llmState.selectedProvider.id,
            decoration: InputDecoration(
              filled: true,
              fillColor: isDark ? const Color(0x33FFFFFF) : const Color(0x14000000),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: MacOSTheme.border(isDark)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: MacOSTheme.border(isDark)),
              ),
            ),
            items: llmState.providers.map((p) {
              return DropdownMenuItem(
                value: p.id,
                child: Text('${p.name} (${p.provider})'),
              );
            }).toList(),
            onChanged: (id) {
              if (id != null) {
                final prov = llmState.providers.firstWhere((p) => p.id == id);
                llmNotifier.selectProvider(prov);
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildMacSectionTitle(String title, bool isDark) {
    return Text(
      title,
      style: MacOSTheme.footnote(isDark: isDark).copyWith(
        fontSize: 10,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.6,
        color: MacOSTheme.tertiaryLabel(isDark),
      ),
    );
  }

  Widget _buildMacButton({
    required String label,
    required bool isPrimary,
    required bool isDark,
    required VoidCallback onPressed,
  }) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onPressed,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6.5),
          decoration: BoxDecoration(
            color: isPrimary
                ? MacOSTheme.systemBlue(isDark)
                : (isDark ? const Color(0x28FFFFFF) : const Color(0x14000000)),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: isPrimary
                  ? Colors.transparent
                  : MacOSTheme.subtleBorder(isDark),
              width: 0.5,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: isPrimary ? Colors.white : MacOSTheme.label(isDark),
            ),
          ),
        ),
      ),
    );
  }
}

// =============================================================================
// 2. MacOS Clerk Authentication Sheet
// =============================================================================
class MacOSClerkAuthSheet extends ConsumerStatefulWidget {
  const MacOSClerkAuthSheet({super.key});

  @override
  ConsumerState<MacOSClerkAuthSheet> createState() => _MacOSClerkAuthSheetState();
}

class _MacOSClerkAuthSheetState extends ConsumerState<MacOSClerkAuthSheet> {
  final TextEditingController _ticketController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _ticketController.dispose();
    super.dispose();
  }

  Future<void> _handleSignIn() async {
    final ticket = _ticketController.text.trim();
    if (ticket.isEmpty) return;

    setState(() => _isLoading = true);
    final success = await ref.read(authStateProvider.notifier).signInWithTicket(ticket);
    if (mounted) setState(() => _isLoading = false);

    if (success && mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final authState = ref.watch(authStateProvider);

    return MacOSSheetModal(
      title: 'Clerk Authentication',
      subtitle: 'Connect your developer account for cloud stack syncing',
      width: 460,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Logo & Welcome
          Center(
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: MacOSTheme.systemBlue(isDark),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Center(
                child: Text(
                  'O',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 14),

          if (authState.isAuthenticated) ...[
            // Logged In Status
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: MacOSTheme.systemGreen(isDark).withOpacity(0.12),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: MacOSTheme.systemGreen(isDark).withOpacity(0.3),
                  width: 0.5,
                ),
              ),
              child: Row(
                children: [
                  Icon(Icons.check_circle, size: 18, color: MacOSTheme.systemGreen(isDark)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Authenticated as ${authState.session?.email ?? "User"}',
                      style: MacOSTheme.subheadline(isDark: isDark).copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            FilledButton.tonal(
              onPressed: () async {
                await ref.read(authStateProvider.notifier).signOut();
              },
              child: const Text('Sign Out of Clerk'),
            ),
          ] else ...[
            // Input Field
            Text(
              'Clerk Dev Ticket or Session Token',
              style: MacOSTheme.footnote(isDark: isDark).copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 6),
            TextField(
              controller: _ticketController,
              obscureText: true,
              style: MacOSTheme.code(isDark: isDark, fontSize: 12),
              decoration: InputDecoration(
                hintText: 'clerk_dev_ticket_...',
                hintStyle: TextStyle(
                  fontSize: 12,
                  color: MacOSTheme.tertiaryLabel(isDark),
                ),
                filled: true,
                fillColor: isDark ? const Color(0x33FFFFFF) : const Color(0x14000000),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(7),
                  borderSide: BorderSide(color: MacOSTheme.border(isDark)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(7),
                  borderSide: BorderSide(color: MacOSTheme.border(isDark)),
                ),
              ),
              onSubmitted: (_) => _handleSignIn(),
            ),
            const SizedBox(height: 14),

            // Authenticate Button
            FilledButton(
              onPressed: _isLoading ? null : _handleSignIn,
              style: FilledButton.styleFrom(
                backgroundColor: MacOSTheme.systemBlue(isDark),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(7)),
              ),
              child: _isLoading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Text(
                      'Authenticate Session',
                      style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600),
                    ),
            ),
            const SizedBox(height: 8),

            // Demo Sign-in
            OutlinedButton(
              onPressed: () {
                _ticketController.text = 'demo_mac_${DateTime.now().millisecondsSinceEpoch}';
                _handleSignIn();
              },
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 10),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(7)),
              ),
              child: const Text('Quick Demo Login', style: TextStyle(fontSize: 12)),
            ),
          ],
        ],
      ),
    );
  }
}

// =============================================================================
// 3. MacOS Commit Split Inspector Sheet
// =============================================================================
class MacOSCommitSplitSheet extends ConsumerStatefulWidget {
  final List<DiffHunk> stagedHunks;

  const MacOSCommitSplitSheet({
    super.key,
    required this.stagedHunks,
  });

  @override
  ConsumerState<MacOSCommitSplitSheet> createState() => _MacOSCommitSplitSheetState();
}

class _MacOSCommitSplitSheetState extends ConsumerState<MacOSCommitSplitSheet> {
  final TextEditingController _summaryController = TextEditingController();
  final TextEditingController _descController = TextEditingController();
  final TextEditingController _scopeController = TextEditingController();
  String _selectedType = 'feat';
  bool _isCommitting = false;

  final List<String> _commitTypes = [
    'feat',
    'fix',
    'refactor',
    'perf',
    'style',
    'test',
    'chore',
    'docs',
  ];

  @override
  void dispose() {
    _summaryController.dispose();
    _descController.dispose();
    _scopeController.dispose();
    super.dispose();
  }

  Future<void> _handleCommit() async {
    final summary = _summaryController.text.trim();
    if (summary.isEmpty) return;

    setState(() => _isCommitting = true);
    final unit = await ref.read(workspaceProvider.notifier).commitSelectedHunks(
          summary: summary,
          description: _descController.text.trim().isEmpty ? null : _descController.text.trim(),
          type: _selectedType,
          scope: _scopeController.text.trim().isEmpty ? null : _scopeController.text.trim(),
          hunks: widget.stagedHunks,
        );
    if (mounted) setState(() => _isCommitting = false);

    if (unit != null && mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final workspace = ref.watch(workspaceProvider);

    final stagedAdditions = widget.stagedHunks.fold<int>(0, (s, h) => s + h.additionsCount);
    final stagedDeletions = widget.stagedHunks.fold<int>(0, (s, h) => s + h.deletionsCount);
    final totalLoc = stagedAdditions + stagedDeletions;
    final maxLoc = workspace.guardrailPolicy.maxLocPerCommit;
    final isWarning = totalLoc > maxLoc;

    return MacOSSheetModal(
      title: 'Inspect & Commit Sliced Diff',
      subtitle: 'Create an atomic commit unit to grow the current PR stack',
      width: 580,
      actions: [
        OutlinedButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        const SizedBox(width: 10),
        FilledButton(
          onPressed: (_isCommitting || widget.stagedHunks.isEmpty) ? null : _handleCommit,
          style: FilledButton.styleFrom(
            backgroundColor: MacOSTheme.systemBlue(isDark),
          ),
          child: _isCommitting
              ? const SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
              : Text('Create Commit ($totalLoc LOC)'),
        ),
      ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // LOC Guardrail Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: isWarning
                  ? MacOSTheme.systemRed(isDark).withOpacity(0.12)
                  : MacOSTheme.systemGreen(isDark).withOpacity(0.12),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isWarning
                    ? MacOSTheme.systemRed(isDark).withOpacity(0.4)
                    : MacOSTheme.systemGreen(isDark).withOpacity(0.4),
                width: 0.5,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  isWarning ? Icons.warning_rounded : Icons.check_circle_outline,
                  size: 16,
                  color: isWarning
                      ? MacOSTheme.systemRed(isDark)
                      : MacOSTheme.systemGreen(isDark),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    isWarning
                        ? 'Warning: $totalLoc LOC exceeds atomic guardrail limit of $maxLoc LOC'
                        : 'Atomic Guardrail Passed: $totalLoc LOC (+$stagedAdditions / -$stagedDeletions) across ${widget.stagedHunks.length} hunks',
                    style: MacOSTheme.footnote(isDark: isDark).copyWith(
                      fontWeight: FontWeight.w600,
                      color: isWarning
                          ? MacOSTheme.systemRed(isDark)
                          : MacOSTheme.systemGreen(isDark),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Conventional Commit Type & Scope Row
          Row(
            children: [
              // Type Dropdown
              Expanded(
                flex: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Type', style: MacOSTheme.footnote(isDark: isDark)),
                    const SizedBox(height: 4),
                    DropdownButtonFormField<String>(
                      value: _selectedType,
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: isDark ? const Color(0x33FFFFFF) : const Color(0x14000000),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(7)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      ),
                      items: _commitTypes
                          .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                          .toList(),
                      onChanged: (val) {
                        if (val != null) setState(() => _selectedType = val);
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),

              // Scope Input
              Expanded(
                flex: 3,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Scope (Optional)', style: MacOSTheme.footnote(isDark: isDark)),
                    const SizedBox(height: 4),
                    TextField(
                      controller: _scopeController,
                      decoration: InputDecoration(
                        hintText: 'e.g., auth, diff-engine',
                        filled: true,
                        fillColor: isDark ? const Color(0x33FFFFFF) : const Color(0x14000000),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(7)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Summary Input
          Text('Commit Summary', style: MacOSTheme.footnote(isDark: isDark)),
          const SizedBox(height: 4),
          TextField(
            controller: _summaryController,
            decoration: InputDecoration(
              hintText: 'e.g., add virtual diff sliver rendering',
              filled: true,
              fillColor: isDark ? const Color(0x33FFFFFF) : const Color(0x14000000),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(7)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
            ),
          ),
          const SizedBox(height: 12),

          // Description Input
          Text('Extended Description (Markdown / Optional)', style: MacOSTheme.footnote(isDark: isDark)),
          const SizedBox(height: 4),
          TextField(
            controller: _descController,
            maxLines: 3,
            decoration: InputDecoration(
              hintText: 'Explain the intent and architectural reason for this commit slice...',
              filled: true,
              fillColor: isDark ? const Color(0x33FFFFFF) : const Color(0x14000000),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(7)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
            ),
          ),
        ],
      ),
    );
  }
}

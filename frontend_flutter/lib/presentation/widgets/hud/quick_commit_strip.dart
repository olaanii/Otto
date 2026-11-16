import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/colors.dart';
import '../../../core/constants/guardrail_defaults.dart';
import '../../../domain/models/diff_hunk.dart';
import '../../providers/llm_selector_provider.dart';

/// Single-line interactive strip for rapidly committing staged hunks.
class QuickCommitStrip extends ConsumerStatefulWidget {
  final List<DiffHunk> stagedHunks;
  final Future<void> Function({
    required String summary,
    String? description,
    required String type,
    String? scope,
  }) onCommit;

  const QuickCommitStrip({
    super.key,
    required this.stagedHunks,
    required this.onCommit,
  });

  @override
  ConsumerState<QuickCommitStrip> createState() => _QuickCommitStripState();
}

class _QuickCommitStripState extends ConsumerState<QuickCommitStrip> {
  final TextEditingController _summaryController = TextEditingController();
  final TextEditingController _scopeController = TextEditingController();
  String _selectedType = 'feat';
  bool _isGeneratingAi = false;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _summaryController.dispose();
    _scopeController.dispose();
    super.dispose();
  }

  Future<void> _generateAiMessage() async {
    if (widget.stagedHunks.isEmpty) return;
    setState(() => _isGeneratingAi = true);
    try {
      final res = await ref
          .read(llmSelectorProvider.notifier)
          .generateConventionalCommit(widget.stagedHunks);

      setState(() {
        _selectedType = res.type;
        _summaryController.text = res.summary;
        if (res.scope != null) _scopeController.text = res.scope!;
      });
    } finally {
      setState(() => _isGeneratingAi = false);
    }
  }

  Future<void> _submitCommit() async {
    final summary = _summaryController.text.trim();
    if (summary.isEmpty || widget.stagedHunks.isEmpty) return;

    setState(() => _isSubmitting = true);
    try {
      await widget.onCommit(
        summary: summary,
        type: _selectedType,
        scope: _scopeController.text.trim().isNotEmpty ? _scopeController.text.trim() : null,
      );
      _summaryController.clear();
      _scopeController.clear();
    } finally {
      setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.cardLight,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.borderLight,
        ),
      ),
      child: Row(
        children: [
          // Conventional Type Dropdown
          DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _selectedType,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isDark ? AppColors.zinc100 : AppColors.zinc900,
              ),
              dropdownColor: isDark ? AppColors.cardDark : Colors.white,
              items: GuardrailDefaults.conventionalCommitTypes.map((type) {
                return DropdownMenuItem(value: type, child: Text(type));
              }).toList(),
              onChanged: (val) {
                if (val != null) setState(() => _selectedType = val);
              },
            ),
          ),
          const SizedBox(width: 6),

          // Scope Input
          SizedBox(
            width: 80,
            child: TextField(
              controller: _scopeController,
              decoration: const InputDecoration(
                hintText: '(scope)',
                hintStyle: TextStyle(fontSize: 12),
                isDense: true,
                border: InputBorder.none,
              ),
              style: const TextStyle(fontSize: 12),
            ),
          ),
          const SizedBox(width: 6),

          // Summary Input
          Expanded(
            child: TextField(
              controller: _summaryController,
              decoration: const InputDecoration(
                hintText: 'Commit summary adhering to atomic guardrails...',
                hintStyle: TextStyle(fontSize: 12),
                isDense: true,
                border: InputBorder.none,
              ),
              style: const TextStyle(fontSize: 12),
              onSubmitted: (_) => _submitCommit(),
            ),
          ),
          const SizedBox(width: 8),

          // AI Generate Message Button
          IconButton(
            icon: _isGeneratingAi
                ? const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.auto_awesome, size: 16),
            tooltip: 'Auto-synthesize conventional commit with AI',
            onPressed: widget.stagedHunks.isNotEmpty && !_isGeneratingAi
                ? _generateAiMessage
                : null,
          ),
          const SizedBox(width: 6),

          // Commit Button
          FilledButton(
            onPressed: widget.stagedHunks.isNotEmpty && !_isSubmitting
                ? _submitCommit
                : null,
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.indigo600,
              visualDensity: VisualDensity.compact,
            ),
            child: _isSubmitting
                ? const SizedBox(
                    width: 12,
                    height: 12,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : const Text('Commit', style: TextStyle(fontSize: 12)),
          ),
        ],
      ),
    );
  }
}

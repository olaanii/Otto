import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/colors.dart';
import '../../core/theme/typography.dart';
import '../../domain/models/guardrail_policy.dart';
import '../providers/llm_selector_provider.dart';
import '../providers/workspace_provider.dart';

/// Settings modal for configuring Atomic Git Guardrails and LLM Provider parameters.
class SettingsDialog extends ConsumerStatefulWidget {
  const SettingsDialog({super.key});

  @override
  ConsumerState<SettingsDialog> createState() => _SettingsDialogState();
}

class _SettingsDialogState extends ConsumerState<SettingsDialog> {
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
    final updatedPolicy = GuardrailPolicy(
      maxLocPerCommit: _maxLoc.toInt(),
      maxFilesPerCommit: _maxFiles,
      enforceConventionalCommits: _enforceConventional,
    );

    ref.read(workspaceProvider.notifier).updateGuardrailPolicy(updatedPolicy);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final llmState = ref.watch(llmSelectorProvider);
    final llmNotifier = ref.read(llmSelectorProvider.notifier);

    return Dialog(
      backgroundColor: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(
          color: isDark ? AppColors.borderDark : AppColors.borderLight,
        ),
      ),
      child: Container(
        width: 560,
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Row(
              children: [
                Icon(Icons.tune, size: 20, color: AppColors.indigo500),
                const SizedBox(width: 10),
                Text(
                  'Workspace Settings',
                  style: AppTypography.uiFont.copyWith(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close, size: 18),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const Divider(height: 24),

            // Section 1: Atomic PR Guardrails
            Text(
              'Atomic Git Guardrails',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: isDark ? AppColors.zinc200 : AppColors.zinc800,
              ),
            ),
            const SizedBox(height: 12),

            // Max LOC Slider
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Max LOC per commit',
                  style: TextStyle(fontSize: 12.5, color: isDark ? AppColors.zinc300 : AppColors.zinc700),
                ),
                Text(
                  '${_maxLoc.toInt()} LOC',
                  style: AppTypography.codeFont.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.indigo500,
                  ),
                ),
              ],
            ),
            Slider(
              value: _maxLoc,
              min: 30,
              max: 200,
              divisions: 17,
              activeColor: AppColors.indigo500,
              onChanged: (val) => setState(() => _maxLoc = val),
            ),

            // Max Files
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Max Files per commit',
                  style: TextStyle(fontSize: 12.5, color: isDark ? AppColors.zinc300 : AppColors.zinc700),
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

            // Conventional Commits Toggle
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Enforce Conventional Commits (feat, fix, refactor...)', style: TextStyle(fontSize: 12.5)),
              value: _enforceConventional,
              onChanged: (val) => setState(() => _enforceConventional = val),
            ),

            const Divider(height: 24),

            // Section 2: LLM Provider Configuration
            Text(
              'AI Diff Refinement Provider',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: isDark ? AppColors.zinc200 : AppColors.zinc800,
              ),
            ),
            const SizedBox(height: 10),

            DropdownButtonFormField<String>(
              value: llmState.selectedProvider.id,
              decoration: InputDecoration(
                filled: true,
                fillColor: isDark ? AppColors.cardDark : AppColors.cardLight,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
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

            const SizedBox(height: 24),

            // Action Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                OutlinedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
                const SizedBox(width: 10),
                FilledButton(
                  onPressed: _saveSettings,
                  style: FilledButton.styleFrom(backgroundColor: AppColors.indigo600),
                  child: const Text('Save Changes'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

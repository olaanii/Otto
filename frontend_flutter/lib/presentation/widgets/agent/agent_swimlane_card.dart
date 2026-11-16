import 'package:flutter/material.dart';
import '../../../core/constants/colors.dart';
import '../../../core/theme/typography.dart';
import '../../../domain/models/ide_agent_profile.dart';
import 'agent_icon_avatar.dart';

/// Workspace sidebar card representing an active IDE AI Agent swimlane.
class AgentSwimlaneCard extends StatelessWidget {
  final IdeAgentProfile agent;
  final VoidCallback? onSliceAgentChanges;

  const AgentSwimlaneCard({
    super.key,
    required this.agent,
    this.onSliceAgentChanges,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : AppColors.cardLight,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: agent.isActive
              ? AppColors.indigo500.withOpacity(0.5)
              : (isDark ? AppColors.borderDark : AppColors.borderLight),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              AgentIconAvatar(agent: agent, size: 26),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      agent.name,
                      style: AppTypography.uiFont.copyWith(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: isDark ? AppColors.zinc100 : AppColors.zinc900,
                      ),
                    ),
                    Text(
                      agent.isActive ? 'Active in workspace' : 'Idle',
                      style: TextStyle(
                        fontSize: 10.5,
                        color: agent.isActive ? AppColors.emerald500 : AppColors.zinc500,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              if (onSliceAgentChanges != null && agent.isActive)
                IconButton(
                  icon: const Icon(Icons.auto_fix_high, size: 16),
                  tooltip: 'Slice changes by this agent into atomic commit',
                  visualDensity: VisualDensity.compact,
                  onPressed: onSliceAgentChanges,
                ),
            ],
          ),
          if (agent.currentPrompt != null && agent.currentPrompt!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
              decoration: BoxDecoration(
                color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                agent.currentPrompt!,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.codeFont.copyWith(
                  fontSize: 11,
                  color: isDark ? AppColors.zinc300 : AppColors.zinc700,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

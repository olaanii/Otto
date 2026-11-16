import 'package:flutter/material.dart';
import '../../../core/constants/colors.dart';
import '../../../domain/models/ide_agent_profile.dart';

/// Avatar glyph representing an IDE AI Agent with active presence badge.
class AgentIconAvatar extends StatelessWidget {
  final IdeAgentProfile agent;
  final double size;

  const AgentIconAvatar({
    super.key,
    required this.agent,
    this.size = 28,
  });

  @override
  Widget build(BuildContext context) {
    Color agentColor = AppColors.indigo500;
    try {
      final hex = agent.colorHex.replaceAll('#', '');
      agentColor = Color(int.parse('FF$hex', radix: 16));
    } catch (_) {}

    return Stack(
      children: [
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: agentColor.withOpacity(0.18),
            shape: BoxShape.circle,
            border: Border.all(color: agentColor.withOpacity(0.4), width: 1),
          ),
          child: Center(
            child: Icon(
              switch (agent.iconKey) {
                'claude' => Icons.psychology,
                'cursor' => Icons.edit_note,
                'cline' => Icons.code,
                _ => Icons.smart_toy_outlined,
              },
              size: size * 0.55,
              color: agentColor,
            ),
          ),
        ),
        if (agent.isActive)
          Positioned(
            right: 0,
            bottom: 0,
            child: Container(
              width: size * 0.32,
              height: size * 0.32,
              decoration: BoxDecoration(
                color: AppColors.emerald500,
                shape: BoxShape.circle,
                border: Border.all(
                  color: Theme.of(context).scaffoldBackgroundColor,
                  width: 1.5,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

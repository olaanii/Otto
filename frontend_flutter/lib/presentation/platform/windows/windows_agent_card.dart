import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../domain/models/ide_agent_profile.dart';
import '../windows/windows_agent_connector.dart'; import '../windows/windows_fluent_theme.dart';
import '../../providers/workspace_provider.dart';

class WindowsAgentCard extends ConsumerWidget {
  final IdeAgentProfile agent;
  final WorkspaceState workspace;
  final void Function({required String message, bool isError}) showInfoBar;

  const WindowsAgentCard({super.key, required this.agent, required this.workspace, required this.showInfoBar});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isConnected = agent.isActive;
    final isAwaiting = agent.isAwaitingConfirmation;
    Color logoBg = const Color(0xFF4285F4);
    try {
      logoBg = Color(int.parse(agent.colorHex.replaceFirst('#', '0xFF')));
    } catch (_) {}
    final letter = agent.name.isNotEmpty ? agent.name[0].toUpperCase() : 'A';
    final badgeColor = isConnected ? const Color(0xFF6CCB5F) : (isAwaiting ? const Color(0xFFF59E0B) : const Color(0xFF8A8A8A));
    final badgeText = isConnected ? 'Connected & Active' : (isAwaiting ? 'Awaiting Approval...' : 'Not connected');
    final actionText = isConnected ? 'Open IDE ↗' : (isAwaiting ? 'Confirm ↗' : 'Connect ↗');
    final borderColor = isConnected ? const Color(0xFF6CCB5F) : (isAwaiting ? const Color(0xFFF59E0B) : const Color(0xFF3A3A3A));

    return GestureDetector(
      onTap: () {
        if (isAwaiting) {
          WindowsAgentConnector.showHandshakeDialog(context: context, ref: ref, agent: agent, showInfoBar: showInfoBar);
        } else if (!isConnected) {
          WindowsAgentConnector.connect(ref: ref, context: context, agent: agent, repoPath: workspace.repositoryPath, showInfoBar: showInfoBar);
        } else {
          WindowsAgentConnector.showOptions(context: context, ref: ref, agent: agent, repoPath: workspace.repositoryPath, showInfoBar: showInfoBar);
        }
      },
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFF2B2B2B),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: borderColor, width: (isConnected || isAwaiting) ? 1.5 : 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(color: logoBg, borderRadius: BorderRadius.circular(18)),
                      alignment: Alignment.center,
                      child: Text(letter, style: const TextStyle(fontFamily: FluentTypography.fontFamily, fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white)),
                    ),
                    const SizedBox(width: 10),
                    Expanded(child: Text(agent.name, style: const TextStyle(fontFamily: FluentTypography.fontFamily, fontSize: 13, fontWeight: FontWeight.w500, color: Colors.white), maxLines: 1, overflow: TextOverflow.ellipsis)),
                  ],
                ),
                const SizedBox(height: 8),
                Text(agent.description, style: const TextStyle(fontFamily: FluentTypography.fontFamily, fontSize: 11, fontWeight: FontWeight.w400, color: Color(0xFFB3B3B3)), maxLines: 2, overflow: TextOverflow.ellipsis),
              ],
            ),
            Row(
              children: [
                Expanded(
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(color: const Color(0xFF3A3A3A), borderRadius: BorderRadius.circular(10)),
                      child: Text(badgeText, style: TextStyle(fontFamily: FluentTypography.fontFamily, fontSize: 10, fontWeight: FontWeight.w500, color: badgeColor), overflow: TextOverflow.ellipsis),
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                Text(actionText, style: const TextStyle(fontFamily: FluentTypography.fontFamily, fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF60CDFF))),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

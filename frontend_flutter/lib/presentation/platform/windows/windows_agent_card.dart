import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/api_endpoints.dart';
import '../../../domain/models/ide_agent_profile.dart';
import '../../providers/auth_state_provider.dart';
import '../../providers/workspace_provider.dart';
import 'windows_agent_connector.dart';
import 'windows_fluent_theme.dart';

class WindowsAgentCard extends ConsumerStatefulWidget {
  final IdeAgentProfile agent;
  final WorkspaceState workspace;
  final void Function({required String message, bool isError}) showInfoBar;
  final void Function(String path)? onOpenProject;

  const WindowsAgentCard({
    super.key,
    required this.agent,
    required this.workspace,
    required this.showInfoBar,
    this.onOpenProject,
  });

  @override
  ConsumerState<WindowsAgentCard> createState() => _WindowsAgentCardState();
}

class _WindowsAgentCardState extends ConsumerState<WindowsAgentCard> {
  List<Map<String, dynamic>> _discoveredProjects = [];

  @override
  void initState() {
    super.initState();
    _fetchDiscoveredProjects();
  }

  @override
  void didUpdateWidget(covariant WindowsAgentCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.agent.id != widget.agent.id || oldWidget.agent.isActive != widget.agent.isActive) {
      _fetchDiscoveredProjects();
    }
  }

  Future<void> _fetchDiscoveredProjects() async {
    try {
      final client = ref.read(apiClientProvider);
      final res = await client.get<Map<String, dynamic>>(
        '${ApiEndpoints.agentsDiscoveredProjects}?agentId=${widget.agent.id}',
      );
      if (mounted && res.data?['ok'] == true) {
        final list = (res.data?['projects'] as List<dynamic>? ?? [])
            .map((e) => Map<String, dynamic>.from(e as Map))
            .toList();
        setState(() => _discoveredProjects = list);
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final agent = widget.agent;
    final workspace = widget.workspace;
    final isConnected = agent.isActive;
    final isAwaiting = agent.isAwaitingConfirmation;

    Color logoBg = const Color(0xFF4285F4);
    try {
      logoBg = Color(int.parse(agent.colorHex.replaceFirst('#', '0xFF')));
    } catch (_) {}
    final letter = agent.name.isNotEmpty ? agent.name[0].toUpperCase() : 'A';
    final badgeColor = isConnected
        ? const Color(0xFF6CCB5F)
        : (isAwaiting ? const Color(0xFFF59E0B) : const Color(0xFF8A8A8A));
    final badgeText = isConnected
        ? 'Connected & Active'
        : (isAwaiting ? 'Awaiting Approval...' : 'Not connected');
    final actionText = isConnected ? 'Open IDE ↗' : (isAwaiting ? 'Confirm ↗' : 'Connect ↗');
    final borderColor = isConnected
        ? const Color(0xFF6CCB5F)
        : (isAwaiting ? const Color(0xFFF59E0B) : const Color(0xFF3A3A3A));

    return GestureDetector(
      onTap: () {
        if (isAwaiting) {
          WindowsAgentConnector.showHandshakeDialog(
            context: context,
            ref: ref,
            agent: agent,
            showInfoBar: widget.showInfoBar,
          );
        } else if (!isConnected) {
          WindowsAgentConnector.connect(
            ref: ref,
            context: context,
            agent: agent,
            repoPath: workspace.repositoryPath,
            showInfoBar: widget.showInfoBar,
          );
        } else {
          WindowsAgentConnector.showOptions(
            context: context,
            ref: ref,
            agent: agent,
            repoPath: workspace.repositoryPath,
            showInfoBar: widget.showInfoBar,
          );
        }
      },
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFF2B2B2B),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: borderColor,
            width: (isConnected || isAwaiting) ? 1.5 : 1,
          ),
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
                      decoration: BoxDecoration(
                        color: logoBg,
                        borderRadius: BorderRadius.circular(18),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        letter,
                        style: const TextStyle(
                          fontFamily: FluentTypography.fontFamily,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        agent.name,
                        style: const TextStyle(
                          fontFamily: FluentTypography.fontFamily,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: Colors.white,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  agent.description,
                  style: const TextStyle(
                    fontFamily: FluentTypography.fontFamily,
                    fontSize: 11,
                    fontWeight: FontWeight.w400,
                    color: Color(0xFFB3B3B3),
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                if (_discoveredProjects.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  const Text(
                    'Discovered Projects:',
                    style: TextStyle(
                      fontFamily: FluentTypography.fontFamily,
                      fontSize: 10.5,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF60CDFF),
                    ),
                  ),
                  const SizedBox(height: 4),
                  for (final p in _discoveredProjects.take(2))
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Row(
                        children: [
                          const Icon(Icons.folder_outlined, size: 12, color: Color(0xFF60CDFF)),
                          const SizedBox(width: 5),
                          Expanded(
                            child: Text(
                              p['name'] as String? ?? '',
                              style: const TextStyle(
                                fontFamily: FluentTypography.fontFamily,
                                fontSize: 11,
                                color: Color(0xFFDDDDDD),
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 4),
                          InkWell(
                            onTap: () {
                              final path = p['path'] as String? ?? '';
                              if (path.isNotEmpty) {
                                widget.onOpenProject?.call(path);
                              }
                            },
                            borderRadius: BorderRadius.circular(4),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFF1E3A5F),
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(color: const Color(0xFF60CDFF), width: 0.8),
                              ),
                              child: const Text(
                                'Open in Otto',
                                style: TextStyle(
                                  fontFamily: FluentTypography.fontFamily,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF60CDFF),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ],
            ),
            Row(
              children: [
                Expanded(
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFF3A3A3A),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        badgeText,
                        style: TextStyle(
                          fontFamily: FluentTypography.fontFamily,
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                          color: badgeColor,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  actionText,
                  style: const TextStyle(
                    fontFamily: FluentTypography.fontFamily,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF60CDFF),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

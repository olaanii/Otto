import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/api_endpoints.dart';
import '../../../domain/models/ide_agent_profile.dart';
import '../../providers/auth_state_provider.dart';
import '../../providers/workspace_provider.dart';

class WindowsAgentConnector {
  static Future<void> connect({
    required WidgetRef ref,
    required BuildContext context,
    required IdeAgentProfile agent,
    required String repoPath,
    required void Function({required String message, bool isError}) showInfoBar,
  }) async {
    final client = ref.read(apiClientProvider);
    try {
      final res = await client.post<Map<String, dynamic>>(
        ApiEndpoints.agentsConnect,
        data: {
          'agentId': agent.id,
          'workspacePath': repoPath,
        },
      );
      final ok = res.data?['ok'] == true;
      final uri = res.data?['protocolUri'] as String? ?? '';
      if (ok) {
        await ref.read(workspaceProvider.notifier).refreshWorkspace();
        showInfoBar(message: 'Launched and connected ${agent.name} ($uri)');
      } else {
        showInfoBar(message: 'Failed to connect ${agent.name}', isError: true);
      }
    } catch (e) {
      showInfoBar(message: 'Connection failed: $e', isError: true);
    }
  }

  static Future<void> disconnect({
    required WidgetRef ref,
    required IdeAgentProfile agent,
    required void Function({required String message, bool isError}) showInfoBar,
  }) async {
    final client = ref.read(apiClientProvider);
    try {
      await client.post<Map<String, dynamic>>(
        ApiEndpoints.agentsDisconnect,
        data: {'agentId': agent.id},
      );
      await ref.read(workspaceProvider.notifier).refreshWorkspace();
      showInfoBar(message: '${agent.name} disconnected');
    } catch (e) {
      showInfoBar(message: 'Failed to disconnect: $e', isError: true);
    }
  }

  static void showOptions({
    required BuildContext context,
    required WidgetRef ref,
    required IdeAgentProfile agent,
    required String repoPath,
    required void Function({required String message, bool isError}) showInfoBar,
  }) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF242424),
        title: Text(agent.name, style: const TextStyle(color: Colors.white, fontSize: 16)),
        content: const Text(
          'Agent is active and connected. Deep link URI launches and focuses the IDE with workspace bridge rules enabled.',
          style: TextStyle(color: Color(0xFFCCCCCC), fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () async {
              Navigator.of(ctx).pop();
              await disconnect(ref: ref, agent: agent, showInfoBar: showInfoBar);
            },
            child: const Text('Disconnect', style: TextStyle(color: Colors.redAccent)),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.of(ctx).pop();
              await connect(ref: ref, context: context, agent: agent, repoPath: repoPath, showInfoBar: showInfoBar);
            },
            child: const Text('Focus in IDE ↗'),
          ),
        ],
      ),
    );
  }
}

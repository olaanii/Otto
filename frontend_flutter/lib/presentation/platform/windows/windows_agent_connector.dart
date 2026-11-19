import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/api_endpoints.dart';
import '../../../core/network/api_client.dart';
import '../../../domain/models/ide_agent_profile.dart';
import '../../providers/workspace_provider.dart';

class WindowsAgentConnector {
  static Future<void> connect({
    required WidgetRef ref,
    required BuildContext context,
    required IdeAgentProfile agent,
    required String repoPath,
    required void Function(String message, {bool isError}) showInfoBar,
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
        showInfoBar('Launched and connected ${agent.name} ($uri)');
      } else {
        showInfoBar('Failed to connect ${agent.name}', isError: true);
      }
    } catch (e) {
      showInfoBar('Connection failed: $e', isError: true);
    }
  }

  static Future<void> disconnect({
    required WidgetRef ref,
    required IdeAgentProfile agent,
    required void Function(String message, {bool isError}) showInfoBar,
  }) async {
    final client = ref.read(apiClientProvider);
    try {
      await client.post<Map<String, dynamic>>(
        ApiEndpoints.agentsDisconnect,
        data: {'agentId': agent.id},
      );
      await ref.read(workspaceProvider.notifier).refreshWorkspace();
      showInfoBar('${agent.name} disconnected');
    } catch (e) {
      showInfoBar('Failed to disconnect: $e', isError: true);
    }
  }
}

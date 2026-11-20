import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:window_manager/window_manager.dart';
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
      if (ok) {
        await ref.read(workspaceProvider.notifier).refreshWorkspace();
        final authUrl = res.data?['authUrl'] as String?;
        showInfoBar(message: 'Redirected to ${agent.name}. Please confirm connection.');
        showHandshakeDialog(
          context: context,
          ref: ref,
          agent: agent,
          authUrl: authUrl,
          showInfoBar: showInfoBar,
        );
      } else {
        showInfoBar(message: 'Failed to connect ${agent.name}', isError: true);
      }
    } catch (e) {
      showInfoBar(message: 'Connection failed: $e', isError: true);
    }
  }

  static void showHandshakeDialog({
    required BuildContext context,
    required WidgetRef ref,
    required IdeAgentProfile agent,
    String? authUrl,
    required void Function({required String message, bool isError}) showInfoBar,
  }) {
    Timer? pollTimer;
    showDialog<void>(
      context: context,
      builder: (ctx) {
        pollTimer ??= Timer.periodic(const Duration(milliseconds: 1500), (t) async {
          await ref.read(workspaceProvider.notifier).refreshWorkspace();
          final current = ref.read(workspaceProvider).activeAgents.where((a) => a.id == agent.id).firstOrNull;
          if (current != null && current.isActive) {
            t.cancel();
            if (Navigator.of(ctx).canPop()) {
              Navigator.of(ctx).pop();
              showInfoBar(message: '${agent.name} connected successfully!');
            }
          }
        });
        return AlertDialog(
          backgroundColor: const Color(0xFF242424),
          title: Row(
            children: [
              const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF60CDFF))),
              const SizedBox(width: 8),
              Text('Confirm in ${agent.name}', style: const TextStyle(color: Colors.white, fontSize: 15)),
            ],
          ),
          content: const Text(
            'Otto opened the authorization prompt in your browser. Confirm there or click Open Browser below.',
            style: TextStyle(color: Color(0xFFCCCCCC), fontSize: 12.5),
          ),
          actions: [
            TextButton(
              onPressed: () {
                pollTimer?.cancel();
                Navigator.of(ctx).pop();
              },
              child: const Text('Cancel', style: TextStyle(color: Color(0xFF8A8A8A))),
            ),
            if (authUrl != null && authUrl.isNotEmpty)
              TextButton.icon(
                icon: const Icon(Icons.open_in_browser_rounded, size: 14),
                label: const Text('Open Browser'),
                onPressed: () => Process.run('cmd', ['/c', 'start', '', authUrl]),
              ),
            FilledButton(
              onPressed: () async {
                pollTimer?.cancel();
                Navigator.of(ctx).pop();
                try {
                  await windowManager.show();
                  await windowManager.focus();
                } catch (_) {}
                await ref.read(workspaceProvider.notifier).refreshWorkspace();
                showInfoBar(message: '${agent.name} connection confirmed & synchronized.');
              },
              child: const Text('I Have Confirmed ↗'),
            ),
          ],
        );
      },
    ).then((_) => pollTimer?.cancel());
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

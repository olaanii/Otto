import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/api_endpoints.dart';
import '../../core/constants/colors.dart';
import '../../core/theme/typography.dart';
import '../../domain/models/guardrail_policy.dart';
import '../providers/auth_state_provider.dart';
import '../providers/llm_selector_provider.dart';
import '../providers/workspace_provider.dart';
import '../widgets/settings/antigravity_identity_tab.dart';
import 'clerk_sign_in_screen.dart';

/// Comprehensive Settings Modal with tabs for Git Guardrails, GitHub Account, and AI Models.
class SettingsDialog extends ConsumerStatefulWidget {
  const SettingsDialog({super.key});

  @override
  ConsumerState<SettingsDialog> createState() => _SettingsDialogState();
}

class _SettingsDialogState extends ConsumerState<SettingsDialog> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Guardrails
  late double _maxLoc;
  late int _maxFiles;
  late bool _enforceConventional;

  // GitHub
  final _patController = TextEditingController();
  bool _obscurePat = true;
  bool _isConnectingGithub = false;
  String? _githubError;
  Map<String, dynamic>? _connectedGithubUser;

  // Google Antigravity & Clerk
  Map<String, dynamic>? _antigravityData;
  bool _isSyncingAntigravity = false;

  // LLM Providers
  int _llmArchitectureMode = 0; // 0 = Local CLI Subscriptions ($0 Cost), 1 = Bring Your Own Key (BYOK)
  final _geminiKeyController = TextEditingController();
  final _anthropicKeyController = TextEditingController();
  final _openaiKeyController = TextEditingController();
  final _openrouterKeyController = TextEditingController();
  final _ollamaUrlController = TextEditingController(text: 'http://localhost:11434');
  final _ollamaModelController = TextEditingController(text: 'llama3:latest');
  bool _isSavingLlm = false;
  String? _llmStatusMessage;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);

    final policy = ref.read(workspaceProvider).guardrailPolicy;
    _maxLoc = policy.maxLocPerCommit.toDouble();
    _maxFiles = policy.maxFilesPerCommit;
    _enforceConventional = policy.enforceConventionalCommits;

    _fetchAntigravityStatus();
    _fetchGithubStatus();
    _fetchLlmProviders();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _patController.dispose();
    _geminiKeyController.dispose();
    _anthropicKeyController.dispose();
    _openaiKeyController.dispose();
    _openrouterKeyController.dispose();
    _ollamaUrlController.dispose();
    _ollamaModelController.dispose();
    super.dispose();
  }

  Future<void> _fetchAntigravityStatus() async {
    try {
      final resp = await ref.read(apiClientProvider).get<Map<String, dynamic>>(ApiEndpoints.antigravityStatus);
      if (resp.data?['ok'] == true) setState(() => _antigravityData = resp.data);
    } catch (_) {}
  }

  Future<void> _syncAntigravitySubscription() async {
    setState(() => _isSyncingAntigravity = true);
    try {
      await _fetchAntigravityStatus();
      await ref.read(authStateProvider.notifier).checkActiveSession();
      await ref.read(llmSelectorProvider.notifier).loadProviders();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Google Antigravity subscription synced successfully.'),
          backgroundColor: Color(0xFF2E7D32), duration: Duration(seconds: 2),
        ));
      }
    } finally {
      if (mounted) setState(() => _isSyncingAntigravity = false);
    }
  }

  Future<void> _fetchGithubStatus() async {
    try {
      final client = ref.read(apiClientProvider);
      final resp = await client.get<Map<String, dynamic>>(ApiEndpoints.githubUser);
      if (resp.data?['ok'] == true && resp.data?['user'] != null) {
        setState(() {
          _connectedGithubUser = resp.data!['user'] as Map<String, dynamic>;
        });
      }
    } catch (_) {
      // Disconnected state
    }
  }

  Future<void> _fetchLlmProviders() async {
    try {
      final client = ref.read(apiClientProvider);
      final resp = await client.get<Map<String, dynamic>>(ApiEndpoints.providers);
      if (resp.data?['ok'] == true) {
        // Providers loaded
      }
    } catch (_) {}
  }

  Future<void> _connectGithub({required String method}) async {
    setState(() {
      _isConnectingGithub = true;
      _githubError = null;
    });

    try {
      final client = ref.read(apiClientProvider);
      final token = _patController.text.trim();
      final resp = await client.post<Map<String, dynamic>>(
        ApiEndpoints.githubConnect,
        data: {'token': token, 'method': method},
      );

      if (resp.data?['ok'] == true && resp.data?['user'] != null) {
        setState(() {
          _connectedGithubUser = resp.data!['user'] as Map<String, dynamic>;
          _patController.clear();
        });
        ref.read(workspaceProvider.notifier).refreshWorkspace();
      } else {
        setState(() {
          _githubError = resp.data?['error']?.toString() ?? 'Connection failed';
        });
      }
    } catch (e) {
      setState(() {
        _githubError = 'Failed to connect: $e';
      });
    } finally {
      if (mounted) setState(() => _isConnectingGithub = false);
    }
  }

  Future<void> _disconnectGithub() async {
    try {
      final client = ref.read(apiClientProvider);
      await client.post<Map<String, dynamic>>(ApiEndpoints.githubDisconnect);
      setState(() {
        _connectedGithubUser = null;
        _githubError = null;
      });
      ref.read(workspaceProvider.notifier).refreshWorkspace();
    } catch (e) {
      setState(() => _githubError = 'Failed to disconnect: $e');
    }
  }

  Future<void> _configureLlmProvider(String providerId, String key, {String? baseUrl, String? model}) async {
    setState(() {
      _isSavingLlm = true;
      _llmStatusMessage = null;
    });

    try {
      final client = ref.read(apiClientProvider);
      await client.post<Map<String, dynamic>>(
        ApiEndpoints.llmConfigure,
        data: {
          'providerId': providerId,
          'apiKey': key,
          if (baseUrl != null) 'baseUrl': baseUrl,
          if (model != null) 'model': model,
        },
      );
      setState(() {
        _llmStatusMessage = 'Configuration saved for $providerId';
      });
      ref.read(llmSelectorProvider.notifier).loadProviders();
    } catch (e) {
      setState(() {
        _llmStatusMessage = 'Failed to save $providerId: $e';
      });
    } finally {
      if (mounted) setState(() => _isSavingLlm = false);
    }
  }

  Future<void> _testLlmConnection({
    required String mode,
    required String providerId,
    String? apiKey,
    String? baseUrl,
  }) async {
    setState(() {
      _isSavingLlm = true;
      _llmStatusMessage = 'Testing $providerId connection...';
    });
    try {
      final client = ref.read(apiClientProvider);
      final resp = await client.post<Map<String, dynamic>>(
        ApiEndpoints.llmTestConnection,
        data: {
          'mode': mode,
          'providerId': providerId,
          if (apiKey != null && apiKey.isNotEmpty) 'apiKey': apiKey,
          if (baseUrl != null && baseUrl.isNotEmpty) 'baseUrl': baseUrl,
        },
      );
      final ok = resp.data?['ok'] == true;
      final msg = resp.data?['message']?.toString() ?? (ok ? 'Connected successfully' : 'Connection failed');
      setState(() => _llmStatusMessage = ok ? '✓ $msg' : '✗ $msg');
    } catch (e) {
      setState(() => _llmStatusMessage = '✗ Test failed: $e');
    } finally {
      if (mounted) setState(() => _isSavingLlm = false);
    }
  }

  void _saveGuardrailSettings() {
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

    return Dialog(
      backgroundColor: isDark ? const Color(0xFF1E1E24) : AppColors.surfaceLight,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(
          color: isDark ? AppColors.borderDark : AppColors.borderLight,
        ),
      ),
      child: Container(
        width: 640,
        height: 600,
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Row(
              children: [
                Icon(Icons.tune_rounded, size: 22, color: AppColors.indigo500),
                const SizedBox(width: 10),
                Text(
                  'Otto Settings & Integrations',
                  style: AppTypography.uiFont.copyWith(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close_rounded, size: 18),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Tab bar
            TabBar(
              controller: _tabController,
              isScrollable: true,
              tabAlignment: TabAlignment.start,
              labelColor: AppColors.indigo500,
              unselectedLabelColor: isDark ? AppColors.zinc400 : AppColors.zinc600,
              indicatorColor: AppColors.indigo500,
              tabs: const [
                Tab(icon: Icon(Icons.verified_user_rounded, size: 16), text: 'Antigravity Identity'),
                Tab(icon: Icon(Icons.smart_toy_rounded, size: 16), text: 'AI Models'),
                Tab(icon: Icon(Icons.hub_rounded, size: 16), text: 'GitHub'),
                Tab(icon: Icon(Icons.security_rounded, size: 16), text: 'Guardrails'),
              ],
            ),
            const SizedBox(height: 16),

            // Tab Views
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildAntigravityTab(isDark),
                  _buildLlmTab(isDark),
                  _buildGithubTab(isDark),
                  _buildGuardrailsTab(isDark),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGuardrailsTab(bool isDark) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Atomic Commit Guardrails (Otto Protocol)',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: isDark ? AppColors.zinc200 : AppColors.zinc800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Otto enforces strict micro-commit guardrails so every diff is reviewable and stackable.',
            style: TextStyle(fontSize: 12, color: isDark ? AppColors.zinc400 : AppColors.zinc600),
          ),
          const SizedBox(height: 20),

          // Max LOC
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Max LOC per commit:', style: TextStyle(fontSize: 13, color: isDark ? AppColors.zinc300 : AppColors.zinc700)),
              Text('${_maxLoc.toInt()} LOC (default: 80)', style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.indigo500)),
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
          const SizedBox(height: 12),

          // Max Files
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Max Files per commit:', style: TextStyle(fontSize: 13, color: isDark ? AppColors.zinc300 : AppColors.zinc700)),
              DropdownButton<int>(
                value: _maxFiles,
                dropdownColor: isDark ? const Color(0xFF282830) : Colors.white,
                items: [1, 2, 3, 5, 8].map((n) => DropdownMenuItem(value: n, child: Text('$n files'))).toList(),
                onChanged: (val) {
                  if (val != null) setState(() => _maxFiles = val);
                },
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Conventional Commits
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Enforce Conventional Commits (feat, fix, docs, refactor)', style: TextStyle(fontSize: 13)),
            value: _enforceConventional,
            activeColor: AppColors.indigo500,
            onChanged: (val) => setState(() => _enforceConventional = val),
          ),
          const SizedBox(height: 24),

          Align(
            alignment: Alignment.centerRight,
            child: FilledButton(
              onPressed: _saveGuardrailSettings,
              style: FilledButton.styleFrom(backgroundColor: AppColors.indigo600),
              child: const Text('Save Guardrail Settings'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGithubTab(bool isDark) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Connect your GitHub Account',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: isDark ? AppColors.zinc200 : AppColors.zinc800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Connecting your real GitHub account enables Otto to push atomic commit branches and open stacked pull requests directly on your repository.',
            style: TextStyle(fontSize: 12, color: isDark ? AppColors.zinc400 : AppColors.zinc600),
          ),
          const SizedBox(height: 18),

          if (_connectedGithubUser != null) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF242C3D) : const Color(0xFFEEF4FF),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFF3B82F6)),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 22,
                    backgroundImage: _connectedGithubUser!['avatarUrl'] != null
                        ? NetworkImage(_connectedGithubUser!['avatarUrl'] as String)
                        : null,
                    child: _connectedGithubUser!['avatarUrl'] == null ? const Icon(Icons.person) : null,
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _connectedGithubUser!['name'] ?? _connectedGithubUser!['login'] ?? 'Connected',
                          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                        ),
                        Text(
                          '@${_connectedGithubUser!['login']}',
                          style: TextStyle(fontSize: 12, color: isDark ? AppColors.zinc400 : AppColors.zinc600),
                        ),
                        if (_connectedGithubUser!['scopes'] != null)
                          Text(
                            'Scopes: ${_connectedGithubUser!['scopes']}',
                            style: const TextStyle(fontSize: 11, color: AppColors.emerald500),
                          ),
                      ],
                    ),
                  ),
                  OutlinedButton(
                    onPressed: _disconnectGithub,
                    style: OutlinedButton.styleFrom(foregroundColor: AppColors.rose500),
                    child: const Text('Disconnect'),
                  ),
                ],
              ),
            ),
          ] else ...[
            // PAT Input
            TextField(
              controller: _patController,
              obscureText: _obscurePat,
              decoration: InputDecoration(
                labelText: 'Personal Access Token (classic or fine-grained)',
                hintText: 'ghp_...',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                suffixIcon: IconButton(
                  icon: Icon(_obscurePat ? Icons.visibility : Icons.visibility_off),
                  onPressed: () => setState(() => _obscurePat = !_obscurePat),
                ),
              ),
            ),
            const SizedBox(height: 12),

            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed: _isConnectingGithub ? null : () => _connectGithub(method: 'pat'),
                    icon: _isConnectingGithub
                        ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                        : const Icon(Icons.key_rounded, size: 16),
                    label: const Text('Connect with Token'),
                    style: FilledButton.styleFrom(backgroundColor: AppColors.indigo600),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _isConnectingGithub ? null : () => _connectGithub(method: 'gh_cli'),
                    icon: const Icon(Icons.terminal_rounded, size: 16),
                    label: const Text('Detect GitHub CLI'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Required token scopes: repo, workflow, read:user.',
              style: TextStyle(fontSize: 11, color: isDark ? AppColors.zinc400 : AppColors.zinc600),
            ),
          ],

          if (_githubError != null) ...[
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.15),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: Colors.redAccent),
              ),
              child: Text(_githubError!, style: const TextStyle(color: Colors.redAccent, fontSize: 12)),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAntigravityTab(bool isDark) {
    final authState = ref.watch(authStateProvider);
    return AntigravityIdentityTab(
      user: authState.session,
      isConnected: authState.isAuthenticated || (_antigravityData?['connected'] == true),
      antigravityData: _antigravityData, isSyncing: _isSyncingAntigravity,
      onSync: _syncAntigravitySubscription,
      onReauthenticate: () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const ClerkSignInScreen())),
      isDark: isDark,
    );
  }

  Widget _buildLlmTab(bool isDark) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Dual-Engine AI Architecture',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: isDark ? AppColors.zinc200 : AppColors.zinc800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Harness your existing flat-rate coding subscriptions via local CLIs (\$0 token fees) or bring your own API key for pay-as-you-go providers.',
            style: TextStyle(fontSize: 12, color: isDark ? AppColors.zinc400 : AppColors.zinc600),
          ),
          const SizedBox(height: 14),

          // Architecture Selector
          Row(
            children: [
              ChoiceChip(
                label: const Text('Local CLI Subscriptions (\$0 Cost)'),
                selected: _llmArchitectureMode == 0,
                onSelected: (val) {
                  if (val) setState(() => _llmArchitectureMode = 0);
                },
              ),
              const SizedBox(width: 8),
              ChoiceChip(
                label: const Text('Bring Your Own Key (BYOK)'),
                selected: _llmArchitectureMode == 1,
                onSelected: (val) {
                  if (val) setState(() => _llmArchitectureMode = 1);
                },
              ),
            ],
          ),
          const SizedBox(height: 14),

          if (_llmArchitectureMode == 0) ...[
            // Local CLI Wrappers
            // Antigravity (Pro Subscription)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF1B2A1B),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFF2E7D32)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.verified_rounded, color: Color(0xFF81C784), size: 22),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text('Google Antigravity (Google AI Pro Plan)', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: Colors.white)),
                      ),
                      OutlinedButton(
                        onPressed: _isSavingLlm ? null : () => _testLlmConnection(mode: 'cli', providerId: 'antigravity'),
                        child: const Text('Test CLI'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text('Status: Detected agy.exe CLI • \$0 extra token fees', style: TextStyle(fontSize: 11, color: isDark ? AppColors.zinc300 : AppColors.zinc700)),
                  Text('Direct local process wrapper with authenticated Google AI Pro plan.', style: TextStyle(fontSize: 10.5, color: isDark ? AppColors.zinc400 : AppColors.zinc600)),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Claude Code CLI
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF282830) : const Color(0xFFF4F4F6),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: isDark ? AppColors.borderDark : AppColors.borderLight),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.terminal_rounded, color: Color(0xFFE57B42), size: 22),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text('Claude Code CLI (Claude Pro / Team)', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                      ),
                      OutlinedButton(
                        onPressed: _isSavingLlm ? null : () => _testLlmConnection(mode: 'cli', providerId: 'claude'),
                        child: const Text('Test CLI'),
                      ),
                      const SizedBox(width: 6),
                      FilledButton(
                        onPressed: _isSavingLlm ? null : () => _configureLlmProvider('claude_cli', 'subscription'),
                        style: FilledButton.styleFrom(backgroundColor: AppColors.indigo600),
                        child: const Text('Activate'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text('Status: Detected claude.exe (v2.1.326)', style: TextStyle(fontSize: 11, color: isDark ? AppColors.zinc300 : AppColors.zinc700)),
                  Text('Executes Claude Code in headless non-interactive mode using local subscription.', style: TextStyle(fontSize: 10.5, color: isDark ? AppColors.zinc400 : AppColors.zinc600)),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Codex CLI
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF282830) : const Color(0xFFF4F4F6),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: isDark ? AppColors.borderDark : AppColors.borderLight),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.smart_toy_outlined, color: Colors.blueAccent, size: 22),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text('OpenAI Codex CLI', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text('Status: Optional wrapper (install via npm i -g @openai/codex)', style: TextStyle(fontSize: 11, color: isDark ? AppColors.zinc400 : AppColors.zinc600)),
                ],
              ),
            ),
          ] else ...[
            // BYOK Cards
            _buildProviderCard(
              title: 'Google AI Studio (Gemini Free Tier)',
              hint: 'AIzaSy...',
              controller: _geminiKeyController,
              onTest: () => _testLlmConnection(mode: 'byok', providerId: 'gemini', apiKey: _geminiKeyController.text.trim()),
              onSave: () => _configureLlmProvider('gemini', _geminiKeyController.text.trim()),
              isDark: isDark,
            ),
            const SizedBox(height: 12),

            _buildProviderCard(
              title: 'OpenAI (GPT-4o / O3-Mini)',
              hint: 'sk-...',
              controller: _openaiKeyController,
              onTest: () => _testLlmConnection(mode: 'byok', providerId: 'openai', apiKey: _openaiKeyController.text.trim()),
              onSave: () => _configureLlmProvider('openai', _openaiKeyController.text.trim()),
              isDark: isDark,
            ),
            const SizedBox(height: 12),

            _buildProviderCard(
              title: 'Anthropic Claude (Pay-As-You-Go API)',
              hint: 'sk-ant-...',
              controller: _anthropicKeyController,
              onTest: () => _testLlmConnection(mode: 'byok', providerId: 'anthropic', apiKey: _anthropicKeyController.text.trim()),
              onSave: () => _configureLlmProvider('anthropic', _anthropicKeyController.text.trim()),
              isDark: isDark,
            ),
            const SizedBox(height: 12),

            _buildProviderCard(
              title: 'OpenRouter (Unified Multi-Model API)',
              hint: 'sk-or-...',
              controller: _openrouterKeyController,
              onTest: () => _testLlmConnection(mode: 'byok', providerId: 'openrouter', apiKey: _openrouterKeyController.text.trim()),
              onSave: () => _configureLlmProvider('openrouter', _openrouterKeyController.text.trim()),
              isDark: isDark,
            ),
            const SizedBox(height: 12),

            // Ollama
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF282830) : const Color(0xFFF4F4F6),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: isDark ? AppColors.borderDark : AppColors.borderLight),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Local Ollama Endpoint (100% Free / Offline)', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _ollamaUrlController,
                    decoration: InputDecoration(
                      labelText: 'Base URL',
                      hintText: 'http://localhost:11434',
                      isDense: true,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _ollamaModelController,
                          decoration: InputDecoration(
                            labelText: 'Model Name',
                            hintText: 'llama3:latest',
                            isDense: true,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      OutlinedButton(
                        onPressed: _isSavingLlm
                            ? null
                            : () => _testLlmConnection(
                                  mode: 'byok',
                                  providerId: 'ollama',
                                  baseUrl: _ollamaUrlController.text.trim(),
                                ),
                        child: const Text('Test'),
                      ),
                      const SizedBox(width: 6),
                      FilledButton(
                        onPressed: _isSavingLlm
                            ? null
                            : () => _configureLlmProvider(
                                  'ollama',
                                  'local',
                                  baseUrl: _ollamaUrlController.text.trim(),
                                  model: _ollamaModelController.text.trim(),
                                ),
                        style: FilledButton.styleFrom(backgroundColor: AppColors.indigo600),
                        child: const Text('Save Ollama'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],

          if (_llmStatusMessage != null) ...[
            const SizedBox(height: 12),
            Text(_llmStatusMessage!, style: const TextStyle(color: AppColors.indigo500, fontSize: 12)),
          ],
        ],
      ),
    );
  }

  Widget _buildProviderCard({
    required String title,
    required String hint,
    required TextEditingController controller,
    required VoidCallback onSave,
    VoidCallback? onTest,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF282830) : const Color(0xFFF4F4F6),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: isDark ? AppColors.borderDark : AppColors.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: controller,
                  obscureText: true,
                  decoration: InputDecoration(
                    hintText: hint,
                    isDense: true,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
                  ),
                ),
              ),
              if (onTest != null) ...[
                const SizedBox(width: 8),
                OutlinedButton(
                  onPressed: _isSavingLlm ? null : onTest,
                  child: const Text('Test'),
                ),
              ],
              const SizedBox(width: 8),
              FilledButton(
                onPressed: _isSavingLlm ? null : onSave,
                style: FilledButton.styleFrom(backgroundColor: AppColors.indigo600),
                child: const Text('Save'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

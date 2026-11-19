/// API and SSE endpoints connecting the Otto Flutter multiplatform client
/// to the Otto local daemon and Express server.
class ApiEndpoints {
  const ApiEndpoints._();

  static const String baseUrl = 'http://localhost:3000';
  static const String sseStreamUrl = 'http://localhost:3000/api/events';

  // Standardized Core Endpoints
  static const String state = '/api/state';
  static const String analyzeDiff = '/api/git/analyze';
  static const String pushStack = '/api/git/push-stack';
  static const String splitCommit = '/api/git/split';
  static const String rebase = '/api/git/rebase';
  static const String refineStack = '/api/ai/refine-stack';
  static const String events = '/api/events';
  static const String providers = '/api/llm/providers';
  static const String syncStatus = '/api/github/sync-status';
  static const String syncNow = '/api/github/sync-now';

  // Auth & Session (wired to actual backend routes)
  static const String antigravityConnect = '/api/antigravity/connect';
  static const String antigravityStatus = '/api/antigravity/status';
  static const String antigravitySignout = '/api/antigravity/signout';

  // Legacy aliases kept for reference — not used by ClerkAuthDataSource
  static const String clerkVerify = '/auth/clerk-verify';
  static const String clerkSession = '/auth/session';
  static const String clerkSignOut = '/auth/signout';

  // Real Integrations
  static const String githubConnect = '/api/github/connect';
  static const String githubDisconnect = '/api/github/disconnect';
  static const String githubUser = '/api/github/user';
  static const String workspaceOpen = '/api/workspace/open';
  static const String workspaceRecent = '/api/workspace/recent';
  static const String agentsConnect = '/api/agents/connect';
  static const String agentsDisconnect = '/api/agents/disconnect';
  static const String llmConfigure = '/api/llm/configure';
  static const String llmCommitMessage = '/llm/commit-message';

  // Compatibility aliases
  static const String workspaceState = state;
  static const String rawDiff = analyzeDiff;
  static const String sliceDiff = analyzeDiff;
  static const String createCommit = '/api/git/commit';
  static const String rebaseStack = rebase;
  static const String llmRefineStack = refineStack;
  static const String llmProviders = providers;
  static const String llmStreamGenerate = '/api/llm/generate-stream';
}

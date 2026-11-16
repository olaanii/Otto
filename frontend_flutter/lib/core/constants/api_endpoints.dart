/// API and SSE endpoints connecting the Otto Flutter multiplatform client
/// to the Otto local Go daemon.
class ApiEndpoints {
  const ApiEndpoints._();

  static const String baseUrl = 'http://localhost:3000/api';
  static const String sseStreamUrl = 'http://localhost:3000/api/git/events';

  // Auth & Session
  static const String clerkVerify = '/auth/clerk-verify';
  static const String clerkSession = '/auth/session';
  static const String clerkSignOut = '/auth/signout';

  // Git Workspace & Stacking
  static const String workspaceState = '/git/workspace';
  static const String rawDiff = '/git/diff';
  static const String sliceDiff = '/git/slice';
  static const String createCommit = '/git/commit';
  static const String splitCommit = '/git/split';
  static const String rebaseStack = '/git/rebase';
  static const String pushStack = '/git/push-stack';

  // LLM Providers & Agent Integration
  static const String llmRefineStack = '/llm/refine';
  static const String llmProviders = '/llm/providers';
  static const String llmStreamGenerate = '/llm/generate-stream';
}

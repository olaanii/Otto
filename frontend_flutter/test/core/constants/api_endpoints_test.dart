import 'package:flutter_test/flutter_test.dart';
import 'package:otto_frontend/core/constants/api_endpoints.dart';

void main() {
  group('ApiEndpoints harmonization', () {
    test('standardized endpoints match Go daemon, Express server, and IDE extension contracts', () {
      expect(ApiEndpoints.state, '/api/state');
      expect(ApiEndpoints.analyzeDiff, '/api/git/analyze');
      expect(ApiEndpoints.pushStack, '/api/git/push-stack');
      expect(ApiEndpoints.splitCommit, '/api/git/split');
      expect(ApiEndpoints.rebase, '/api/git/rebase');
      expect(ApiEndpoints.refineStack, '/api/ai/refine-stack');
      expect(ApiEndpoints.events, '/api/events');
      expect(ApiEndpoints.providers, '/api/llm/providers');
      expect(ApiEndpoints.syncStatus, '/api/github/sync-status');
      expect(ApiEndpoints.syncNow, '/api/github/sync-now');
    });

    test('compatibility aliases are preserved', () {
      expect(ApiEndpoints.workspaceState, ApiEndpoints.state);
      expect(ApiEndpoints.rebaseStack, ApiEndpoints.rebase);
      expect(ApiEndpoints.llmRefineStack, ApiEndpoints.refineStack);
      expect(ApiEndpoints.llmProviders, ApiEndpoints.providers);
      expect(ApiEndpoints.sseStreamUrl, 'http://localhost:3000/api/events');
    });
  });
}

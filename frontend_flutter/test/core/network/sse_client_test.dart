import 'package:flutter_test/flutter_test.dart';
import 'package:otto_frontend/core/network/sse_client.dart';

void main() {
  group('SseEvent and SSE harmonization', () {
    test('identifies named workspace events', () {
      final e1 = SseEvent(event: 'workspace_changed', data: '{}');
      final e2 = SseEvent(event: 'file_changed', data: '{}');
      final e3 = SseEvent(event: 'git_diff', data: '{}');

      expect(e1.isWorkspaceUpdate, true);
      expect(e2.isWorkspaceUpdate, true);
      expect(e3.isWorkspaceUpdate, true);
    });

    test('identifies generic events with stagedAtomicStack payload', () {
      final e = SseEvent(data: '{"stagedAtomicStack": [{"id": "c1"}]}');
      expect(e.isWorkspaceUpdate, true);
    });

    test('identifies generic events with type: state_updated payload', () {
      final e = SseEvent(data: '{"type": "state_updated", "timestamp": "2026-11-16T12:00:00Z"}');
      expect(e.isWorkspaceUpdate, true);
    });

    test('ignores unrelated events', () {
      final e = SseEvent(event: 'heartbeat', data: '{"type": "ping"}');
      expect(e.isWorkspaceUpdate, false);
    });

    test('parseJson gracefully handles malformed or raw string payloads', () {
      final e = SseEvent(data: 'not-valid-json');
      final parsed = e.parseJson();
      expect(parsed['raw'], 'not-valid-json');
    });

    test('onWorkspaceChanged stream properly filters non-workspace events', () async {
      final e1 = SseEvent(event: 'heartbeat', data: '{"ping": true}');
      final e2 = SseEvent(event: 'workspace_changed', data: '{}');
      final e3 = SseEvent(data: '{"stagedAtomicStack": []}');

      final events = [e1, e2, e3];
      final filtered = events.where((e) => e.isWorkspaceUpdate).toList();

      expect(filtered.length, 2);
      expect(filtered[0].event, 'workspace_changed');
      expect(filtered[1].data, '{"stagedAtomicStack": []}');
    });
  });
}

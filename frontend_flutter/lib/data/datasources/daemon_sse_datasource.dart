import '../../core/network/sse_client.dart';

abstract class IDaemonSseDataSource {
  Stream<SseEvent> get eventStream;
  void disconnect();
}

class DaemonSseDataSource implements IDaemonSseDataSource {
  final SseClient sseClient;

  DaemonSseDataSource(this.sseClient);

  @override
  Stream<SseEvent> get eventStream => sseClient.subscribe();

  @override
  void disconnect() {
    sseClient.dispose();
  }
}

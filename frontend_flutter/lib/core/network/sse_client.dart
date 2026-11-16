import 'dart:async';
import 'dart:convert';
import 'package:dio/dio.dart';
import '../storage/secure_storage_service.dart';

/// Represents a single event received from the SSE event stream.
class SseEvent {
  final String? event;
  final String data;
  final String? id;

  const SseEvent({
    this.event,
    required this.data,
    this.id,
  });

  Map<String, dynamic> parseJson() {
    try {
      final decoded = jsonDecode(data);
      if (decoded is Map<String, dynamic>) {
        return decoded;
      }
      return {'raw': data};
    } catch (_) {
      return {'raw': data};
    }
  }

  /// Returns true if this event indicates workspace or file changes that require refreshing state.
  /// Handles named events ('workspace_changed', 'file_changed', 'git_diff')
  /// as well as generic messages with JSON payloads containing 'stagedAtomicStack' or 'type: state_updated'.
  bool get isWorkspaceUpdate {
    if (event == 'workspace_changed' || event == 'file_changed' || event == 'git_diff') {
      return true;
    }
    final json = parseJson();
    if (json.containsKey('stagedAtomicStack') ||
        json['type'] == 'state_updated' ||
        json['event'] == 'workspace_changed' ||
        json['event'] == 'file_changed') {
      return true;
    }
    return false;
  }

  @override
  String toString() => 'SseEvent(event: $event, id: $id, data: $data)';
}

/// SSE client subscribing to real-time events emitted by the Otto daemon or server.
class SseClient {
  final String url;
  final SecureStorageService secureStorage;
  final Dio _dio;

  StreamController<SseEvent>? _controller;
  CancelToken? _cancelToken;
  bool _isConnected = false;
  bool _isDisposed = false;

  SseClient({
    required this.url,
    required this.secureStorage,
    Dio? dio,
  }) : _dio = dio ?? Dio();

  bool get isConnected => _isConnected;

  /// Filtered stream that emits whenever a workspace or file change event arrives.
  Stream<SseEvent> get onWorkspaceChanged =>
      subscribe().where((e) => e.isWorkspaceUpdate);

  /// Returns a broadcast stream of server-sent events.
  Stream<SseEvent> subscribe() {
    if (_controller == null || _controller!.isClosed) {
      _controller = StreamController<SseEvent>.broadcast(
        onListen: _startListening,
        onCancel: _stopListening,
      );
    }
    return _controller!.stream;
  }

  Future<void> _startListening() async {
    if (_isConnected || _isDisposed) return;
    _cancelToken = CancelToken();

    try {
      final jwt = await secureStorage.read(SecureStorageService.keyClerkJwt);
      final headers = <String, String>{
        'Accept': 'text/event-stream',
        'Cache-Control': 'no-cache',
      };
      if (jwt != null && jwt.isNotEmpty) {
        headers['Authorization'] = 'Bearer $jwt';
      }

      final response = await _dio.get<ResponseBody>(
        url,
        options: Options(
          responseType: ResponseType.stream,
          headers: headers,
        ),
        cancelToken: _cancelToken,
      );

      _isConnected = true;

      String buffer = '';
      String? currentEvent;
      String? currentId;
      final currentDataLines = <String>[];

      final stream = response.data!.stream;
      await for (final chunk in stream) {
        final decoded = utf8.decode(chunk);
        buffer += decoded;

        final lines = buffer.split('\n');
        // Keep unfinished trailing line in buffer
        buffer = lines.removeLast();

        for (final rawLine in lines) {
          final line = rawLine.trimRight();
          if (line.isEmpty) {
            // Dispatch event on empty line delimiter
            if (currentDataLines.isNotEmpty && !_controller!.isClosed) {
              final payload = currentDataLines.join('\n');
              _controller!.add(
                SseEvent(
                  event: currentEvent,
                  id: currentId,
                  data: payload,
                ),
              );
              currentEvent = null;
              currentId = null;
              currentDataLines.clear();
            }
          } else if (line.startsWith('event:')) {
            currentEvent = line.substring(6).trim();
          } else if (line.startsWith('data:')) {
            currentDataLines.add(line.substring(5).trim());
          } else if (line.startsWith('id:')) {
            currentId = line.substring(3).trim();
          }
        }
      }
    } catch (e) {
      _isConnected = false;
      final isCancelled = _cancelToken?.isCancelled ?? false;
      if (!isCancelled &&
          !_isDisposed &&
          _controller != null &&
          !_controller!.isClosed &&
          _controller!.hasListener) {
        // Auto-reconnect after 3 seconds on disconnection if active subscribers remain
        Future.delayed(const Duration(seconds: 3), () {
          if (!_isDisposed &&
              _controller != null &&
              !_controller!.isClosed &&
              _controller!.hasListener) {
            _startListening();
          }
        });
      }
    } finally {
      _isConnected = false;
    }
  }

  void _stopListening() {
    _cancelToken?.cancel('Client unsubscribed');
    _isConnected = false;
  }

  void dispose() {
    _isDisposed = true;
    _stopListening();
    _controller?.close();
  }
}

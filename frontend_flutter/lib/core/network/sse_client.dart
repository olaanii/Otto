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
      return jsonDecode(data) as Map<String, dynamic>;
    } catch (_) {
      return {'raw': data};
    }
  }

  @override
  String toString() => 'SseEvent(event: $event, id: $id, data: $data)';
}

/// SSE client subscribing to real-time events emitted by the Otto Go daemon.
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
      if (!_isDisposed && !_controller!.isClosed) {
        // Auto-reconnect after 3 seconds on disconnection
        Future.delayed(const Duration(seconds: 3), () {
          if (!_isDisposed) _startListening();
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

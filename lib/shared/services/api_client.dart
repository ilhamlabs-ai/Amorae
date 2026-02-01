import 'dart:async';
import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:uuid/uuid.dart';
import '../models/message_model.dart';

/// API client for backend communication with SSE support
class ApiClient {
  final Dio _dio;
  final FirebaseAuth _auth;
  final String baseUrl;
  final Uuid _uuid = const Uuid();

  ApiClient({
    required this.baseUrl,
    Dio? dio,
    FirebaseAuth? auth,
  })  : _dio = dio ?? Dio(),
        _auth = auth ?? FirebaseAuth.instance {
    _dio.options.baseUrl = baseUrl;
    _dio.options.connectTimeout = const Duration(seconds: 30);
    _dio.options.receiveTimeout = const Duration(minutes: 5);
  }

  /// Get Firebase ID token
  Future<String?> _getIdToken() async {
    final user = _auth.currentUser;
    if (user == null) return null;
    return user.getIdToken();
  }

  /// Generate request ID for idempotency
  String generateRequestId() => _uuid.v4();

  /// Send message (non-streaming, simpler approach)
  Future<Map<String, dynamic>> sendMessage({
    required String threadId,
    required String content,
    List<Map<String, dynamic>>? attachments,
  }) async {
    final token = await _getIdToken();
    if (token == null) {
      throw Exception('Not authenticated');
    }

    final requestId = generateRequestId();

    final response = await _dio.post(
      '/v1/chat/send',
      data: {
        'threadId': threadId,
        'content': content,
        if (attachments != null) 'attachments': attachments,
      },
      options: Options(
        headers: {
          'Authorization': 'Bearer $token',
          'X-Request-Id': requestId,
        },
      ),
    );

    return response.data as Map<String, dynamic>;
  }

  /// Send message with SSE streaming
  Stream<SSEEvent> sendMessageStream({
    required String threadId,
    required String content,
    List<Map<String, dynamic>>? attachments,
  }) async* {
    final token = await _getIdToken();
    if (token == null) {
      yield SSEEvent.error('Not authenticated');
      return;
    }

    final requestId = generateRequestId();

    try {
      final response = await _dio.post(
        '/v1/chat/send_stream',
        data: {
          'threadId': threadId,
          'content': content,
          if (attachments != null) 'attachments': attachments,
        },
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
            'X-Request-Id': requestId,
            'Accept': 'text/event-stream',
          },
          responseType: ResponseType.stream,
        ),
      );

      final stream = response.data.stream as Stream<List<int>>;
      String buffer = '';

      print('🌊 Starting SSE stream...');
      
      await for (final chunk in stream) {
        final decoded = utf8.decode(chunk);
        print('📦 Received chunk: ${decoded.length} chars');
        buffer += decoded;

        // Parse SSE events
        // Print full buffer with escaped newlines for debugging
        final escapedBuffer = buffer.replaceAll('\n', '\\n').replaceAll('\r', '\\r');
        print('📋 Buffer content (first 200 chars): ${escapedBuffer.substring(0, escapedBuffer.length > 200 ? 200 : escapedBuffer.length)}');
        if (escapedBuffer.length > 200) {
          print('📋 Buffer content (last 100 chars): ${escapedBuffer.substring(escapedBuffer.length - 100)}');
        }
        print('📏 Buffer length: ${buffer.length}');
        print('🔍 Contains \\n\\n: ${buffer.contains('\n\n')}');
        print('🔍 First \\n\\n at index: ${buffer.contains('\n\n') ? buffer.indexOf('\n\n') : -1}');
        
        while (buffer.contains('\n\n')) {
          final eventEnd = buffer.indexOf('\n\n');
          final eventStr = buffer.substring(0, eventEnd);
          buffer = buffer.substring(eventEnd + 2);

          print('🎯 Parsing event: ${eventStr.substring(0, eventStr.length > 100 ? 100 : eventStr.length)}...');
          
          final event = _parseSSEEvent(eventStr);
          if (event != null) {
            print('✅ Event parsed: ${event.type}');
            yield event;

            // Stop on error or final
            if (event.type == SSEEventType.error ||
                event.type == SSEEventType.final_) {
              print('🛑 Stream ended: ${event.type}');
              return;
            }
          } else {
            print('⚠️ Failed to parse event');
          }
        }
      }
      print('🏁 Stream complete');
    } on DioException catch (e) {
      print('❌ Dio error: ${e.message}');
      yield SSEEvent.error(e.message ?? 'Network error');
    } catch (e) {
      print('❌ Error: $e');
      yield SSEEvent.error(e.toString());
    }
  }

  /// Parse SSE event from string
  SSEEvent? _parseSSEEvent(String eventStr) {
    String? eventType;
    String? data;

    for (final line in eventStr.split('\n')) {
      if (line.startsWith('event: ')) {
        eventType = line.substring(7);
      } else if (line.startsWith('data: ')) {
        data = line.substring(6);
      }
    }

    if (data == null) return null;

    try {
      final json = jsonDecode(data);

      switch (eventType) {
        case 'meta':
          return SSEEvent.meta(
            threadId: json['threadId'],
            assistantMessageId: json['assistantMessageId'],
            generationId: json['generationId'],
            requestId: json['requestId'],
          );
        case 'stage':
          return SSEEvent.stage(
            name: json['name'],
            status: json['status'],
          );
        case 'delta':
          return SSEEvent.delta(
            cursor: json['cursor'],
            text: json['text'],
          );
        case 'heartbeat':
          return SSEEvent.heartbeat(json['ts']);
        case 'final':
          return SSEEvent.final_(
            cursor: json['cursor'],
            finishReason: json['finishReason'],
          );
        case 'error':
          return SSEEvent.error(
            json['message'],
            code: json['code'],
          );
        default:
          return null;
      }
    } catch (e) {
      return null;
    }
  }

  /// Trigger memory curation
  Future<void> curateMemory({
    required String threadId,
    required int fromSeq,
    required int toSeq,
  }) async {
    final token = await _getIdToken();
    if (token == null) throw Exception('Not authenticated');

    await _dio.post(
      '/v1/memory/curate',
      data: {
        'threadId': threadId,
        'fromSeq': fromSeq,
        'toSeq': toSeq,
      },
      options: Options(
        headers: {
          'Authorization': 'Bearer $token',
        },
      ),
    );
  }

  /// Delete user data (GDPR)
  Future<void> deleteUserData() async {
    final token = await _getIdToken();
    if (token == null) throw Exception('Not authenticated');

    await _dio.post(
      '/v1/privacy/delete_user',
      options: Options(
        headers: {
          'Authorization': 'Bearer $token',
        },
      ),
    );
  }

  /// Health check
  Future<bool> healthCheck() async {
    try {
      final response = await _dio.get('/health');
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
}

/// SSE Event types
enum SSEEventType {
  meta,
  stage,
  delta,
  heartbeat,
  final_,
  error,
}

/// SSE Event
class SSEEvent {
  final SSEEventType type;
  final Map<String, dynamic> data;

  SSEEvent._({required this.type, required this.data});

  factory SSEEvent.meta({
    required String threadId,
    required String assistantMessageId,
    required String generationId,
    required String requestId,
  }) {
    return SSEEvent._(
      type: SSEEventType.meta,
      data: {
        'threadId': threadId,
        'assistantMessageId': assistantMessageId,
        'generationId': generationId,
        'requestId': requestId,
      },
    );
  }

  factory SSEEvent.stage({
    required String name,
    required String status,
  }) {
    return SSEEvent._(
      type: SSEEventType.stage,
      data: {'name': name, 'status': status},
    );
  }

  factory SSEEvent.delta({
    required int cursor,
    required String text,
  }) {
    return SSEEvent._(
      type: SSEEventType.delta,
      data: {'cursor': cursor, 'text': text},
    );
  }

  factory SSEEvent.heartbeat(int timestamp) {
    return SSEEvent._(
      type: SSEEventType.heartbeat,
      data: {'ts': timestamp},
    );
  }

  factory SSEEvent.final_({
    required int cursor,
    required String finishReason,
  }) {
    return SSEEvent._(
      type: SSEEventType.final_,
      data: {'cursor': cursor, 'finishReason': finishReason},
    );
  }

  factory SSEEvent.error(String message, {String? code}) {
    return SSEEvent._(
      type: SSEEventType.error,
      data: {'message': message, if (code != null) 'code': code},
    );
  }

  // Getters for convenience
  String? get threadId => data['threadId'];
  String? get assistantMessageId => data['assistantMessageId'];
  String? get generationId => data['generationId'];
  String? get requestId => data['requestId'];
  String? get stageName => data['name'];
  String? get stageStatus => data['status'];
  int? get cursor => data['cursor'];
  String? get text => data['text'];
  String? get finishReason => data['finishReason'];
  String? get errorMessage => data['message'];
  String? get errorCode => data['code'];

  bool get isMeta => type == SSEEventType.meta;
  bool get isDelta => type == SSEEventType.delta;
  bool get isFinal => type == SSEEventType.final_;
  bool get isError => type == SSEEventType.error;
}

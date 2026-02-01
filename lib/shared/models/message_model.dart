import 'package:cloud_firestore/cloud_firestore.dart';

/// Message model matching Firestore schema (append-only)
class MessageModel {
  final String id;
  final String threadId;
  final int seq;
  final String role; // user | assistant | tool
  final String type; // text | image | mixed
  final String content;
  final List<MessageAttachment> attachments;
  final int createdAt;
  final int tokenEstimate;
  final String? contentHash;
  final ModerationInfo moderation;
  final AIMeta? aiMeta;
  final StreamState? stream;

  MessageModel({
    required this.id,
    required this.threadId,
    required this.seq,
    required this.role,
    this.type = 'text',
    required this.content,
    this.attachments = const [],
    required this.createdAt,
    this.tokenEstimate = 0,
    this.contentHash,
    required this.moderation,
    this.aiMeta,
    this.stream,
  });

  factory MessageModel.fromFirestore(DocumentSnapshot doc, String threadId) {
    final data = doc.data() as Map<String, dynamic>;
    
    // Handle Firestore Timestamp conversion
    int getTimestamp(dynamic value) {
      if (value == null) return DateTime.now().millisecondsSinceEpoch;
      if (value is Timestamp) return value.millisecondsSinceEpoch;
      if (value is int) return value;
      return DateTime.now().millisecondsSinceEpoch;
    }
    
    return MessageModel(
      id: doc.id,
      threadId: threadId,
      seq: data['seq'] ?? 0,
      role: data['role'] ?? 'user',
      type: data['type'] ?? 'text',
      content: data['content'] ?? '',
      attachments: (data['attachments'] as List<dynamic>?)
              ?.map((a) => MessageAttachment.fromMap(a))
              .toList() ??
          [],
      createdAt: getTimestamp(data['createdAt']),
      tokenEstimate: data['tokenEstimate'] ?? 0,
      contentHash: data['contentHash'],
      moderation: ModerationInfo.fromMap(data['moderation'] ?? {}),
      aiMeta: data['aiMeta'] != null ? AIMeta.fromMap(data['aiMeta']) : null,
      stream: data['stream'] != null ? StreamState.fromMap(data['stream']) : null,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'seq': seq,
      'role': role,
      'type': type,
      'content': content,
      'attachments': attachments.map((a) => a.toMap()).toList(),
      'createdAt': createdAt,
      'tokenEstimate': tokenEstimate,
      'contentHash': contentHash,
      'moderation': moderation.toMap(),
      if (aiMeta != null) 'aiMeta': aiMeta!.toMap(),
      if (stream != null) 'stream': stream!.toMap(),
    };
  }

  MessageModel copyWith({
    String? id,
    String? threadId,
    int? seq,
    String? role,
    String? type,
    String? content,
    List<MessageAttachment>? attachments,
    int? createdAt,
    int? tokenEstimate,
    String? contentHash,
    ModerationInfo? moderation,
    AIMeta? aiMeta,
    StreamState? stream,
  }) {
    return MessageModel(
      id: id ?? this.id,
      threadId: threadId ?? this.threadId,
      seq: seq ?? this.seq,
      role: role ?? this.role,
      type: type ?? this.type,
      content: content ?? this.content,
      attachments: attachments ?? this.attachments,
      createdAt: createdAt ?? this.createdAt,
      tokenEstimate: tokenEstimate ?? this.tokenEstimate,
      contentHash: contentHash ?? this.contentHash,
      moderation: moderation ?? this.moderation,
      aiMeta: aiMeta ?? this.aiMeta,
      stream: stream ?? this.stream,
    );
  }

  /// Check if this is a user message
  bool get isUser => role == 'user';

  /// Check if this is an AI message
  bool get isAssistant => role == 'assistant';

  /// Check if the message is still streaming
  bool get isStreaming => stream?.status == 'streaming';

  /// Check if the message has attachments
  bool get hasAttachments => attachments.isNotEmpty;

  /// Get formatted time
  String get formattedTime {
    final date = DateTime.fromMillisecondsSinceEpoch(createdAt);
    return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  /// Create a user message
  factory MessageModel.createUser({
    required String id,
    required String threadId,
    required int seq,
    required String content,
    List<MessageAttachment> attachments = const [],
  }) {
    return MessageModel(
      id: id,
      threadId: threadId,
      seq: seq,
      role: 'user',
      type: attachments.isNotEmpty ? 'mixed' : 'text',
      content: content,
      attachments: attachments,
      createdAt: DateTime.now().millisecondsSinceEpoch,
      moderation: ModerationInfo.empty(),
    );
  }

  /// Create an assistant placeholder for streaming
  factory MessageModel.createAssistantPlaceholder({
    required String id,
    required String threadId,
    required int seq,
    required String generationId,
    required String requestId,
  }) {
    return MessageModel(
      id: id,
      threadId: threadId,
      seq: seq,
      role: 'assistant',
      type: 'text',
      content: '',
      createdAt: DateTime.now().millisecondsSinceEpoch,
      moderation: ModerationInfo.empty(),
      stream: StreamState(
        status: 'streaming',
        generationId: generationId,
        requestId: requestId,
        cursor: 0,
        startedAt: DateTime.now().millisecondsSinceEpoch,
      ),
    );
  }
}

/// Message attachment (images)
class MessageAttachment {
  final String kind; // image
  final String storagePath;
  final String mimeType;
  final int? width;
  final int? height;
  final int? sizeBytes;
  final String? downloadUrl;

  MessageAttachment({
    required this.kind,
    required this.storagePath,
    required this.mimeType,
    this.width,
    this.height,
    this.sizeBytes,
    this.downloadUrl,
  });

  factory MessageAttachment.fromMap(Map<String, dynamic> map) {
    return MessageAttachment(
      kind: map['kind'] ?? 'image',
      storagePath: map['storagePath'] ?? '',
      mimeType: map['mimeType'] ?? 'image/jpeg',
      width: map['width'],
      height: map['height'],
      sizeBytes: map['sizeBytes'],
      downloadUrl: map['downloadUrl'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'kind': kind,
      'storagePath': storagePath,
      'mimeType': mimeType,
      if (width != null) 'width': width,
      if (height != null) 'height': height,
      if (sizeBytes != null) 'sizeBytes': sizeBytes,
      if (downloadUrl != null) 'downloadUrl': downloadUrl,
    };
  }
}

/// AI generation metadata
class AIMeta {
  final String provider;
  final String model;
  final int latencyMs;
  final double costUsdApprox;

  AIMeta({
    required this.provider,
    required this.model,
    required this.latencyMs,
    this.costUsdApprox = 0,
  });

  factory AIMeta.fromMap(Map<String, dynamic> map) {
    return AIMeta(
      provider: map['provider'] ?? 'openai',
      model: map['model'] ?? 'gpt-4',
      latencyMs: map['latencyMs'] ?? 0,
      costUsdApprox: (map['costUsdApprox'] ?? 0).toDouble(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'provider': provider,
      'model': model,
      'latencyMs': latencyMs,
      'costUsdApprox': costUsdApprox,
    };
  }
}

/// Moderation info
class ModerationInfo {
  final List<String> inputFlags;
  final List<String> outputFlags;

  ModerationInfo({
    this.inputFlags = const [],
    this.outputFlags = const [],
  });

  factory ModerationInfo.fromMap(Map<String, dynamic> map) {
    return ModerationInfo(
      inputFlags: List<String>.from(map['inputFlags'] ?? []),
      outputFlags: List<String>.from(map['outputFlags'] ?? []),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'inputFlags': inputFlags,
      'outputFlags': outputFlags,
    };
  }

  factory ModerationInfo.empty() {
    return ModerationInfo();
  }
}

/// SSE stream state
class StreamState {
  final String status; // streaming | final | error | cancelled
  final String generationId;
  final String requestId;
  final int cursor;
  final int startedAt;
  final int? lastChunkAt;
  final int? endedAt;
  final String? errorCode;

  StreamState({
    required this.status,
    required this.generationId,
    required this.requestId,
    required this.cursor,
    required this.startedAt,
    this.lastChunkAt,
    this.endedAt,
    this.errorCode,
  });

  factory StreamState.fromMap(Map<String, dynamic> map) {
    return StreamState(
      status: map['status'] ?? 'streaming',
      generationId: map['generationId'] ?? '',
      requestId: map['requestId'] ?? '',
      cursor: map['cursor'] ?? 0,
      startedAt: map['startedAt'] ?? 0,
      lastChunkAt: map['lastChunkAt'],
      endedAt: map['endedAt'],
      errorCode: map['errorCode'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'status': status,
      'generationId': generationId,
      'requestId': requestId,
      'cursor': cursor,
      'startedAt': startedAt,
      if (lastChunkAt != null) 'lastChunkAt': lastChunkAt,
      if (endedAt != null) 'endedAt': endedAt,
      if (errorCode != null) 'errorCode': errorCode,
    };
  }

  bool get isStreaming => status == 'streaming';
  bool get isFinal => status == 'final';
  bool get isError => status == 'error';
}

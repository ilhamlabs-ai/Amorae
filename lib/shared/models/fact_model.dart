import 'package:cloud_firestore/cloud_firestore.dart';

/// Fact model for durable user memory
class FactModel {
  final String id;
  final String userId;
  final String type; // profile | preference | project | constraint | emotional
  final String key;
  final dynamic value;
  final double confidence;
  final String status; // active | deprecated
  final double importance;
  final String scope; // global | thread:{threadId}
  final List<String> supersedes;
  final FactSource source;
  final int createdAt;
  final int updatedAt;

  FactModel({
    required this.id,
    required this.userId,
    required this.type,
    required this.key,
    required this.value,
    this.confidence = 0.8,
    this.status = 'active',
    this.importance = 0.5,
    this.scope = 'global',
    this.supersedes = const [],
    required this.source,
    required this.createdAt,
    required this.updatedAt,
  });

  factory FactModel.fromFirestore(DocumentSnapshot doc, String userId) {
    final data = doc.data() as Map<String, dynamic>;
    return FactModel(
      id: doc.id,
      userId: userId,
      type: data['type'] ?? 'profile',
      key: data['key'] ?? '',
      value: data['value'],
      confidence: (data['confidence'] ?? 0.8).toDouble(),
      status: data['status'] ?? 'active',
      importance: (data['importance'] ?? 0.5).toDouble(),
      scope: data['scope'] ?? 'global',
      supersedes: List<String>.from(data['supersedes'] ?? []),
      source: FactSource.fromMap(data['source'] ?? {}),
      createdAt: data['createdAt'] ?? 0,
      updatedAt: data['updatedAt'] ?? 0,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'type': type,
      'key': key,
      'value': value,
      'confidence': confidence,
      'status': status,
      'importance': importance,
      'scope': scope,
      'supersedes': supersedes,
      'source': source.toMap(),
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }

  bool get isActive => status == 'active';
  bool get isDeprecated => status == 'deprecated';
  bool get isGlobal => scope == 'global';
  bool get isHighImportance => importance >= 0.8;

  FactModel copyWith({
    String? id,
    String? userId,
    String? type,
    String? key,
    dynamic value,
    double? confidence,
    String? status,
    double? importance,
    String? scope,
    List<String>? supersedes,
    FactSource? source,
    int? createdAt,
    int? updatedAt,
  }) {
    return FactModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      type: type ?? this.type,
      key: key ?? this.key,
      value: value ?? this.value,
      confidence: confidence ?? this.confidence,
      status: status ?? this.status,
      importance: importance ?? this.importance,
      scope: scope ?? this.scope,
      supersedes: supersedes ?? this.supersedes,
      source: source ?? this.source,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

/// Source provenance for a fact
class FactSource {
  final String threadId;
  final String messageId;
  final int seq;
  final int timestamp;

  FactSource({
    required this.threadId,
    required this.messageId,
    required this.seq,
    required this.timestamp,
  });

  factory FactSource.fromMap(Map<String, dynamic> map) {
    return FactSource(
      threadId: map['threadId'] ?? '',
      messageId: map['messageId'] ?? '',
      seq: map['seq'] ?? 0,
      timestamp: map['timestamp'] ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'threadId': threadId,
      'messageId': messageId,
      'seq': seq,
      'timestamp': timestamp,
    };
  }
}

/// Fact types
class FactTypes {
  static const String profile = 'profile';
  static const String preference = 'preference';
  static const String project = 'project';
  static const String constraint = 'constraint';
  static const String emotional = 'emotional';
}

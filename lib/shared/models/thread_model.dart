import 'package:cloud_firestore/cloud_firestore.dart';

/// Thread model matching Firestore schema
class ThreadModel {
  final String id;
  final String userId;
  final String title;
  final String? persona; // Persona name used in this thread
  final String? customPersonaName; // Custom name for girlfriend/boyfriend/friend
  final int createdAt;
  final int updatedAt;
  final int lastMessageAt;
  final int seqCounter;
  final int messageCount;
  final int tokenCountApprox;
  final SummaryState summaryState;
  final ThreadState state;

  ThreadModel({
    required this.id,
    required this.userId,
    required this.title,
    this.persona,
    this.customPersonaName,
    required this.createdAt,
    required this.updatedAt,
    required this.lastMessageAt,
    this.seqCounter = 0,
    this.messageCount = 0,
    this.tokenCountApprox = 0,
    required this.summaryState,
    required this.state,
  });

  factory ThreadModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    // Handle Firestore Timestamp conversion
    int getTimestamp(dynamic value) {
      if (value == null) return DateTime.now().millisecondsSinceEpoch;
      if (value is Timestamp) return value.millisecondsSinceEpoch;
      if (value is int) return value;
      return DateTime.now().millisecondsSinceEpoch;
    }
    
    return ThreadModel(
      id: doc.id,
      userId: data['userId'] ?? '',
      title: data['title'] ?? 'New Chat',
      persona: data['persona'],
      customPersonaName: data['customPersonaName'],
      createdAt: getTimestamp(data['createdAt']),
      updatedAt: getTimestamp(data['updatedAt']),
      lastMessageAt: getTimestamp(data['lastMessageAt']),
      seqCounter: data['seqCounter'] ?? 0,
      messageCount: data['messageCount'] ?? 0,
      tokenCountApprox: data['tokenCountApprox'] ?? 0,
      summaryState: SummaryState.fromMap(data['summaryState'] ?? {}),
      state: ThreadState.fromMap(data['state'] ?? {}),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'title': title,
      'persona': persona,
      'customPersonaName': customPersonaName,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
      'lastMessageAt': lastMessageAt,
      'seqCounter': seqCounter,
      'messageCount': messageCount,
      'tokenCountApprox': tokenCountApprox,
      'summaryState': summaryState.toMap(),
      'state': state.toMap(),
    };
  }

  ThreadModel copyWith({
    String? id,
    String? userId,
    String? title,
    String? persona,
    String? customPersonaName,
    int? createdAt,
    int? updatedAt,
    int? lastMessageAt,
    int? seqCounter,
    int? messageCount,
    int? tokenCountApprox,
    SummaryState? summaryState,
    ThreadState? state,
  }) {
    return ThreadModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      persona: persona ?? this.persona,
      customPersonaName: customPersonaName ?? this.customPersonaName,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      lastMessageAt: lastMessageAt ?? this.lastMessageAt,
      seqCounter: seqCounter ?? this.seqCounter,
      messageCount: messageCount ?? this.messageCount,
      tokenCountApprox: tokenCountApprox ?? this.tokenCountApprox,
      summaryState: summaryState ?? this.summaryState,
      state: state ?? this.state,
    );
  }

  /// Create a new thread
  factory ThreadModel.create({
    required String id,
    required String userId,
    String title = 'New Chat',
    String? persona,
    String? customPersonaName,
  }) {
    final now = DateTime.now().millisecondsSinceEpoch;
    return ThreadModel(
      id: id,
      userId: userId,
      title: title,
      persona: persona,
      customPersonaName: customPersonaName,
      createdAt: now,
      updatedAt: now,
      lastMessageAt: now,
      summaryState: SummaryState.initial(),
      state: ThreadState.initial(),
    );
  }

  /// Get formatted last message time
  String get formattedLastMessageTime {
    final date = DateTime.fromMillisecondsSinceEpoch(lastMessageAt);
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inDays > 7) {
      return '${date.month}/${date.day}';
    } else if (diff.inDays > 0) {
      return '${diff.inDays}d ago';
    } else if (diff.inHours > 0) {
      return '${diff.inHours}h ago';
    } else if (diff.inMinutes > 0) {
      return '${diff.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }
}

/// Summary state for thread
class SummaryState {
  final String? threadSummaryId;
  final int summaryCursorSeq;
  final int summaryVersion;

  SummaryState({
    this.threadSummaryId,
    this.summaryCursorSeq = 0,
    this.summaryVersion = 1,
  });

  factory SummaryState.fromMap(Map<String, dynamic> map) {
    return SummaryState(
      threadSummaryId: map['threadSummaryId'],
      summaryCursorSeq: map['summaryCursorSeq'] ?? 0,
      summaryVersion: map['summaryVersion'] ?? 1,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'threadSummaryId': threadSummaryId,
      'summaryCursorSeq': summaryCursorSeq,
      'summaryVersion': summaryVersion,
    };
  }

  factory SummaryState.initial() {
    return SummaryState();
  }
}

/// Thread state
class ThreadState {
  final List<String> pinnedFactIds;
  final String riskState; // none | watch | high

  ThreadState({
    this.pinnedFactIds = const [],
    this.riskState = 'none',
  });

  factory ThreadState.fromMap(Map<String, dynamic> map) {
    return ThreadState(
      pinnedFactIds: List<String>.from(map['pinnedFactIds'] ?? []),
      riskState: map['riskState'] ?? 'none',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'pinnedFactIds': pinnedFactIds,
      'riskState': riskState,
    };
  }

  factory ThreadState.initial() {
    return ThreadState();
  }
}

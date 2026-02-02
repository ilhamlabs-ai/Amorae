import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import '../models/user_model.dart';
import '../models/thread_model.dart';
import '../models/message_model.dart';
import '../models/fact_model.dart';
import '../models/persona_model.dart';

/// Firestore service for all database operations
class FirestoreService {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  FirestoreService({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  })  : _firestore = firestore ?? FirebaseFirestore.instanceFor(
          app: Firebase.app(),
          databaseId: 'amorae',
        ),
        _auth = auth ?? FirebaseAuth.instance;

  String? get currentUserId => _auth.currentUser?.uid;

  // ============ USERS ============

  /// Get user document reference
  DocumentReference<Map<String, dynamic>> _userRef(String userId) {
    return _firestore.collection('users').doc(userId);
  }

  /// Get or create user
  Future<UserModel> getOrCreateUser({
    required String userId,
    String? displayName,
    String? photoUrl,
  }) async {
    print('🔍 getOrCreateUser called for userId: $userId');
    final ref = _userRef(userId);
    
    try {
      print('📡 Fetching user document from Firestore...');
      final doc = await ref.get();
      print('📊 Document snapshot - exists: ${doc.exists}, source: ${doc.metadata.isFromCache ? "CACHE" : "SERVER"}');

      if (doc.exists) {
        print('📄 User document exists, returning existing user');
        final userData = doc.data();
        print('📋 User data: $userData');
        return UserModel.fromFirestore(doc);
      }

      // Create new user
      print('📝 Document does not exist. Creating new user document...');
      final user = UserModel.createDefault(
        id: userId,
        displayName: displayName,
        photoUrl: photoUrl,
      );
      
      final userData = user.toFirestore();
      print('📋 User data to save: $userData');
      print('🔐 Current auth user: ${_auth.currentUser?.uid}');

      // Use set to create the document
      print('💾 Calling Firestore set()...');
      await ref.set(userData, SetOptions(merge: true));
      print('✅ Firestore set() completed without error');
      
      // Verify it was created
      print('🔍 Verifying document was created...');
      final verifyDoc = await ref.get();
      print('✔️ Verification - exists: ${verifyDoc.exists}, source: ${verifyDoc.metadata.isFromCache ? "CACHE" : "SERVER"}');
      
      return user;
    } catch (e, stackTrace) {
      print('❌ Error in getOrCreateUser: $e');
      print('📚 Stack trace: $stackTrace');
      rethrow;
    }
  }

  /// Get user by ID
  Future<UserModel?> getUser(String userId) async {
    final doc = await _userRef(userId).get();
    if (!doc.exists) return null;
    return UserModel.fromFirestore(doc);
  }

  /// Update user
  Future<void> updateUser(String userId, Map<String, dynamic> data) async {
    print('📝 updateUser called for userId: $userId with data keys: ${data.keys.toList()}');
    data['updatedAt'] = DateTime.now().millisecondsSinceEpoch;
    
    try {
      // Use set with merge to handle cases where document might not exist yet
      await _userRef(userId).set(data, SetOptions(merge: true));
      print('✅ User updated successfully');
    } catch (e, stackTrace) {
      print('❌ Error updating user: $e');
      print('📚 Stack trace: $stackTrace');
      rethrow;
    }
  }

  /// Stream user changes
  Stream<UserModel?> streamUser(String userId) {
    return _userRef(userId).snapshots().map((doc) {
      if (!doc.exists) return null;
      return UserModel.fromFirestore(doc);
    });
  }

  // ============ THREADS ============

  /// Get threads collection reference
  CollectionReference<Map<String, dynamic>> get _threadsRef {
    return _firestore.collection('threads');
  }

  /// Create a new thread
  Future<ThreadModel> createThread({
    required String userId,
    String? title,
    String? persona,
    String? customPersonaName,
  }) async {
    // Get user to determine persona and generate title
    final user = await getUser(userId);
    final selectedPersona = persona ?? user?.prefs.selectedPersona ?? 'girlfriend';
    
    // Generate title - prioritize custom name for personalized feel
    String threadTitle;
    if (title != null) {
      threadTitle = title;
    } else if (customPersonaName != null && customPersonaName.isNotEmpty) {
      // Use custom name if provided
      threadTitle = 'Chat with $customPersonaName';
    } else {
      // Fall back to persona display name
      final personaModel = PersonaModel.getByName(selectedPersona);
      if (personaModel != null) {
        threadTitle = 'Chat with ${personaModel.displayName}';
      } else {
        threadTitle = 'Chat with $selectedPersona';
      }
    }
    
    print('🔵 Creating thread: persona=$selectedPersona, customName=$customPersonaName, title=$threadTitle');
    
    final ref = _threadsRef.doc();
    final thread = ThreadModel.create(
      id: ref.id,
      userId: userId,
      title: threadTitle,
      persona: selectedPersona,
      customPersonaName: customPersonaName,
    );

    await ref.set(thread.toFirestore());
    print('✅ Thread created: id=${thread.id}, customPersonaName=${thread.customPersonaName}');
    return thread;
  }

  /// Get thread by ID
  Future<ThreadModel?> getThread(String threadId) async {
    final doc = await _threadsRef.doc(threadId).get();
    if (!doc.exists) return null;
    return ThreadModel.fromFirestore(doc);
  }

  /// Update thread
  Future<void> updateThread(String threadId, Map<String, dynamic> data) async {
    data['updatedAt'] = DateTime.now().millisecondsSinceEpoch;
    await _threadsRef.doc(threadId).update(data);
  }

  /// Update thread's custom persona name
  Future<void> updateThreadCustomName(String threadId, String customName) async {
    await updateThread(threadId, {
      'customPersonaName': customName,
      'title': 'Chat with $customName',
    });
  }

  /// Update thread's persona type and custom name
  Future<void> updateThreadPersona(String threadId, String persona, String? customName) async {
    await updateThread(threadId, {
      'persona': persona,
      'customPersonaName': customName,
      'title': 'Chat with ${customName ?? persona}',
    });
  }

  /// Update all threads for a user with a specific persona to use new custom name
  Future<int> updateAllThreadsCustomName({
    required String userId,
    required String persona,
    required String newCustomName,
  }) async {
    final query = await _threadsRef
        .where('userId', isEqualTo: userId)
        .where('persona', isEqualTo: persona)
        .get();
    
    if (query.docs.isEmpty) return 0;
    
    final batch = _firestore.batch();
    for (var doc in query.docs) {
      batch.update(doc.reference, {
        'customPersonaName': newCustomName,
        'title': 'Chat with $newCustomName',
        'updatedAt': DateTime.now().millisecondsSinceEpoch,
      });
    }
    await batch.commit();
    return query.docs.length;
  }

  /// Delete thread and all messages
  Future<void> deleteThread(String threadId) async {
    // Delete all messages first
    final messagesRef = _threadsRef.doc(threadId).collection('messages');
    final messages = await messagesRef.get();
    
    final batch = _firestore.batch();
    for (var doc in messages.docs) {
      batch.delete(doc.reference);
    }
    
    // Delete thread
    batch.delete(_threadsRef.doc(threadId));
    await batch.commit();
  }

  /// Stream user's threads
  Stream<List<ThreadModel>> streamUserThreads(String userId) {
    return _threadsRef
        .where('userId', isEqualTo: userId)
        .orderBy('lastMessageAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => ThreadModel.fromFirestore(doc)).toList();
    });
  }

  /// Get user's threads
  Future<List<ThreadModel>> getUserThreads(String userId) async {
    final snapshot = await _threadsRef
        .where('userId', isEqualTo: userId)
        .orderBy('lastMessageAt', descending: true)
        .get();
    return snapshot.docs.map((doc) => ThreadModel.fromFirestore(doc)).toList();
  }

  // ============ MESSAGES ============

  /// Get messages collection reference
  CollectionReference<Map<String, dynamic>> _messagesRef(String threadId) {
    return _threadsRef.doc(threadId).collection('messages');
  }

  /// Add a message
  Future<MessageModel> addMessage({
    required String threadId,
    required MessageModel message,
  }) async {
    // Get next seq number atomically
    final threadRef = _threadsRef.doc(threadId);
    
    return _firestore.runTransaction((transaction) async {
      final threadDoc = await transaction.get(threadRef);
      final currentSeq = (threadDoc.data()?['seqCounter'] ?? 0) as int;
      final newSeq = currentSeq + 1;
      
      final messageWithSeq = message.copyWith(seq: newSeq);
      final messageRef = _messagesRef(threadId).doc(message.id);
      
      transaction.set(messageRef, messageWithSeq.toFirestore());
      transaction.update(threadRef, {
        'seqCounter': newSeq,
        'messageCount': FieldValue.increment(1),
        'lastMessageAt': DateTime.now().millisecondsSinceEpoch,
        'updatedAt': DateTime.now().millisecondsSinceEpoch,
      });
      
      return messageWithSeq;
    });
  }

  /// Update message (for streaming updates)
  Future<void> updateMessage({
    required String threadId,
    required String messageId,
    required Map<String, dynamic> data,
  }) async {
    await _messagesRef(threadId).doc(messageId).update(data);
  }

  /// Get message by ID
  Future<MessageModel?> getMessage(String threadId, String messageId) async {
    final doc = await _messagesRef(threadId).doc(messageId).get();
    if (!doc.exists) return null;
    return MessageModel.fromFirestore(doc, threadId);
  }

  /// Stream messages for a thread
  Stream<List<MessageModel>> streamMessages(String threadId) {
    return _messagesRef(threadId)
        .orderBy('seq', descending: false)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => MessageModel.fromFirestore(doc, threadId))
          .toList();
    });
  }

  /// Get recent messages (for working set)
  Future<List<MessageModel>> getRecentMessages(
    String threadId, {
    int limit = 20,
  }) async {
    final snapshot = await _messagesRef(threadId)
        .orderBy('seq', descending: true)
        .limit(limit)
        .get();
    
    return snapshot.docs
        .map((doc) => MessageModel.fromFirestore(doc, threadId))
        .toList()
        .reversed
        .toList();
  }

  // ============ FACTS ============

  /// Get facts collection reference
  CollectionReference<Map<String, dynamic>> _factsRef(String userId) {
    return _userRef(userId).collection('facts');
  }

  /// Add a fact
  Future<FactModel> addFact({
    required String userId,
    required FactModel fact,
  }) async {
    final ref = _factsRef(userId).doc(fact.id);
    await ref.set(fact.toFirestore());
    return fact;
  }

  /// Get active facts for user
  Future<List<FactModel>> getActiveFacts(String userId) async {
    final snapshot = await _factsRef(userId)
        .where('status', isEqualTo: 'active')
        .orderBy('importance', descending: true)
        .get();
    
    return snapshot.docs
        .map((doc) => FactModel.fromFirestore(doc, userId))
        .toList();
  }

  /// Get high importance facts
  Future<List<FactModel>> getHighImportanceFacts(String userId) async {
    final snapshot = await _factsRef(userId)
        .where('status', isEqualTo: 'active')
        .where('importance', isGreaterThanOrEqualTo: 0.8)
        .get();
    
    return snapshot.docs
        .map((doc) => FactModel.fromFirestore(doc, userId))
        .toList();
  }

  /// Stream facts
  Stream<List<FactModel>> streamFacts(String userId) {
    return _factsRef(userId)
        .where('status', isEqualTo: 'active')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => FactModel.fromFirestore(doc, userId))
          .toList();
    });
  }

  /// Deprecate a fact
  Future<void> deprecateFact(String userId, String factId) async {
    await _factsRef(userId).doc(factId).update({
      'status': 'deprecated',
      'updatedAt': DateTime.now().millisecondsSinceEpoch,
    });
  }

  /// Delete all user data (threads, messages, facts, and user document)
  Future<void> deleteUser(String userId) async {
    print('🗑️ Starting user deletion for userId: $userId');
    
    try {
      // Delete all threads and their messages
      print('🗑️ Deleting threads...');
      final threadsSnapshot = await _threadsRef
          .where('userId', isEqualTo: userId)
          .get();
      
      for (final threadDoc in threadsSnapshot.docs) {
        final threadId = threadDoc.id;
        print('🗑️ Deleting thread: $threadId');
        
        // Delete all messages in thread
        final messagesSnapshot = await threadDoc.reference
            .collection('messages')
            .get();
        for (final messageDoc in messagesSnapshot.docs) {
          await messageDoc.reference.delete();
        }
        
        // Delete thread document
        await threadDoc.reference.delete();
      }
      
      // Delete all facts
      print('🗑️ Deleting facts...');
      final factsSnapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('facts')
          .get();
      for (final factDoc in factsSnapshot.docs) {
        await factDoc.reference.delete();
      }
      
      // Delete user document
      print('🗑️ Deleting user document...');
      await _userRef(userId).delete();
      
      print('✅ User deletion completed successfully');
    } catch (e, stackTrace) {
      print('❌ Error deleting user: $e');
      print('📚 Stack trace: $stackTrace');
      rethrow;
    }
  }
}

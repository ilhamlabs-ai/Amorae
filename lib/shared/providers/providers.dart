import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/services.dart';
import '../models/models.dart';

// ============ SERVICE PROVIDERS ============

/// Auth service provider
final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService();
});

/// Firestore service provider
final firestoreServiceProvider = Provider<FirestoreService>((ref) {
  return FirestoreService();
});

/// Storage service provider
final storageServiceProvider = Provider<StorageService>((ref) {
  return StorageService();
});

/// API client provider
final apiClientProvider = Provider<ApiClient>((ref) {
  // Production backend on AWS Lightsail with HTTPS and custom domain
  const String productionUrl = 'https://amorae.duckdns.org';
  
  // Local development backend
  const String localUrl = 'http://192.168.0.147:8000';
  
  // Use production URL by default
  // Switch to localUrl for local development
  return ApiClient(baseUrl: productionUrl);
});

// ============ AUTH PROVIDERS ============

/// Auth state stream provider
final authStateProvider = StreamProvider<User?>((ref) {
  final authService = ref.watch(authServiceProvider);
  return authService.authStateChanges;
});

/// Current user ID provider
final currentUserIdProvider = Provider<String?>((ref) {
  final authState = ref.watch(authStateProvider);
  return authState.whenData((user) => user?.uid).value;
});

/// Is signed in provider
final isSignedInProvider = Provider<bool>((ref) {
  final userId = ref.watch(currentUserIdProvider);
  return userId != null;
});

// ============ USER PROVIDERS ============

/// Current user model provider
final currentUserProvider = StreamProvider<UserModel?>((ref) {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) return Stream.value(null);
  
  final firestore = ref.watch(firestoreServiceProvider);
  return firestore.streamUser(userId);
});

/// User onboarding complete provider
final isOnboardingCompleteProvider = Provider<bool>((ref) {
  final userAsync = ref.watch(currentUserProvider);
  return userAsync.whenData((user) => user?.onboarding.completed ?? false).value ?? false;
});

// ============ THREAD PROVIDERS ============

/// User threads stream provider
final userThreadsProvider = StreamProvider<List<ThreadModel>>((ref) {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) return Stream.value([]);
  
  final firestore = ref.watch(firestoreServiceProvider);
  return firestore.streamUserThreads(userId);
});

/// Selected thread ID provider
final selectedThreadIdProvider = StateProvider<String?>((ref) => null);

/// Selected thread provider
final selectedThreadProvider = FutureProvider<ThreadModel?>((ref) async {
  final threadId = ref.watch(selectedThreadIdProvider);
  if (threadId == null) return null;
  
  final firestore = ref.watch(firestoreServiceProvider);
  return firestore.getThread(threadId);
});

// ============ MESSAGES PROVIDERS ============

/// Messages for selected thread
final messagesProvider = StreamProvider<List<MessageModel>>((ref) {
  final threadId = ref.watch(selectedThreadIdProvider);
  if (threadId == null) return Stream.value([]);
  
  final firestore = ref.watch(firestoreServiceProvider);
  return firestore.streamMessages(threadId);
});

// ============ FACTS PROVIDERS ============

/// User facts provider
final userFactsProvider = StreamProvider<List<FactModel>>((ref) {
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) return Stream.value([]);
  
  final firestore = ref.watch(firestoreServiceProvider);
  return firestore.streamFacts(userId);
});

// ============ CHAT STATE PROVIDERS ============

/// Chat sending state
final isSendingMessageProvider = StateProvider<bool>((ref) => false);

/// Current streaming content
final streamingContentProvider = StateProvider<String>((ref) => '');

/// Is AI typing indicator
final isAITypingProvider = StateProvider<bool>((ref) => false);

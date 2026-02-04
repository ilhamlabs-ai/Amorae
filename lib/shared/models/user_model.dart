import 'package:cloud_firestore/cloud_firestore.dart';

/// User model matching Firestore schema
class UserModel {
  final String id;
  final int createdAt;
  final int updatedAt;
  final String? displayName;
  final String? photoUrl;
  final String? gender; // Optional: male, female, other, null
  final int? age; // Optional: user-provided age
  final String? bio; // Optional: short user bio
  final String locale;
  final String timezone;
  final OnboardingState onboarding;
  final SafetySettings safety;
  final UserPreferences prefs;
  final UserPlan plan;

  UserModel({
    required this.id,
    required this.createdAt,
    required this.updatedAt,
    this.displayName,
    this.photoUrl,
    this.gender,
    this.age,
    this.bio,
    this.locale = 'en',
    this.timezone = 'UTC',
    required this.onboarding,
    required this.safety,
    required this.prefs,
    required this.plan,
  });

  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UserModel(
      id: doc.id,
      createdAt: data['createdAt'] ?? 0,
      updatedAt: data['updatedAt'] ?? 0,
      displayName: data['displayName'],
      photoUrl: data['photoUrl'],
      gender: data['gender'],
      age: data['age'],
      bio: data['bio'],
      locale: data['locale'] ?? 'en',
      timezone: data['timezone'] ?? 'UTC',
      onboarding: OnboardingState.fromMap(data['onboarding'] ?? {}),
      safety: SafetySettings.fromMap(data['safety'] ?? {}),
      prefs: UserPreferences.fromMap(data['prefs'] ?? {}),
      plan: UserPlan.fromMap(data['plan'] ?? {}),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'createdAt': createdAt,
      'updatedAt': updatedAt,
      'displayName': displayName,
      'photoUrl': photoUrl,
      'gender': gender,
      'age': age,
      'bio': bio,
      'locale': locale,
      'timezone': timezone,
      'onboarding': onboarding.toMap(),
      'safety': safety.toMap(),
      'prefs': prefs.toMap(),
      'plan': plan.toMap(),
    };
  }

  UserModel copyWith({
    String? id,
    int? createdAt,
    int? updatedAt,
    String? displayName,
    String? photoUrl,
    String? gender,
    int? age,
    String? bio,
    String? locale,
    String? timezone,
    OnboardingState? onboarding,
    SafetySettings? safety,
    UserPreferences? prefs,
    UserPlan? plan,
  }) {
    return UserModel(
      id: id ?? this.id,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      displayName: displayName ?? this.displayName,
      photoUrl: photoUrl ?? this.photoUrl,
      gender: gender ?? this.gender,
      age: age ?? this.age,
      bio: bio ?? this.bio,
      locale: locale ?? this.locale,
      timezone: timezone ?? this.timezone,
      onboarding: onboarding ?? this.onboarding,
      safety: safety ?? this.safety,
      prefs: prefs ?? this.prefs,
      plan: plan ?? this.plan,
    );
  }

  /// Create a default user for new sign-ups
  factory UserModel.createDefault({
    required String id,
    String? displayName,
    String? photoUrl,
  }) {
    final now = DateTime.now().millisecondsSinceEpoch;
    return UserModel(
      id: id,
      createdAt: now,
      updatedAt: now,
      displayName: displayName,
      photoUrl: photoUrl,
      age: null,
      bio: null,
      onboarding: OnboardingState.initial(),
      safety: SafetySettings.initial(),
      prefs: UserPreferences.initial(),
      plan: UserPlan.free(),
    );
  }
}

/// Onboarding state
class OnboardingState {
  final bool completed;
  final int version;
  final int? completedAt;

  OnboardingState({
    this.completed = false,
    this.version = 1,
    this.completedAt,
  });

  factory OnboardingState.fromMap(Map<String, dynamic> map) {
    return OnboardingState(
      completed: map['completed'] ?? false,
      version: map['version'] ?? 1,
      completedAt: map['completedAt'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'completed': completed,
      'version': version,
      'completedAt': completedAt,
    };
  }

  factory OnboardingState.initial() {
    return OnboardingState(completed: false, version: 1);
  }

  OnboardingState copyWith({
    bool? completed,
    int? version,
    int? completedAt,
  }) {
    return OnboardingState(
      completed: completed ?? this.completed,
      version: version ?? this.version,
      completedAt: completedAt ?? this.completedAt,
    );
  }
}

/// Safety settings
class SafetySettings {
  final bool ageConfirmed18Plus;
  final bool aiDisclosureAccepted;
  final bool dependencyGuardEnabled;
  final bool selfHarmEscalationEnabled;

  SafetySettings({
    this.ageConfirmed18Plus = false,
    this.aiDisclosureAccepted = false,
    this.dependencyGuardEnabled = true,
    this.selfHarmEscalationEnabled = true,
  });

  factory SafetySettings.fromMap(Map<String, dynamic> map) {
    return SafetySettings(
      ageConfirmed18Plus: map['ageConfirmed18Plus'] ?? false,
      aiDisclosureAccepted: map['aiDisclosureAccepted'] ?? false,
      dependencyGuardEnabled: map['dependencyGuardEnabled'] ?? true,
      selfHarmEscalationEnabled: map['selfHarmEscalationEnabled'] ?? true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'ageConfirmed18Plus': ageConfirmed18Plus,
      'aiDisclosureAccepted': aiDisclosureAccepted,
      'dependencyGuardEnabled': dependencyGuardEnabled,
      'selfHarmEscalationEnabled': selfHarmEscalationEnabled,
    };
  }

  factory SafetySettings.initial() {
    return SafetySettings();
  }

  SafetySettings copyWith({
    bool? ageConfirmed18Plus,
    bool? aiDisclosureAccepted,
    bool? dependencyGuardEnabled,
    bool? selfHarmEscalationEnabled,
  }) {
    return SafetySettings(
      ageConfirmed18Plus: ageConfirmed18Plus ?? this.ageConfirmed18Plus,
      aiDisclosureAccepted: aiDisclosureAccepted ?? this.aiDisclosureAccepted,
      dependencyGuardEnabled: dependencyGuardEnabled ?? this.dependencyGuardEnabled,
      selfHarmEscalationEnabled: selfHarmEscalationEnabled ?? this.selfHarmEscalationEnabled,
    );
  }
}

/// User preferences for AI interaction
class UserPreferences {
  final String selectedPersona; // amora (default), einstein, gandhi, etc.
  final String emojiLevel; // none | minimal | moderate | expressive
  final List<String> topicsToAvoid;
  final List<String> phrasesToAvoid;

  UserPreferences({
    this.selectedPersona = 'amora',
    this.emojiLevel = 'moderate',
    this.topicsToAvoid = const [],
    this.phrasesToAvoid = const [],
  });

  factory UserPreferences.fromMap(Map<String, dynamic> map) {
    return UserPreferences(
      selectedPersona: map['selectedPersona'] ?? 'amora',
      emojiLevel: map['emojiLevel'] ?? 'moderate',
      topicsToAvoid: List<String>.from(map['topicsToAvoid'] ?? []),
      phrasesToAvoid: List<String>.from(map['phrasesToAvoid'] ?? []),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'selectedPersona': selectedPersona,
      'emojiLevel': emojiLevel,
      'topicsToAvoid': topicsToAvoid,
      'phrasesToAvoid': phrasesToAvoid,
    };
  }

  factory UserPreferences.initial() {
    return UserPreferences();
  }

  UserPreferences copyWith({
    String? selectedPersona,
    String? emojiLevel,
    List<String>? topicsToAvoid,
    List<String>? phrasesToAvoid,
  }) {
    return UserPreferences(
      selectedPersona: selectedPersona ?? this.selectedPersona,
      emojiLevel: emojiLevel ?? this.emojiLevel,
      topicsToAvoid: topicsToAvoid ?? this.topicsToAvoid,
      phrasesToAvoid: phrasesToAvoid ?? this.phrasesToAvoid,
    );
  }
}

/// User plan / subscription info
class UserPlan {
  final String tier; // free | pro
  final DailyQuota quotaDaily;

  UserPlan({
    this.tier = 'free',
    required this.quotaDaily,
  });

  factory UserPlan.fromMap(Map<String, dynamic> map) {
    return UserPlan(
      tier: map['tier'] ?? 'free',
      quotaDaily: DailyQuota.fromMap(map['quotaDaily'] ?? {}),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'tier': tier,
      'quotaDaily': quotaDaily.toMap(),
    };
  }

  factory UserPlan.free() {
    return UserPlan(
      tier: 'free',
      quotaDaily: DailyQuota(messages: 100, images: 10),
    );
  }

  factory UserPlan.pro() {
    return UserPlan(
      tier: 'pro',
      quotaDaily: DailyQuota(messages: 1000, images: 100),
    );
  }
}

/// Daily usage quota
class DailyQuota {
  final int messages;
  final int images;

  DailyQuota({
    this.messages = 100,
    this.images = 10,
  });

  factory DailyQuota.fromMap(Map<String, dynamic> map) {
    return DailyQuota(
      messages: map['messages'] ?? 100,
      images: map['images'] ?? 10,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'messages': messages,
      'images': images,
    };
  }
}

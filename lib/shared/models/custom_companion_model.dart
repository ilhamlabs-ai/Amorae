import 'package:cloud_firestore/cloud_firestore.dart';

/// Custom companion model matching Firestore schema
class CustomCompanionModel {
  final String id;
  final String name;
  final String? gender; // male | female | non-binary | other | prefer-not-to-say
  final String relationship; // girlfriend | boyfriend | best_friend | therapist | father | mother | custom | romantic | platonic | mentor | coach | confidant | professional
  final String? customRelationship; // user-defined relationship label
  final String? bio;
  final int createdAt;
  final int updatedAt;

  CustomCompanionModel({
    required this.id,
    required this.name,
    required this.relationship,
    this.gender,
    this.customRelationship,
    this.bio,
    required this.createdAt,
    required this.updatedAt,
  });

  factory CustomCompanionModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    int getTimestamp(dynamic value) {
      if (value == null) return DateTime.now().millisecondsSinceEpoch;
      if (value is Timestamp) return value.millisecondsSinceEpoch;
      if (value is int) return value;
      return DateTime.now().millisecondsSinceEpoch;
    }

    return CustomCompanionModel(
      id: doc.id,
      name: data['name'] ?? '',
      gender: data['gender'],
      relationship: data['relationship'] ?? 'platonic',
      customRelationship: data['customRelationship'],
      bio: data['bio'],
      createdAt: getTimestamp(data['createdAt']),
      updatedAt: getTimestamp(data['updatedAt']),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'gender': gender,
      'relationship': relationship,
      'customRelationship': customRelationship,
      'bio': bio,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }

  Map<String, dynamic> toThreadMap() {
    return {
      'id': id,
      'name': name,
      'gender': gender,
      'relationship': relationship,
      'customRelationship': customRelationship,
      'bio': bio,
    };
  }

  CustomCompanionModel copyWith({
    String? id,
    String? name,
    String? gender,
    String? relationship,
    String? customRelationship,
    String? bio,
    int? createdAt,
    int? updatedAt,
  }) {
    return CustomCompanionModel(
      id: id ?? this.id,
      name: name ?? this.name,
      gender: gender ?? this.gender,
      relationship: relationship ?? this.relationship,
      customRelationship: customRelationship ?? this.customRelationship,
      bio: bio ?? this.bio,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  factory CustomCompanionModel.create({
    required String id,
    required String name,
    required String relationship,
    String? gender,
    String? customRelationship,
    String? bio,
  }) {
    final now = DateTime.now().millisecondsSinceEpoch;
    return CustomCompanionModel(
      id: id,
      name: name,
      relationship: relationship,
      gender: gender,
      customRelationship: customRelationship,
      bio: bio,
      createdAt: now,
      updatedAt: now,
    );
  }
}

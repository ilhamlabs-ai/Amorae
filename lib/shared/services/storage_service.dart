import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:uuid/uuid.dart';

/// Storage service for image uploads
class StorageService {
  final FirebaseStorage _storage;
  final Uuid _uuid = const Uuid();

  StorageService({FirebaseStorage? storage})
      : _storage = storage ?? FirebaseStorage.instance;

  /// Get storage path for thread images
  String _getImagePath(String userId, String threadId, String extension) {
    final imageId = _uuid.v4();
    return 'users/$userId/threads/$threadId/images/$imageId.$extension';
  }

  /// Upload image from file
  Future<UploadResult> uploadImage({
    required String userId,
    required String threadId,
    required File file,
    String mimeType = 'image/jpeg',
  }) async {
    // Determine extension
    final extension = _getExtension(mimeType);
    final storagePath = _getImagePath(userId, threadId, extension);
    final ref = _storage.ref(storagePath);

    // Upload file
    final metadata = SettableMetadata(
      contentType: mimeType,
      customMetadata: {
        'userId': userId,
        'threadId': threadId,
        'uploadedAt': DateTime.now().toIso8601String(),
      },
    );

    final uploadTask = ref.putFile(file, metadata);
    final snapshot = await uploadTask;

    // Get download URL
    final downloadUrl = await snapshot.ref.getDownloadURL();

    // Get file metadata
    final fileMetadata = await ref.getMetadata();

    return UploadResult(
      storagePath: storagePath,
      downloadUrl: downloadUrl,
      mimeType: mimeType,
      sizeBytes: fileMetadata.size ?? 0,
    );
  }

  /// Upload image from bytes
  Future<UploadResult> uploadImageBytes({
    required String userId,
    required String threadId,
    required List<int> bytes,
    String mimeType = 'image/jpeg',
  }) async {
    final extension = _getExtension(mimeType);
    final storagePath = _getImagePath(userId, threadId, extension);
    final ref = _storage.ref(storagePath);

    final metadata = SettableMetadata(
      contentType: mimeType,
      customMetadata: {
        'userId': userId,
        'threadId': threadId,
        'uploadedAt': DateTime.now().toIso8601String(),
      },
    );

    final uploadTask = ref.putData(
      bytes is List<int> ? bytes as dynamic : bytes,
      metadata,
    );
    final snapshot = await uploadTask;

    final downloadUrl = await snapshot.ref.getDownloadURL();

    return UploadResult(
      storagePath: storagePath,
      downloadUrl: downloadUrl,
      mimeType: mimeType,
      sizeBytes: bytes.length,
    );
  }

  /// Get download URL for a storage path
  Future<String> getDownloadUrl(String storagePath) async {
    final ref = _storage.ref(storagePath);
    return ref.getDownloadURL();
  }

  /// Delete file
  Future<void> deleteFile(String storagePath) async {
    final ref = _storage.ref(storagePath);
    await ref.delete();
  }

  /// Delete all thread images
  Future<void> deleteThreadImages(String userId, String threadId) async {
    final prefix = 'users/$userId/threads/$threadId/images/';
    final listResult = await _storage.ref(prefix).listAll();
    
    for (var item in listResult.items) {
      await item.delete();
    }
  }

  String _getExtension(String mimeType) {
    switch (mimeType) {
      case 'image/png':
        return 'png';
      case 'image/gif':
        return 'gif';
      case 'image/webp':
        return 'webp';
      case 'image/jpeg':
      default:
        return 'jpg';
    }
  }
}

/// Result of an image upload
class UploadResult {
  final String storagePath;
  final String downloadUrl;
  final String mimeType;
  final int sizeBytes;

  UploadResult({
    required this.storagePath,
    required this.downloadUrl,
    required this.mimeType,
    required this.sizeBytes,
  });
}

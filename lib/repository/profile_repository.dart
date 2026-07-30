import 'dart:io';
import '../models/user.dart';
import '../models/scoreboard_entry.dart';
import '../services/firestore_service.dart';
import '../services/storage_service.dart';

class ProfileRepository {
  final FirestoreService _firestoreService;
  final StorageService _storageService;

  ProfileRepository({
    FirestoreService? firestoreService,
    StorageService? storageService,
  })  : _firestoreService = firestoreService ?? FirestoreService(),
        _storageService = storageService ?? StorageService();

  /// ইউজারের প্রোফাইল ছবি ক্লাউডে আপলোড করে ডেটাবেসে URL সেভ করার লজিক
  Future<String> uploadProfileImage({
    required String userId,
    required File imageFile,
  }) async {
    final user = await _firestoreService.getUserProfile(userId);
    if (user == null) {
      throw Exception('User not found');
    }

    final ext = imageFile.path.split('.').last;
    final extension = ext.isNotEmpty ? ext : 'jpg';
    final path = 'profile_images/$userId/profile_image.$extension';

    final downloadUrl = await _storageService.uploadFile(path, imageFile);

    final updatedUser = user.copyWith(avatarUrl: downloadUrl);
    await _firestoreService.updateUserProfile(updatedUser);

    return downloadUrl;
  }

  /// ইউজারের প্রোফাইল ডাটা ফেচ করা
  Future<User?> getUserProfile(String userId) async {
    return await _firestoreService.getUserProfile(userId);
  }

  /// ইউজারের প্রোফাইল ডাটা আপডেট করা
  Future<void> updateUserProfile(User profile) async {
    return await _firestoreService.updateUserProfile(profile);
  }

  /// ইউজারের নিজস্ব কুইজ খেলার হিস্ট্রি ফেচ করা
  Future<List<ScoreboardEntry>> getPersonalResults(String userId, String filter) async {
    return await _firestoreService.getUserScoreboard(userId, filter: filter);
  }
}
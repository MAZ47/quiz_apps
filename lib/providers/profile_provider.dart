import 'package:firebase_auth/firebase_auth.dart' hide User;
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';

import '../models/scoreboard_entry.dart';
import '../models/user.dart';
import '../repository/profile_repository.dart';
import '../utils/image_picker_util.dart';

class ProfileProvider extends ChangeNotifier {
  final ProfileRepository _profileRepository;
  User? _userProfile;
  bool _isLoading = false;
  bool _isUploadingImage = false;

  String _selectedProfileFilter = 'Monthly';
  final List<ScoreboardEntry> _personalHistory = [];
  bool _isLoadingPersonalHistory = false;

  ProfileProvider({ProfileRepository? profileRepository})
      : _profileRepository = profileRepository ?? ProfileRepository();

  // গেটার্স
  User? get userProfile => _userProfile;
  bool get isLoading => _isLoading;
  bool get isUploadingImage => _isUploadingImage;
  String get selectedProfileFilter => _selectedProfileFilter;
  List<ScoreboardEntry> get personalHistory => _personalHistory;
  bool get isLoadingPersonalHistory => _isLoadingPersonalHistory;

  // পার্সোনাল স্কোর হিস্ট্রির ফিল্টার সেট করা (যেমন: Monthly, Weekly)
  set selectedProfileFilter(String filter) {
    _selectedProfileFilter = filter;
    notifyListeners();
    loadPersonalResults();
  }

  /// বর্তমানে লগইন থাকা ইউজারের প্রোফাইল ডাটা ফেচ করা
  Future<void> loadCurrentUserProfile() async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;

    _isLoading = true;
    notifyListeners();

    try {
      _userProfile = await _profileRepository.getUserProfile(userId);
    } catch (e) {
      debugPrint('Error loading current user profile: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// নির্দিষ্ট কোনো User ID দিয়ে প্রোফাইল ডাটা লোড করা
  Future<void> loadUserProfile(String userId) async {
    _isLoading = true;
    notifyListeners();

    try {
      _userProfile = await _profileRepository.getUserProfile(userId);
    } catch (e) {
      debugPrint('Error loading user profile: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// প্রোফাইল ইনফরমেশন (যেমন: নাম ইত্যাদি) আপডেট করা
  Future<void> updateUserProfile(User updatedProfile) async {
    _isLoading = true;
    notifyListeners();

    try {
      await _profileRepository.updateUserProfile(updatedProfile);
      _userProfile = updatedProfile;
    } catch (e) {
      debugPrint('Error updating user profile: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// গ্যালারি বা ক্যামেরা থেকে ছবি পিক করে প্রোফাইল পিকচার হিসেবে আপলোড করা
  Future<void> updateProfileImage(ImageSource source) async {
    try {
      final file = await ImagePickerUtil().pickImage(source: source);
      if (file == null) return;

      _isUploadingImage = true;
      notifyListeners();

      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) throw Exception('User not authenticated');

      await _profileRepository.uploadProfileImage(
        userId: userId,
        imageFile: file,
      );

      await loadUserProfile(userId);
    } catch (e) {
      debugPrint('Error updating profile image: $e');
    } finally {
      _isUploadingImage = false;
      notifyListeners();
    }
  }

  /// ইউজারের নিজস্ব কুইজ রেজাল্ট বা পার্সোনাল হিস্ট্রি ফেচ করা
  Future<void> loadPersonalResults() async {
    _isLoadingPersonalHistory = true;
    notifyListeners();
    try {
      final userId = FirebaseAuth.instance.currentUser?.uid ?? 'anonymous';
      final results = await _profileRepository.getPersonalResults(
        userId,
        _selectedProfileFilter,
      );
      debugPrint(
        'Loaded ${results.length} scoreboard entries for user $userId with filter $selectedProfileFilter',
      );
      _personalHistory.clear();
      _personalHistory.addAll(results);
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading personal results: $e');
    } finally {
      _isLoadingPersonalHistory = false;
      notifyListeners();
    }
  }
}
import 'package:firebase_auth/firebase_auth.dart' hide User; // User কনফ্লিক্ট দূর করার জন্য
import 'package:flutter/foundation.dart';

import '../models/user.dart';
import '../repository/auth_repository.dart';
import '../services/bdapps_service.dart';

/// Authentication + BDApps subscription provider.
///
/// Email/Google login methods are kept for backwards compatibility, but the
/// primary flow now goes through SMS subscription:
///   requestOtp() → verifyOtp() → isSubscribed == true.
class AuthProvider extends ChangeNotifier {
  AuthProvider({
    AuthRepository? authRepository,
    BdAppsService? bdAppsService,
  })  : _authRepository = authRepository ?? AuthRepository(),
        _bdAppsService = bdAppsService ?? BdAppsService();

  final AuthRepository _authRepository;
  final BdAppsService _bdAppsService;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  User? _user;
  User? get user => _user;

  // ───────── SMS subscription state ─────────
  String? _mobileNumber;
  String? get mobileNumber => _mobileNumber;

  String? _lastReferenceNo;
  String? get lastReferenceNo => _lastReferenceNo;

  bool _isSubscribed = false;
  bool get isSubscribed => _isSubscribed;

  // ───────── BDApps config (read-only) ─────────
  Map<String, String> get bdAppsConfig => {
        'appName': BdAppsConfig.appName,
        'gateway': BdAppsConfig.gatewayBaseUrl,
      };

  // ───────── Email / Google (legacy) ─────────

  Future<void> signup(String email, String password) async {
    _setLoading(true);
    try {
      _user = await _authRepository.signup(email, password);
      debugPrint('User signed up: ${_user?.uid}');
      _setErrorMessage(null);
    } catch (e) {
      _setErrorMessage(e.toString());
    } finally {
      _setLoading(false);
    }
  }

  Future<void> login(String email, String password) async {
    _setLoading(true);
    try {
      _user = await _authRepository.login(email, password);
      debugPrint('User logged in: ${_user?.uid}');
      _setErrorMessage(null);
    } catch (e) {
      _setErrorMessage(e.toString());
    } finally {
      _setLoading(false);
    }
  }

  Future<void> signInWithGoogle() async {
    _setLoading(true);
    try {
      final GoogleAuthProvider googleProvider = GoogleAuthProvider();
      await FirebaseAuth.instance.signInWithPopup(googleProvider);
      _setErrorMessage(null);
    } catch (e) {
      _setErrorMessage(e.toString());
    } finally {
      _setLoading(false);
    }
  }

  /// Alias used by LoginPage.
  Future<void> loginWithGoogle() => signInWithGoogle();

  Future<void> logout() async {
    _setLoading(true);
    try {
      await _authRepository.logout();
      _user = null;
      _setErrorMessage(null);
    } catch (e) {
      _setErrorMessage(e.toString());
    } finally {
      _setLoading(false);
    }
  }

  // ───────── SMS subscription (primary) ─────────

  /// Stores the mobile number and asks the v1 gateway to send an OTP.
  /// Returns `true` when BDApps accepted the request (S1000).
  Future<bool> requestOtp(String phoneNumber) async {
    _setLoading(true);
    _mobileNumber = phoneNumber;
    try {
      final response = await _bdAppsService.sendOtp(phoneNumber);
      if (response['success'] == true && response['referenceNo'] != null) {
        _lastReferenceNo = response['referenceNo'].toString();
        _setErrorMessage(null);
        return true;
      }
      _setErrorMessage(
        response['statusDetail'] ??
            response['message'] ??
            'OTP পাঠানো যায়নি, আবার চেষ্টা করুন।',
      );
      return false;
    } catch (e) {
      _setErrorMessage(e.toString());
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Verifies the OTP. On success flips `isSubscribed` to true.
  Future<bool> verifyOtp(String referenceNo, String otp) async {
    _setLoading(true);
    try {
      final response = await _bdAppsService.verifyOtp(referenceNo, otp);
      final ok = response['statusCode'] == 'S1000' ||
          response['subscriptionStatus'] == 'REGISTERED';
      if (ok) {
        _isSubscribed = true;
        _setErrorMessage(null);
      } else {
        _setErrorMessage(
          response['statusDetail'] ??
              response['message'] ??
              'OTP সঠিক নয়, আবার চেষ্টা করুন।',
        );
      }
      return ok;
    } catch (e) {
      _setErrorMessage(e.toString());
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// On app start — if we already know a phone number, ask BDApps
  /// whether the user is still subscribed.
  Future<void> refreshSubscriptionStatus() async {
    if (_mobileNumber == null || _mobileNumber!.isEmpty) return;
    _setLoading(true);
    try {
      final response = await _bdAppsService.checkSubscription(_mobileNumber!);
      _isSubscribed = response['isSubscribed'] == true ||
          response['subscriptionStatus'] == 'REGISTERED' ||
          response['statusCode'] == 'S1000';
      _setErrorMessage(null);
    } catch (e) {
      _setErrorMessage(e.toString());
    } finally {
      _setLoading(false);
    }
  }

  /// Profile page "Unsubscribe" button calls this.
  Future<bool> unsubscribe() async {
    if (_mobileNumber == null || _mobileNumber!.isEmpty) {
      _setErrorMessage('ফোন নম্বর পাওয়া যায়নি।');
      return false;
    }
    _setLoading(true);
    try {
      final response = await _bdAppsService.unsubscribe(_mobileNumber!);
      final ok = response['success'] == true ||
          response['statusCode'] == 'S1000' ||
          response['statusCode'] == 'E1356' ||
          response['statusCode'] == 'E1644' ||
          response['subscriptionStatus'] == 'UNREGISTERED';
      if (ok) {
        _isSubscribed = false;
        _setErrorMessage(null);
      } else {
        _setErrorMessage(
          response['statusDetail'] ??
              response['message'] ??
              'Unsubscribe ব্যর্থ হয়েছে।',
        );
      }
      return ok;
    } catch (e) {
      _setErrorMessage(e.toString());
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // ───────── internals ─────────

  /// Profile-page থেকে কল হয় যখন [SubscriptionProvider.unsubscribe]
  /// সফল হয়। AuthProvider-এর নিজস্ব `_isSubscribed` ফ্ল্যাগটিও false
  /// করে দেয় যাতে auth-ভিত্তিক গার্ডগুলো আপ টু ডেট থাকে।
  void markUnsubscribed() {
    if (_isSubscribed == false && _mobileNumber == null) return;
    _isSubscribed = false;
    _mobileNumber = null;
    _setErrorMessage(null);
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _setErrorMessage(String? value) {
    _errorMessage = value;
    notifyListeners();
  }
}
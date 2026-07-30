import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/bdapps_service.dart';

/// সাবস্ক্রিপশন ফ্লো-এর বিভিন্ন স্টেট
enum SubscriptionState { inputPhone, inputOtp, subscribed, error }

class SubscriptionProvider extends ChangeNotifier {
  final BdAppsService _bdAppsService = BdAppsService();

  SubscriptionState _state = SubscriptionState.inputPhone;
  SubscriptionState get state => _state;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String _errorMessage = '';
  String get errorMessage => _errorMessage;

  String _referenceNo = '';
  String _phoneNumber = '';
  String get phoneNumber => _phoneNumber; // প্রোফাইল বা অন্যান্য পেজে নম্বর পাওয়ার জন্য গেটার

  bool _isSubscribed = false;
  bool get isSubscribed => _isSubscribed;

  SubscriptionProvider() {
    _loadSubscriptionStatus();
  }

  /// অ্যাপ চালু হলে লোকাল স্টোরেজ (SharedPreferences) থেকে সাবস্ক্রিপশন স্ট্যাটাস এবং ফোন নম্বর চেক করা
  Future<void> _loadSubscriptionStatus() async {
    final prefs = await SharedPreferences.getInstance();
    _isSubscribed = prefs.getBool('isSubscribed') ?? false;
    _phoneNumber = prefs.getString('userPhone') ?? ''; // সেভ করা ফোন নম্বর লোড করা হলো

    if (_isSubscribed) {
      _state = SubscriptionState.subscribed;
      notifyListeners();
    }
  }

  /// bdapps সার্ভিস ব্যবহার করে মোবাইল নম্বরে OTP পাঠানো
  Future<void> sendOtp(String phoneNumber) async {
    _setLoading(true);
    _phoneNumber = phoneNumber;
    try {
      final response = await _bdAppsService.sendOtp(phoneNumber);

      final registerStatus = (response['registerStatus'] ?? '').toString().toUpperCase();
      final statusCode = (response['statusCode'] ?? '').toString();
      final isAlreadyRegistered =
          registerStatus == 'ALREADY_REGISTERED' || statusCode == 'E1351';

      if (isAlreadyRegistered) {
        // BDApps already knows this number as an active subscriber — this
        // is the common real-world case (fresh install / cleared app data /
        // reinstalled app) and it should mean "you're in", not "please
        // unsubscribe first". LandingPage's listener will take it from here
        // and navigate to /home once _state flips to subscribed.
        _state = SubscriptionState.subscribed;
        _isSubscribed = true;
        _errorMessage = '';
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('isSubscribed', true);
        await prefs.setString('userPhone', _phoneNumber);
      } else if ((response['success'] == true || statusCode == 'S1000') &&
          response['referenceNo'] != null &&
          response['referenceNo'].toString().isNotEmpty) {
        _referenceNo = response['referenceNo'].toString();
        _state = SubscriptionState.inputOtp;
        _errorMessage = '';
      } else {
        _state = SubscriptionState.error;
        _errorMessage = response['message'] ?? response['statusDetail'] ?? 'Failed to send OTP';
      }
    } catch (e) {
      _state = SubscriptionState.error;
      _errorMessage = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  /// ইউজারের ইনপুট দেওয়া OTP ভেরিফাই করা
  Future<void> verifyOtp(String otp) async {
    _setLoading(true);
    try {
      final response = await _bdAppsService.verifyOtp(_referenceNo, otp);

      if (response['statusCode'] == 'S1000' || response['subscriptionStatus'] == 'REGISTERED') {
        _state = SubscriptionState.subscribed;
        _isSubscribed = true;
        _errorMessage = '';

        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('isSubscribed', true);

        // 🔥 ওটিপি সফলভাবে ভেরিফাই হওয়ার পর ফোন নম্বরটি লোকাল স্টোরেজে সেভ করা হলো
        await prefs.setString('userPhone', _phoneNumber);
      } else {
        _errorMessage = response['statusDetail'] ?? response['message'] ?? 'Failed to verify OTP';
      }
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  /// লাইভ সার্ভার থেকে সাবস্ক্রিপশন একটিভ আছে কি না তা যাচাই করা
  Future<void> checkSubscriptionStatus() async {
    if (_phoneNumber.isEmpty) return;

    _setLoading(true);
    try {
      final response = await _bdAppsService.checkSubscription(_phoneNumber);

      if (response['isSubscribed'] == true || response['subscriptionStatus'] == 'REGISTERED' || response['statusCode'] == 'S1000') {
        _state = SubscriptionState.subscribed;
        _isSubscribed = true;

        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('isSubscribed', true);
        await prefs.setString('userPhone', _phoneNumber);
      } else {
        _isSubscribed = false;
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('isSubscribed', false);
      }
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  /// সাবস্ক্রিপশন ফর্ম রিসেট করা
  void reset() {
    _state = SubscriptionState.inputPhone;
    _errorMessage = '';
    notifyListeners();
  }

  /// Profile-page থেকে কল হয় unsubscribe-এর পর — AuthProvider-এর
  /// পাশাপাশি এই প্রোভাইডারের `_isSubscribed`/`_phoneNumber` এবং
  /// SharedPreferences-এর `isSubscribed`/`userPhone` ক্লিয়ার করে দেয়।
  /// রাউটার redirect এই `_isSubscribed` দেখে, তাই এটি false করা না
  /// হলে `/landing`-এ যাওয়া মাত্র আবার `/home`-এ ঠেলে দেবে।
  Future<void> markUnsubscribedLocally() async {
    _isSubscribed = false;
    _phoneNumber = '';
    _referenceNo = '';
    _state = SubscriptionState.inputPhone;
    _errorMessage = '';
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isSubscribed', false);
    await prefs.remove('userPhone');
    notifyListeners();
  }

  /// BDApps কে বলে দেওয়া যে ইউজার আর সাবস্ক্রাইব করতে চায় না।
  /// S1000 = success, E1356/E1644 = আগেই unregistered — দুটোই success হিসেবে গণ্য।
  ///
  /// [phoneNumber] is optional and, when given, overrides the provider's own
  /// [_phoneNumber]. Callers (e.g. ProfilePage) may resolve the number from a
  /// fallback source (like AuthProvider) when this provider's own field is
  /// empty — without this override, passing nothing here would silently
  /// short-circuit below and never actually call the API, even though a
  /// valid number was already known to the caller.
  Future<bool> unsubscribe({String? phoneNumber}) async {
    if (phoneNumber != null && phoneNumber.isNotEmpty) {
      _phoneNumber = phoneNumber;
    }
    if (_phoneNumber.isEmpty) {
      _errorMessage = 'ফোন নম্বর পাওয়া যায়নি, আবার চেষ্টা করুন।';
      notifyListeners();
      return false;
    }
    _setLoading(true);
    try {
      final response = await _bdAppsService.unsubscribe(_phoneNumber);
      final ok = response['success'] == true ||
          response['statusCode'] == 'S1000' ||
          response['statusCode'] == 'E1356' ||
          response['statusCode'] == 'E1644' ||
          response['subscriptionStatus'] == 'UNREGISTERED';

      if (ok) {
        _isSubscribed = false;
        _state = SubscriptionState.inputPhone;
        _referenceNo = '';
        _phoneNumber = '';
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('isSubscribed', false);
        await prefs.remove('userPhone'); // আনসাবস্ক্রাইব করলে নম্বর মুছে ফেলা হবে
        _errorMessage = '';
      } else {
        _errorMessage = response['statusDetail'] ??
            response['message'] ??
            'Unsubscribe ব্যর্থ হয়েছে, আবার চেষ্টা করুন।';
      }
      return ok;
    } catch (e) {
      _errorMessage = e.toString();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}
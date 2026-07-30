import 'package:firebase_auth/firebase_auth.dart' as fb_auth;
import 'package:google_sign_in/google_sign_in.dart';

import '../models/user.dart' as app_user; // Firebase User এর সাথে কনফ্লিক্ট এড়াতে অ্যালিয়াস ব্যবহার
import '../services/firestore_service.dart';

/// Firebase Auth wrapper। `AuthProvider` এই ক্লাসের মাধ্যমে
/// signup/login/Google login/logout করে, এবং Firestore-এ প্রোফাইল
/// ডেটা সিঙ্ক করে।
///
/// পূর্বে এই ক্লাস একটি আলাদা `AuthService` এর উপর নির্ভর করতো যেটা
/// `bdapps_api.dart` ইম্পোর্ট করতো — কিন্তু সেই helper ফাইলটি সরিয়ে
/// ফেলা হয়েছে, তাই এখন Firebase Auth কলগুলো সরাসরি এখানে থাকছে।
class AuthRepository {
  final fb_auth.FirebaseAuth _firebaseAuth;
  final FirestoreService _firestoreService;

  /// `google_sign_in` v7-এ পাবলিক কনস্ট্রাক্টর নেই। একটি singleton আছে
  /// (`GoogleSignIn.instance`) এবং অন্য কোনো মেথড কল করার আগে অবশ্যই
  /// একবার `await initialize(...)` কল করতে হবে।
  static final GoogleSignIn _googleSignIn = GoogleSignIn.instance;
  static bool _googleSignInInitialized = false;

  AuthRepository({
    fb_auth.FirebaseAuth? firebaseAuth,
    FirestoreService? firestoreService,
  })  : _firebaseAuth = firebaseAuth ?? fb_auth.FirebaseAuth.instance,
        _firestoreService = firestoreService ?? FirestoreService();

  /// সেশন/প্রোসেস লাইফ সাইকেলে প্রথম Google কল করার আগে একবার
  /// `initialize(...)` অ্যাওয়েট করা লাগে — এই helper সেটা বীমা করে।
  Future<void> _ensureGoogleSignInInitialized() async {
    if (_googleSignInInitialized) return;
    await _googleSignIn.initialize();
    _googleSignInInitialized = true;
  }

  fb_auth.FirebaseAuth get firebaseAuth => _firebaseAuth;

  /// নতুন অ্যাকাউন্ট তৈরি এবং ফায়ারস্টোরে প্রোফাইল ডেটা ইনিশিয়াল সেভ করার লজিক
  Future<app_user.User> signup(String email, String password) async {
    final credentials = await _firebaseAuth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    // ইমেইলের প্রথম অংশকে ডিফল্ট নাম হিসেবে নেওয়া (যেমন: john@email.com -> john)
    final user = app_user.User(
      uid: credentials.user?.uid ?? '',
      displayName: credentials.user?.email?.split('@')[0],
      email: credentials.user?.email ?? '',
      createdAt: DateTime.now(),
    );

    // ফায়ারস্টোর ডেটাবেসে প্রোফাইল সেভ করা
    await _firestoreService.saveUserProfile(user);
    return user;
  }

  /// ইমেইল-পাসওয়ার্ড দিয়ে লগইন করা এবং ফায়ারস্টোর প্রোফাইল আপডেট/সেভ করা
  Future<app_user.User> login(String email, String password) async {
    final credentials = await _firebaseAuth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    final user = app_user.User(
      uid: credentials.user?.uid ?? '',
      email: credentials.user?.email ?? '',
      displayName: credentials.user?.email?.split('@')[0],
    );

    await _firestoreService.saveUserProfile(user);
    return user;
  }

  /// গুগলের মাধ্যমে লগইন করা এবং ফায়ারস্টোর প্রোফাইল ডেটা সিঙ্ক করা
  Future<app_user.User> loginWithGoogle() async {
    await _ensureGoogleSignInInitialized();

    // `google_sign_in` v7-এ `signIn()` মেথড নেই — এর পরিবর্তে
    // `authenticate()` ব্যবহার হয়। ইউজার বাতিল করলে v7 একটি
    // `GoogleSignInException` থ্রো করে, যেটা caller-এ propagate হবে।
    final googleUser = await _googleSignIn.authenticate();
    final googleAuth = googleUser.authentication;
    // v7-এ `GoogleSignInAuthentication` শুধু `idToken` প্রদান করে;
    // Firebase-এ `accessToken` আর প্রয়োজন হয় না।
    final credential = fb_auth.GoogleAuthProvider.credential(
      idToken: googleAuth.idToken,
    );
    final credentials = await _firebaseAuth.signInWithCredential(credential);
    if (credentials.user == null) {
      throw Exception('Google sign in failed.');
    }

    final user = app_user.User(
      uid: credentials.user!.uid,
      email: credentials.user!.email ?? '',
      displayName: credentials.user!.email?.split('@')[0],
    );

    await _firestoreService.saveUserProfile(user);
    return user;
  }

  /// সেশন আউট বা লগআউট লজিক
  Future<void> logout() async {
    try {
      await _googleSignIn.signOut();
    } catch (_) {
      // Google sign-out failure shouldn't block Firebase sign-out.
    }
    await _firebaseAuth.signOut();
  }
}
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user.dart'; // এরর এড়াতে রিলেটিভ পাথ ব্যবহার করা হয়েছে
import '../models/scoreboard_entry.dart';

class FirestoreService {
  final FirebaseFirestore _firestore;

  // কনস্ট্রাক্টরের মাধ্যমে ফায়ারবেস ফায়ারস্টোর ইনিশিয়ালাইজ করা (টেস্টিং ফ্রেন্ডলি)
  FirestoreService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  /// ফায়ারস্টোরের 'scoreboard' কালেকশনে নতুন স্কোর এন্ট্রি সেভ করা
  Future<void> saveScoreboardEntry(ScoreboardEntry entry) async {
    await _firestore
        .collection('scoreboard')
        .doc(entry.id)
        .set(entry.toFirestore());
  }

  /// গ্লোবাল লিডারবোর্ডের ডেটা ফিল্টার এবং পেজিনেশনসহ তুলে আনা
  Future<QuerySnapshot> getGlobalScoreboard(
      DocumentSnapshot? startAfter,
      int limit, {
        String filter = 'all',
      }) async {
    Query query = _firestore
        .collection('scoreboard')
        .orderBy('correctCount', descending: true)
        .orderBy('timestamp', descending: true)
        .limit(limit);

    final now = DateTime.now();
    DateTime? start;
    if (filter == 'week') {
      // চলতি সপ্তাহের প্রথম দিন (সোমবার/রবিবার) থেকে ফিল্টার
      start = DateTime(now.year, now.month, now.day - now.weekday + 1);
    } else if (filter == 'month') {
      // চলতি মাসের ১ তারিখ থেকে ফিল্টার
      start = DateTime(now.year, now.month, 1);
    }

    if (start != null) {
      query = query.where(
        'timestamp',
        isGreaterThanOrEqualTo: Timestamp.fromDate(start),
      );
    }

    // স্ক্রোল ডাউন করলে পরবর্তী ডেটা লোড করার জন্য পেজিনেশন লজিক
    if (startAfter != null) {
      query = query.startAfterDocument(startAfter);
    }

    return await query.get();
  }

  /// নির্দিষ্ট কোনো ইউজারের খেলার হিস্ট্রি ফিল্টারসহ তুলে আনা
  Future<List<ScoreboardEntry>> getUserScoreboard(
      String userId, {
        String filter = 'Monthly',
      }) async {
    Query query = _firestore
        .collection('scoreboard')
        .where('userId', isEqualTo: userId);

    final now = DateTime.now();
    if (filter == 'Daily') {
      final start = DateTime(now.year, now.month, now.day);
      query = query.where('timestamp', isGreaterThanOrEqualTo: start);
    } else if (filter == 'Monthly') {
      final start = DateTime(now.year, now.month, 1);
      query = query.where('timestamp', isGreaterThanOrEqualTo: start);
    } else if (filter == 'Yearly') {
      final start = DateTime(now.year, 1, 1);
      query = query.where('timestamp', isGreaterThanOrEqualTo: start);
    }

    final snapshot = await query.orderBy('timestamp', descending: true).get();

    return snapshot.docs.map((doc) {
      final data = doc.data() as Map<String, dynamic>;
      data['id'] = doc.id; // ডক আইডি ডেটার সাথে যুক্ত করা
      return ScoreboardEntry.fromFirestore(data);
    }).toList();
  }

  /// নির্দিষ্ট ইউজারের সর্বোচ্চ স্কোর (High Score) কত তা বের করা
  Future<int> getUserHighScore(String userId) async {
    final snapshot = await _firestore
        .collection('scoreboard')
        .where('userId', isEqualTo: userId)
        .orderBy('correctCount', descending: true)
        .limit(1)
        .get();

    if (snapshot.docs.isNotEmpty) {
      final data = snapshot.docs.first.data();
      return data['correctCount'] as int? ?? 0;
    }
    return 0;
  }

  /// কোনো স্কোরবোর্ড এন্ট্রি আপডেট করার জন্য
  Future<void> updateScoreboardEntry(
      String resultId,
      ScoreboardEntry updatedResult,
      ) async {
    await _firestore
        .collection('scoreboard')
        .doc(resultId)
        .update(updatedResult.toFirestore());
  }

  /// কোনো স্কোরবোর্ড এন্ট্রি ডিলিট করার জন্য
  Future<void> deleteScoreboardEntry(String resultId) async {
    await _firestore.collection('scoreboard').doc(resultId).delete();
  }

  /// ইউজারের প্রোফাইল ফায়ারস্টোরে সেভ করা (থাকলে আপডেট, না থাকলে নতুন তৈরি)
  Future<void> saveUserProfile(User user) async {
    final userRef = _firestore.collection('users').doc(user.uid);
    final userDoc = await userRef.get();

    if (userDoc.exists) {
      await userRef.update(user.toMap());
    } else {
      await userRef.set(user.toMap());
    }
  }

  /// ফায়ারস্টোর থেকে ইউজারের প্রোফাইল ডাটা তুলে আনা
  Future<User?> getUserProfile(String userId) async {
    final doc = await _firestore.collection('users').doc(userId).get();
    if (doc.exists && doc.data() != null) {
      return User.fromMap(doc.data()!);
    }
    return null;
  }

  /// ইউজারের প্রোফাইল আপডেট করা (merge: true দিলে বিদ্যমান অন্য ফিল্ড সুরক্ষিত থাকে)
  Future<void> updateUserProfile(User profile) async {
    final userRef = _firestore.collection('users').doc(profile.uid);
    await userRef.set(profile.toMap(), SetOptions(merge: true));
  }

  /// এআই (AI) দিয়ে জেনারেট করা কুইজ ফায়ারস্টোরে সেভ করে রাখা
  Future<void> saveGeneratedQuiz(String category, List<dynamic> questionsJson) async {
    await _firestore.collection('generated_quizzes').add({
      'category': category,
      'questions': questionsJson,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }
}
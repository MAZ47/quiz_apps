import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/scoreboard_entry.dart';
import '../services/firestore_service.dart';
import '../services/hive_storage_service.dart';

/// পেজিনেশনের জন্য কাস্টম ডাটা হোল্ডার ক্লাস
class PaginatedScoreboardResult {
  final List<ScoreboardEntry> entries;
  final DocumentSnapshot? lastDoc;

  PaginatedScoreboardResult(this.entries, this.lastDoc);
}

class ScoreboardRepository {
  final FirestoreService _firestoreService;
  final HiveStorageService _hiveStorageService;

  ScoreboardRepository({
    FirestoreService? firestoreService,
    HiveStorageService? hiveStorageService,
  })  : _firestoreService = firestoreService ?? FirestoreService(),
        _hiveStorageService = hiveStorageService ?? HiveStorageService();

  /// ফায়ারস্টোর ও লোকাল হাইভ দুই জায়গাতেই স্কোর সেভ করা
  Future<void> addEntry(ScoreboardEntry entry) async {
    await _firestoreService.saveScoreboardEntry(entry);
    await _hiveStorageService.saveScoreEntry(entry);
  }

  /// গ্লোবাল লিডারবোর্ড থেকে পেজিনেশন অনুযায়ী স্কোর ফেচ করা
  Future<PaginatedScoreboardResult> getGlobalScoreboard(
      DocumentSnapshot? startAfter, int limit, String filter) async {
    final snapshot = await _firestoreService.getGlobalScoreboard(
      startAfter,
      limit,
      filter: filter,
    );

    DocumentSnapshot? lastDoc;
    List<ScoreboardEntry> entries = [];

    if (snapshot.docs.isNotEmpty) {
      lastDoc = snapshot.docs.last;
      entries = snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id; // ডকুমেন্ট আইডি যুক্ত করা
        return ScoreboardEntry.fromFirestore(data);
      }).toList();
    }

    return PaginatedScoreboardResult(entries, lastDoc);
  }

  /// নির্দিষ্ট কোনো ফলাফল ডাটাবেস থেকে ডিলিট করা
  Future<void> deleteResult(String resultId) async {
    await _firestoreService.deleteScoreboardEntry(resultId);
  }
}
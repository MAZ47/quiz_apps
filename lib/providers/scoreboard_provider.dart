import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/quiz_result.dart';
import '../models/scoreboard_entry.dart';
import '../repository/scoreboard_repository.dart';

class ScoreboardProvider extends ChangeNotifier {
  final ScoreboardRepository _repository;

  final List<ScoreboardEntry> _history = [];
  bool _isLoadingHistory = false;
  bool _hasMoreGlobalScores = true;
  DocumentSnapshot? _lastDoc;
  String _selectedScoreboardFilter = 'all';

  ScoreboardProvider({ScoreboardRepository? repository})
      : _repository = repository ?? ScoreboardRepository();

  // গেটার্স
  List<ScoreboardEntry> get history => _history;
  bool get isLoading => _isLoadingHistory;
  bool get hasMoreGlobalScores => _hasMoreGlobalScores;
  String get selectedScoreboardFilter => _selectedScoreboardFilter;

  // ফিল্টার সেট করা (all, week, month ইত্যাদি)
  set selectedScoreboardFilter(String filter) {
    _selectedScoreboardFilter = filter;
    notifyListeners();
    loadHistory(refresh: true);
  }

  /// স্কোরবোর্ড হিস্ট্রি লোড করা
  Future<void> loadHistory({bool refresh = false}) async {
    try {
      fetchNextGlobalPage(refresh: refresh);
    } catch (e) {
      debugPrint('Error loading scoreboard history: $e');
    } finally {
      _isLoadingHistory = false;
      notifyListeners();
    }
  }

  /// নতুন স্কোর এন্ট্রি সেভ করা
  Future<void> addEntry(ScoreboardEntry entry) async {
    try {
      await _repository.addEntry(entry);
      await loadHistory();
    } catch (e) {
      debugPrint('Error saving scoreboard entry: $e');
    }
  }

  /// কুইজ গেম শেষ হলে ফলাফল থেকে স্কোরবোর্ড এন্ট্রি বানিয়ে সেভ করা
  Future<void> saveQuizResult(QuizResult result) async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      final entry = ScoreboardEntry(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        categoryName: result.categoryName,
        correctCount: result.correctCount,
        totalQuestions: result.totalQuestions,
        timestamp: result.timestamp,
        userId: currentUser?.uid ?? 'anonymous',
        displayName: currentUser?.displayName ?? 'Anonymous',
      );
      await addEntry(entry);
    } catch (e) {
      debugPrint('Error saving quiz result: $e');
    }
  }

  /// গ্লোবাল লিডারবোর্ডের পরবর্তী পেজের ডেটা লোড করা (Pagination)
  Future<void> fetchNextGlobalPage({bool refresh = false}) async {
    if (_isLoadingHistory) return;
    if (!refresh && !_hasMoreGlobalScores) return;

    if (refresh) {
      _history.clear();
      _lastDoc = null;
      _hasMoreGlobalScores = true;
    }

    _isLoadingHistory = true;
    Future.microtask(() => notifyListeners());

    try {
      final result = await _repository.getGlobalScoreboard(
        _lastDoc,
        10,
        _selectedScoreboardFilter,
      );

      if (result.entries.isNotEmpty) {
        _lastDoc = result.lastDoc;
        _history.addAll(result.entries);
      }

      if (result.entries.length < 10) {
        _hasMoreGlobalScores = false;
      }
    } catch (e) {
      debugPrint('Error fetching global scoreboard: $e');
    } finally {
      _isLoadingHistory = false;
      notifyListeners();
    }
  }

  /// কোনো নির্দিষ্ট স্কোর এন্ট্রি ডিলিট করা
  Future<void> deleteResult(String resultId) async {
    try {
      await _repository.deleteResult(resultId);
      await loadHistory(); // ডিলিটের পর লোকাল হিস্ট্রি রিফ্রেশ
    } catch (e) {
      debugPrint('Error deleting scoreboard entry: $e');
    }
  }

  /// পুল-টু-রিফ্রেশ এর জন্য
  Future<void> onRefreshGlobalScores() async {
    await fetchNextGlobalPage(refresh: true);
  }
}
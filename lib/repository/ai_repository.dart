import 'package:flutter/foundation.dart';
import '../models/question.dart';
import '../services/ai_service.dart';

class AiRepository {
  AiRepository({AiService? aiService})
      : aiService = aiService ?? AiService();

  final AiService aiService;

  /// AI চ্যাটের জন্য স্ট্রিম রেসপন্স সার্ভিস থেকে রিলে করা
  Stream<String> sendMessageStream(String text) {
    return aiService.sendMessageStream(text);
  }

  /// ভুল উত্তরগুলোর ব্যাচ এক্সপ্ল্যানেশন সার্ভিস থেকে পাওয়া
  Future<Map<int, String>?> generateExplanationsBatch(
      List<Map<String, dynamic>> wrongAnswers,
      ) {
    return _guarded(() => aiService.generateExplanationsBatch(wrongAnswers));
  }

  /// AI কুইজ জেনারেট সার্ভিস কল করা
  Future<List<Question>?> generateQuiz(String prompt) {
    return _guarded(() => aiService.generateQuiz(prompt));
  }

  /// Wraps a call so API errors are translated into friendly Bengali messages.
  Future<T> _guarded<T>(Future<T> Function() body) async {
    try {
      return await body();
    } catch (e, st) {
      debugPrint('AiRepository: error → $e\n$st');
      throw Exception('AI সার্ভিসে সমস্যা হয়েছে, আবার চেষ্টা করুন।');
    }
  }
}
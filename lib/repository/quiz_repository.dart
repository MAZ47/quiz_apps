import '../models/question.dart';
import '../services/api_client.dart';

class QuizRepository {
  final ApiClient _apiClient;

  // কনস্ট্রাক্টরের মাধ্যমে এপিআই ক্লায়েন্ট ইনিশিয়ালাইজ করা (টেস্টিং ফ্রেন্ডলি)
  QuizRepository({ApiClient? apiClient}) : _apiClient = apiClient ?? ApiClient();

  /// এপিআই ক্লায়েন্টের মাধ্যমে ব্যাকএন্ড থেকে প্রশ্ন নিয়ে আসার মেথড
  Future<List<Question>> fetchQuestions({
    int amount = 10,
    String difficulty = 'medium',
  }) async {
    return await _apiClient.fetchQuestions(amount: amount, difficulty: difficulty);
  }
}
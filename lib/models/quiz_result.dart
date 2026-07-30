import 'question.dart';

class QuizResult {
  final String? id;                 // ফায়ারস্টোর ডক আইডি (ঐচ্ছিক)
  final int totalQuestions;         // মোট কয়টি প্রশ্ন ছিল
  final int correctCount;           // কয়টি সঠিক উত্তর দিয়েছে
  final int score;                  // অর্জিত স্কোর
  final List<int?> selectedAnswers; // ইউজারের সিলেক্ট করা উত্তরের ইনডেক্স (null = স্কিপ/টাইম-আউট)
  final List<Question> questions;   // প্রশ্নের অবজেক্ট লিস্ট (রানটাইম ইউজের জন্য)
  final String categoryName;        // কুইজের ক্যাটাগরি নাম
  final DateTime timestamp;         // গেম খেলার সময়

  const QuizResult({
    this.id,
    required this.totalQuestions,
    required this.correctCount,
    required this.score,
    required this.selectedAnswers,
    required this.questions,
    required this.categoryName,
    required this.timestamp,
  });

  /// কুইজের নির্ভুলতার হার বা এক্যুরেসি (Accuracy) বের করার গেটার (যেমন: ০.৮ = ৮০%)
  double get accuracy =>
      totalQuestions == 0 ? 0 : correctCount / totalQuestions;

  // ফায়ারস্টোর ডেটাবেসে সেভ করার জন্য ম্যাপে রূপান্তর করার মেথড
  Map<String, dynamic> toFirestore() {
    return {
      'totalQuestions': totalQuestions,
      'correctCount': correctCount,
      'score': score,
      'selectedAnswers': selectedAnswers,
      'categoryName': categoryName,
      'timestamp': timestamp,
    };
  }

  // ফায়ারস্টোর থেকে আসা ডাটা থেকে QuizResult অবজেক্ট তৈরি করার ফ্যাক্টরি মেথড
  factory QuizResult.fromFirestore(Map<String, dynamic> data) {
    return QuizResult(
      id: data['id'] as String?,
      totalQuestions: data['totalQuestions'] ?? 0,
      correctCount: data['correctCount'] ?? 0,
      score: data['score'] ?? 0,
      selectedAnswers: List<int?>.from(data['selectedAnswers'] ?? []),
      questions: const [], // ফায়ারস্টোরে প্রশ্ন সেভ করা হয় না, তাই ডিফল্ট খালি লিস্ট
      categoryName: data['categoryName'] as String? ?? 'General Knowledge',
      // ফায়ারস্টোরের Timestamp থেকে Dart-এর DateTime-এ কনভার্ট করার লজিক
      timestamp: data['timestamp'] != null
          ? (data['timestamp'] as dynamic).toDate()
          : DateTime.now(),
    );
  }
}
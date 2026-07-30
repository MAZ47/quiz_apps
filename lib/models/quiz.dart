import 'question.dart';
import 'quiz_category.dart'; // এর পরের ফাইলে আমরা এটি তৈরি করব

class Quiz {
  final String name; // কুইজের নাম (যেমন: Flutter Basic Quiz)
  final QuizCategory category; // কুইজটা কোন ক্যাটাগরির (যেমন: Technology, History)
  final List<Question> questions; // এই কুইজের আন্ডারে থাকা সব প্রশ্নের লিস্ট

  Quiz({
    required this.name,
    required this.category,
    required this.questions,
  });
}
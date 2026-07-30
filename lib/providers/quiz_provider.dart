import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/question.dart';
import '../models/quiz_result.dart'; // কুইজ রেজাল্ট মডেল লিংক করা
import '../repository/quiz_repository.dart'; // কুইজ রেপোজিটরি লিংক করা

// কুইজের বিভিন্ন অবস্থা বা স্টেট ট্র্যাকিং এনালগ
enum QuizStatus { idle, active, finished }

class QuizProvider extends ChangeNotifier {
  static const int totalSeconds = 15; // প্রতিটি প্রশ্নের জন্য বরাদ্দ সময় ১৫ সেকেন্ড

  final QuizRepository _repository;

  QuizProvider({QuizRepository? repository})
      : _repository = repository ?? QuizRepository();

  List<Question> _questions = [];
  int _currentIndex = 0;
  List<int?> _selectedAnswers = [];
  int _correctCount = 0;
  int _secondsLeft = totalSeconds;
  QuizStatus _status = QuizStatus.idle;
  Timer? _timer;
  String _categoryName = 'General Knowledge';
  DateTime _startTime = DateTime.now();

  // গেটার্স (UI থেকে ডাটা রিড করার জন্য)
  List<Question> get questions => _questions;
  int get currentIndex => _currentIndex;
  List<int?> get selectedAnswers => _selectedAnswers;
  int get score => _correctCount;
  int get secondsLeft => _secondsLeft;
  QuizStatus get status => _status;
  String get categoryName => _categoryName;
  DateTime get startTime => _startTime;

  Question get currentQuestion => _questions[_currentIndex];
  bool get isLastQuestion => _currentIndex == _questions.length - 1;
  int? get currentAnswer => _selectedAnswers[_currentIndex];
  bool get hasAnswered => currentAnswer != null;

  void setCategoryName(String name) {
    _categoryName = name;
    notifyListeners();
  }

  // খেলার শেষে কুইজ রেজাল্ট অবজেক্ট জেনারেট করার গেটার
  QuizResult get result => QuizResult(
    totalQuestions: _questions.length,
    correctCount: _correctCount,
    score: _correctCount,
    selectedAnswers: List<int?>.from(_selectedAnswers),
    questions: List<Question>.from(_questions),
    categoryName: _categoryName,
    timestamp: _startTime,
  );

  /// রেপোজিটরি থেকে প্রশ্ন নিয়ে আসার মেথড
  Future<List<Question>> fetchQuestions({
    int amount = 10,
    String difficulty = 'medium',
  }) async {
    return await _repository.fetchQuestions(amount: amount, difficulty: difficulty);
  }

  // ইন্টারনেট বা ব্যাকএন্ড না থাকলে ব্যাকআপ হিসেবে ৬টি ডেমো প্রশ্ন
  static final List<Question> sampleQuestions = [
    Question(
      text: 'What is the capital of France?',
      options: ['Berlin', 'Madrid', 'Paris', 'Rome'],
      correctOptionIndex: 2,
      difficulty: 1,
    ),
    Question(
      text: 'Who wrote "To Kill a Mockingbird"?',
      options: ['Harper Lee', 'Mark Twain', 'Ernest Hemingway', 'F. Scott Fitzgerald'],
      correctOptionIndex: 0,
      difficulty: 2,
    ),
    Question(
      text: 'What is the largest planet in our solar system?',
      options: ['Earth', 'Jupiter', 'Mars', 'Saturn'],
      correctOptionIndex: 1,
      difficulty: 1,
    ),
    Question(
      text: 'Which element has the chemical symbol "O"?',
      options: ['Gold', 'Oxygen', 'Silver', 'Hydrogen'],
      correctOptionIndex: 1,
      difficulty: 1,
    ),
    Question(
      text: 'What year did the Berlin Wall fall?',
      options: ['1987', '1989', '1991', '1993'],
      correctOptionIndex: 1,
      difficulty: 3,
    ),
    Question(
      text: 'What is the capital of Germany?',
      options: ['Vienna', 'Zurich', 'Berlin', 'Hamburg'],
      correctOptionIndex: 2,
      difficulty: 1,
    ),
  ];

  /// কুইজ খেলা শুরু করার মেইন ফাংশন
  void startQuiz(List<Question>? questions) {
    _questions = questions ?? sampleQuestions;
    _currentIndex = 0;
    _correctCount = 0;
    _selectedAnswers = List.filled(_questions.length, null);
    _secondsLeft = totalSeconds;
    _status = QuizStatus.active;
    _startTime = DateTime.now();
    _startTimer();
    notifyListeners();
  }

  /// ইউজারের দেওয়া উত্তর প্রসেস করার লজিক
  void selectedAnswer(int answerIndex) {
    if (_status != QuizStatus.active || hasAnswered) return;

    _cancelTimer(); // উত্তর দেওয়ার সাথে সাথে টাইমার অফ হবে
    _selectedAnswers[_currentIndex] = answerIndex;

    // সঠিক উত্তরের ইনডেক্স মিললে স্কোর ১ বাড়বে
    if (answerIndex == currentQuestion.correctOptionIndex) {
      _correctCount++;
    }
    notifyListeners();

    // উত্তর দেখানোর জন্য ১ সেকেন্ড ওয়েট করে পরের প্রশ্নে যাবে
    Future.delayed(const Duration(seconds: 1), _advance);
  }

  // পরবর্তী প্রশ্ন লোড করার অথবা গেম শেষ করার ইন্টারনাল মেথড
  void _advance() {
    if (isLastQuestion) {
      _status = QuizStatus.finished;
      _cancelTimer();
      notifyListeners();
    } else {
      _currentIndex++;
      _startTimer();
      notifyListeners();
    }
  }

  // টাইমার চালু করার মেথড
  void _startTimer() {
    _secondsLeft = totalSeconds;
    _timer = Timer.periodic(const Duration(seconds: 1), _tick);
  }

  // প্রতি সেকেন্ডে টাইমার কমানোর লজিক
  void _tick(Timer timer) {
    if (_secondsLeft > 0) {
      _secondsLeft--;
      notifyListeners();
    } else {
      _cancelTimer();
      // সময় শেষ হয়ে গেলে অটোমেটিক ফাঁকা উত্তর সাবমিট করে এগিয়ে যাবে
      _advance();
    }
  }

  // টাইমার বন্ধ বা ক্যানসেল করার মেথড
  void _cancelTimer() {
    _timer?.cancel();
    _timer = null;
  }

  /// গেমের সব স্টেট রিসেট করে আগের অবস্থায় নিয়ে যাওয়া
  void reset() {
    _cancelTimer();
    _questions = [];
    _currentIndex = 0;
    _selectedAnswers = [];
    _correctCount = 0;
    _secondsLeft = totalSeconds;
    _status = QuizStatus.idle;
    notifyListeners();
  }

  @override
  void dispose() {
    _cancelTimer(); // মেমোরি লিক রোধ করতে ডিসপোজ করা
    super.dispose();
  }
}
class Question {
  final String text;
  final List<String> options;
  final int correctOptionIndex;
  final int difficulty;

  Question({
    required this.text,
    required this.options,
    required this.correctOptionIndex,
    this.difficulty = 2,
  });

  // API বা ফায়ারবেস থেকে আসা ম্যাপ ডাটাকে Dart অবজেক্টে রূপান্তর
  factory Question.fromJson(Map<String, dynamic> json) {
    String correctAnswer = json['correct_answer'] as String;
    List<String> incorrectAnswers = List<String>.from(
      json['incorrect_answers'] as List<dynamic>,
    );

    // সঠিক এবং ভুল অপশনগুলো একসাথে মিশিয়ে ওলোট-পালোট (Shuffle) করা
    List<String> allOptions = [correctAnswer, ...incorrectAnswers];
    allOptions.shuffle();

    // ওলোট-পালোট করার পর সঠিক উত্তরটা কত নম্বর ইনডেক্সে আছে তা বের করা
    int correctOptionIndex = allOptions.indexOf(correctAnswer);

    // টেক্সট ফরম্যাটের ডিফিকাল্টিকে ইন্টিজার (1, 2, 3) ভ্যালুতে কনভার্ট
    int difficulty;
    switch (json['difficulty'] as String) {
      case 'easy':
        difficulty = 1;
        break;
      case 'medium':
        difficulty = 2;
        break;
      case 'hard':
        difficulty = 3;
        break;
      default:
        difficulty = 2; // কিছু দেওয়া না থাকলে ডিফল্ট মিডিয়াম (2)
    }

    return Question(
      text: json['question'] as String,
      options: allOptions,
      correctOptionIndex: correctOptionIndex,
      difficulty: difficulty,
    );
  }

  // Dart অবজেক্টকে আবার ব্যাকএন্ডের চেনা ফরম্যাটে (Map) রূপান্তর
  Map<String, dynamic> toJson() {
    String difficultyString;
    switch (difficulty) {
      case 1:
        difficultyString = 'easy';
        break;
      case 3:
        difficultyString = 'hard';
        break;
      case 2:
      default:
        difficultyString = 'medium';
    }

    String correctAnswer = options[correctOptionIndex];
    List<String> incorrectAnswers = List.from(options)..removeAt(correctOptionIndex);

    return {
      'question': text,
      'correct_answer': correctAnswer,
      'incorrect_answers': incorrectAnswers,
      'difficulty': difficultyString,
    };
  }
}
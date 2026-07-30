import 'question.dart';

class ChatMessage {
  final String text;
  final bool isUser;
  final List<Question>? generatedQuiz;

  ChatMessage({
    required this.text,
    required this.isUser,
    this.generatedQuiz,
  });
}
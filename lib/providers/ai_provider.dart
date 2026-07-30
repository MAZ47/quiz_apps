import 'package:flutter/material.dart';
import '../models/chat_message.dart';
import '../repository/ai_repository.dart';

class AiProvider extends ChangeNotifier {
  final AiRepository aiRepository;

  AiProvider({AiRepository? aiRepository})
      : aiRepository = aiRepository ?? AiRepository();

  final List<ChatMessage> _messages = [];
  List<ChatMessage> get messages => _messages;

  bool _isGenerating = false;
  bool get isGenerating => _isGenerating;

  String _currentGeneratingText = '';
  String get currentGeneratingText => _currentGeneratingText;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  bool _isQuizGenerationMode = false;
  bool get isQuizGenerationMode => _isQuizGenerationMode;

  /// কুইজ জেনারেট মোড টগল করার মেথড
  void toggleQuizGenerationMode(bool value) {
    _isQuizGenerationMode = value;
    notifyListeners();
  }

  /// ইউজার মেসেজ পাঠালে সেটা চ্যাটে বা কুইজ জেনারেটরে প্রসেস করা
  void sendMessage(String text) {
    if (_isQuizGenerationMode) {
      _generateQuiz(text);
      return;
    }

    final trimmedText = text.trim();
    if (trimmedText.isEmpty || _isGenerating) return;

    _messages.add(ChatMessage(text: trimmedText, isUser: true));
    _isGenerating = true;
    _currentGeneratingText = '';
    _errorMessage = null;
    notifyListeners();

    try {
      final responseStream = aiRepository.sendMessageStream(trimmedText);
      responseStream.listen(
            (chunk) {
          if (chunk != null) {
            final dynamic dynamicChunk = chunk;
            // chunk সরাসরি String হতে পারে বা .text প্রপার্টিযুক্ত অবজেক্ট হতে পারে
            if (dynamicChunk is String) {
              _currentGeneratingText += dynamicChunk;
            } else {
              try {
                final textValue = dynamicChunk.text;
                if (textValue != null) {
                  _currentGeneratingText += textValue.toString();
                }
              } catch (_) {
                _currentGeneratingText += dynamicChunk.toString();
              }
            }
            notifyListeners();
          }
        },
        onError: (error) {
          _errorMessage = 'Error: $error';
          _messages.add(ChatMessage(text: _errorMessage!, isUser: false));
          _isGenerating = false;
          _currentGeneratingText = '';
          notifyListeners();
        },
        onDone: () {
          if (_errorMessage == null) {
            _messages.add(ChatMessage(text: _currentGeneratingText, isUser: false));
          }
          _isGenerating = false;
          _currentGeneratingText = '';
          notifyListeners();
        },
      );
    } catch (e) {
      _errorMessage = 'Error generating response.';
      _messages.add(ChatMessage(text: _errorMessage!, isUser: false));
      _isGenerating = false;
      _currentGeneratingText = '';
      notifyListeners();
    }
  }

  /// এআই দিয়ে নতুন কুইজ তৈরি করার প্রাইভেট মেথড
  void _generateQuiz(String prompt) async {
    final trimmedPrompt = prompt.trim();
    if (trimmedPrompt.isEmpty || _isGenerating) return;

    _messages.add(ChatMessage(text: 'Generate a quiz: $trimmedPrompt', isUser: true));
    _isGenerating = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final quiz = await aiRepository.generateQuiz(trimmedPrompt);
      if (quiz != null && quiz.isNotEmpty) {
        _messages.add(
          ChatMessage(
            text: 'I have generated a quiz for you!',
            isUser: false,
            generatedQuiz: quiz,
          ),
        );
      } else {
        _errorMessage = 'Failed to generate quiz or invalid format.';
        _messages.add(ChatMessage(text: _errorMessage!, isUser: false));
      }
    } catch (e) {
      _errorMessage = 'Error generating quiz: $e';
      _messages.add(ChatMessage(text: _errorMessage!, isUser: false));
    } finally {
      _isGenerating = false;
      notifyListeners();
    }
  }

  bool _isGeneratingExplanations = false;
  bool get isGeneratingExplanations => _isGeneratingExplanations;

  Map<int, String> _explanations = {};
  Map<int, String> get explanations => _explanations;

  /// কুইজের ভুল উত্তরের ব্যাখ্যা এআই থেকে ব্যাচ আকারে ফেচ করা
  Future<void> fetchExplanationsBatch(List<Map<String, dynamic>> wrongAnswers) async {
    if (wrongAnswers.isEmpty) return;
    _isGeneratingExplanations = true;
    _explanations = {};
    notifyListeners();

    final result = await aiRepository.generateExplanationsBatch(wrongAnswers);
    if (result != null) {
      _explanations = result;
    }
    _isGeneratingExplanations = false;
    notifyListeners();
  }
}
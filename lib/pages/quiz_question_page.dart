import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../app_route.dart';
import '../models/question.dart';
import '../providers/ai_provider.dart';
import '../providers/quiz_provider.dart';

class QuizQuestionPage extends StatefulWidget {
  final List<Question> questions;

  const QuizQuestionPage({super.key, required this.questions});

  @override
  State<QuizQuestionPage> createState() => _QuizQuestionPageState();
}

class _QuizQuestionPageState extends State<QuizQuestionPage> {
  late QuizProvider _quizProvider;

  @override
  void initState() {
    super.initState();
    _quizProvider = context.read<QuizProvider>();
    _quizProvider.addListener(_onQuizStatusChanged);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _quizProvider.startQuiz(widget.questions);
        debugPrint(
          '${widget.questions.length} questions loaded into QuizProvider',
        );
      }
    });
  }

  void _onQuizStatusChanged() {
    if (_quizProvider.status == QuizStatus.finished) {
      if (mounted) {
        context.go(AppRoute.quizResult, extra: _quizProvider.result);
      }
    }
  }

  @override
  void dispose() {
    _quizProvider.removeListener(_onQuizStatusChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Consumer<QuizProvider>(
      builder: (context, quiz, _) {
        if (quiz.questions.isEmpty) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        return Scaffold(
          appBar: AppBar(
            title: Text(
              'Question ${quiz.currentIndex + 1} of ${quiz.questions.length}',
            ),
            backgroundColor: colorScheme.inversePrimary,
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: 12.0),
                child: Chip(
                  avatar: const Icon(Icons.star, size: 18),
                  label: Text(
                    '${quiz.score} pts',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
          body: Column(
            children: [
              LinearProgressIndicator(
                value: quiz.secondsLeft / QuizProvider.totalSeconds,
                minHeight: 6,
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          const Icon(Icons.timer_outlined, size: 18),
                          const SizedBox(width: 4),
                          AnimatedSwitcher(
                            duration: const Duration(milliseconds: 300),
                            child: Text(
                              '${quiz.secondsLeft} s',
                              key: ValueKey<int>(quiz.secondsLeft),
                              style: Theme.of(context).textTheme.titleSmall,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Hero(
                            tag: 'category-${quiz.categoryName}',
                            child: Material(
                              type: MaterialType.transparency,
                              child: Text(
                                quiz.categoryName,
                                style: Theme.of(context)
                                    .textTheme
                                    .titleLarge
                                    ?.copyWith(fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                          Chip(
                            label: const Text('Easy'),
                            backgroundColor: Colors.green.shade100,
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        quiz.currentQuestion.text,
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const Divider(height: 32, thickness: 1.5),
                      ...List.generate(
                        quiz.currentQuestion.options.length,
                            (index) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12.0),
                            child: SizedBox(
                              width: double.infinity,
                              child: OutlinedButton(
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 14,
                                    horizontal: 16,
                                  ),
                                  alignment: Alignment.centerLeft,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                onPressed: () {
                                  quiz.selectedAnswer(index);
                                },
                                child: Text(
                                  quiz.currentQuestion.options[index],
                                  style: const TextStyle(fontSize: 16),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          floatingActionButton: Semantics(
            label: 'Request AI Hint',
            child: FloatingActionButton.extended(
              heroTag: 'quiz_ai_hint_fab',
              tooltip: 'Request AI Hint',
              onPressed: () {
                HapticFeedback.lightImpact();
                _showHintDialog(context, quiz.currentQuestion);
              },
              icon: const Icon(Icons.lightbulb_outline),
              label: const Text('Hint'),
            ),
          ),
        );
      },
    );
  }

  void _showHintDialog(BuildContext context, Question currentQuestion) {
    showDialog(
      context: context,
      builder: (context) {
        return _HintDialog(currentQuestion: currentQuestion);
      },
    );
  }
}

class _HintDialog extends StatefulWidget {
  final Question currentQuestion;

  const _HintDialog({required this.currentQuestion});

  @override
  State<_HintDialog> createState() => _HintDialogState();
}

class _HintDialogState extends State<_HintDialog> {
  StreamSubscription<dynamic>? _subscription;
  String _hintText = '';
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchAiHint();
  }

  void _fetchAiHint() {
    final aiRepo = context.read<AiProvider>().aiRepository;
    final prompt =
        'Give a very short, subtle hint for this quiz question without revealing the answer. Question: ${widget.currentQuestion.text}, Options: ${widget.currentQuestion.options.join(', ')}.';

    _subscription = aiRepo.sendMessageStream(prompt).listen(
          (chunk) {
        if (mounted) {
          setState(() {
            final dynamic dynamicChunk = chunk;
            if (dynamicChunk is String) {
              _hintText += dynamicChunk;
            } else if (dynamicChunk != null) {
              try {
                final text = dynamicChunk.text;
                if (text != null) {
                  _hintText += text.toString();
                }
              } catch (_) {
                _hintText += dynamicChunk.toString();
              }
            }
          });
        }
      },
      onError: (error) {
        if (mounted) {
          setState(() {
            _errorMessage = 'Failed to generate hint. Please try again.';
          });
        }
      },
    );
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.lightbulb, color: Colors.amber),
          SizedBox(width: 8),
          Text('AI Hint'),
        ],
      ),
      content: _errorMessage != null
          ? Text(
        _errorMessage!,
        style: const TextStyle(color: Colors.redAccent),
      )
          : _hintText.isEmpty
          ? const SizedBox(
        height: 60,
        child: Center(
          child: CircularProgressIndicator(),
        ),
      )
          : SingleChildScrollView(
        child: Text(
          _hintText,
          style: const TextStyle(fontSize: 15, height: 1.4),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Close'),
        ),
      ],
    );
  }
}
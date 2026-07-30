// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lottie/lottie.dart';
import 'package:provider/provider.dart';
import 'package:quiz_apps/app_route.dart';
import 'package:quiz_apps/models/quiz_result.dart';
import 'package:quiz_apps/providers/ai_provider.dart';
import 'package:quiz_apps/providers/quiz_provider.dart';
import 'package:quiz_apps/providers/scoreboard_provider.dart';
import 'package:quiz_apps/widgets/score_circle.dart';
import 'package:share_plus/share_plus.dart';

class ResultPage extends StatefulWidget {
  final QuizResult result;

  const ResultPage({super.key, required this.result});

  @override
  State<ResultPage> createState() => _ResultPageState();
}

class _ResultPageState extends State<ResultPage> {
  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      // Save the quiz score to local scoreboard
      context.read<ScoreboardProvider>().saveQuizResult(widget.result);

      // Collect wrong answers for AI explanations
      final wrongAnswers = <Map<String, dynamic>>[];
      for (var i = 0; i < widget.result.questions.length; i++) {
        final q = widget.result.questions[i];
        final selected = widget.result.selectedAnswers[i];
        final isSkipped = selected == null;
        final isCorrect = selected == q.correctOptionIndex;

        if (!isSkipped && !isCorrect) {
          wrongAnswers.add({
            'index': i,
            'question': q.text,
            'selectedAnswer': q.options[selected],
            'correctAnswer': q.options[q.correctOptionIndex],
          });
        }
      }

      if (wrongAnswers.isNotEmpty) {
        context.read<AiProvider>().fetchExplanationsBatch(wrongAnswers);
      }
    });
  }

  int get _skippedCount =>
      widget.result.selectedAnswers.where((a) => a == null).length;

  void _shareScore() {
    SharePlus.instance.share(
      ShareParams(
        text:
        'Check out my quiz score: ${widget.result.score}/${widget.result.totalQuestions} in category "${widget.result.categoryName}"! Can you beat me?',
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final result = widget.result;
    final colorScheme = Theme.of(context).colorScheme;
    final accuracy = result.accuracy;

    final (scoreColor, scoreLabel, _) = accuracy >= 0.7
        ? (Colors.green, 'Excellent!', Icons.emoji_events)
        : accuracy >= 0.5
        ? (Colors.orange, 'Good Job!', Icons.thumb_up)
        : (Colors.red, 'Keep Practicing', Icons.refresh);

    final wrongCount =
        result.totalQuestions - result.correctCount - _skippedCount;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: colorScheme.inversePrimary,
        title: const Text('Quiz Results'),
        automaticallyImplyLeading: false,
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              scoreColor.withValues(alpha: 0.15),
              scoreColor.withValues(alpha: 0.05),
            ],
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── Top Celebration Animation ────────────────────────────────
              Center(
                child: Transform.scale(
                  scale: 1.5,
                  child: Lottie.network(
                    'https://lottie.host/62f15475-3f56-4f84-8906-116af7888159/5e016EA2YU.json',
                    width: 100,
                    height: 100,
                    repeat: false,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Center(
                child: Text(
                  scoreLabel,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: scoreColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Center(
                child: ScoreCircle(result: result, color: scoreColor),
              ),
              const SizedBox(height: 20),

              // ── Score Statistics Row ──────────────────────────────────────
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _StatPill(
                    icon: Icons.check_circle,
                    label: 'Correct',
                    value: '${result.correctCount}',
                    color: Colors.green,
                  ),
                  _StatPill(
                    icon: Icons.cancel,
                    label: 'Wrong',
                    value: '$wrongCount',
                    color: Colors.red,
                  ),
                  _StatPill(
                    icon: Icons.timer_off,
                    label: 'Skipped',
                    value: '$_skippedCount',
                    color: Colors.grey,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextButton.icon(
                onPressed: _shareScore,
                icon: const Icon(Icons.share, size: 18),
                label: const Text('Share your score'),
              ),
              const SizedBox(height: 16),

              // ── Answer Review Header ─────────────────────────────────────
              Text(
                'Answer Review',
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),

              // ── Questions List Review ─────────────────────────────────────
              ...List.generate(result.questions.length, (i) {
                final q = result.questions[i];
                final selected = result.selectedAnswers[i];
                final isCorrect = selected == q.correctOptionIndex;
                final isSkipped = selected == null;

                return Padding(
                  padding: const EdgeInsets.only(bottom: 12.0),
                  child: Card(
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(
                        color: isSkipped
                            ? Colors.grey.shade300
                            : isCorrect
                            ? Colors.green.shade200
                            : Colors.red.shade200,
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                isSkipped
                                    ? Icons.timer_off_outlined
                                    : isCorrect
                                    ? Icons.check_circle_outline
                                    : Icons.cancel_outlined,
                                color: isSkipped
                                    ? Colors.grey
                                    : isCorrect
                                    ? Colors.green
                                    : Colors.red,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Q${i + 1}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                              const Spacer(),
                              if (isSkipped)
                                const _ReviewBadge(
                                  label: 'Skipped',
                                  color: Colors.grey,
                                )
                              else if (isCorrect)
                                const _ReviewBadge(
                                  label: '+1 pt',
                                  color: Colors.green,
                                )
                              else
                                const _ReviewBadge(
                                  label: 'Wrong',
                                  color: Colors.red,
                                ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            q.text,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 15,
                            ),
                          ),
                          const SizedBox(height: 10),
                          if (!isSkipped && !isCorrect) ...[
                            _AnswerRow(
                              prefix: 'Your answer',
                              text: q.options[selected],
                              color: Colors.red.shade700,
                            ),
                            const SizedBox(height: 4),
                          ],
                          _AnswerRow(
                            prefix: 'Correct answer',
                            text: q.options[q.correctOptionIndex],
                            color: Colors.green.shade700,
                          ),
                          if (!isSkipped && !isCorrect) ...[
                            const SizedBox(height: 12),
                            _AiExplanationWidget(
                              questionIndex: i,
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                );
              }),

              const SizedBox(height: 16),

              // ── Action Buttons ───────────────────────────────────────────
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      onPressed: () {
                        context.read<QuizProvider>().reset();
                        context.go(AppRoute.home);
                      },
                      icon: const Icon(Icons.home_outlined),
                      label: const Text('Home'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton.icon(
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      onPressed: () {
                        context.read<QuizProvider>().startQuiz(null);
                        context.go(AppRoute.quizQuestion);
                      },
                      icon: const Icon(Icons.replay),
                      label: const Text('Play Again'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatPill extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatPill({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: color, size: 22),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
        ),
      ],
    );
  }
}

class _ReviewBadge extends StatelessWidget {
  final String label;
  final Color color;

  const _ReviewBadge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          color: color,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

class _AnswerRow extends StatelessWidget {
  final String prefix;
  final String text;
  final Color color;

  const _AnswerRow({
    required this.prefix,
    required this.text,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$prefix: ',
          style: TextStyle(
            fontSize: 13,
            color: color,
            fontWeight: FontWeight.w600,
          ),
        ),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 13,
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}

class _AiExplanationWidget extends StatelessWidget {
  final int questionIndex;

  const _AiExplanationWidget({
    required this.questionIndex,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<AiProvider>(
      builder: (context, aiProvider, child) {
        if (aiProvider.isGeneratingExplanations) {
          return const Row(
            children: [
              SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              SizedBox(width: 8),
              Text(
                'Generating AI explanation...',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          );
        }

        final explanation = aiProvider.explanations[questionIndex];
        if (explanation == null || explanation.isEmpty) {
          return const SizedBox.shrink();
        }

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.blue.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.blue.withValues(alpha: 0.2)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.auto_awesome, color: Colors.blue, size: 16),
                  const SizedBox(width: 6),
                  Text(
                    'AI Explanation',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue.shade800,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                explanation,
                style: TextStyle(
                  fontSize: 12,
                  height: 1.4,
                  color: Colors.grey.shade900,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
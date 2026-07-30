import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../app_route.dart';
import '../models/question.dart';
import '../providers/quiz_provider.dart';

class QuizLoadingPage extends StatefulWidget {
  const QuizLoadingPage({super.key});

  @override
  State<QuizLoadingPage> createState() => _QuizLoadingPageState();
}

class _QuizLoadingPageState extends State<QuizLoadingPage> {
  late Future<List<Question>> _questionsFuture;
  bool _hasNavigated = false;

  @override
  void initState() {
    super.initState();
    _fetchQuestions();
  }

  void _fetchQuestions() {
    setState(() {
      _hasNavigated = false;
      _questionsFuture = context.read<QuizProvider>().fetchQuestions();
    });
  }

  void _navigateToQuiz(List<Question> questions) {
    if (_hasNavigated) return;
    _hasNavigated = true;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.replace(AppRoute.quizQuestion, extra: questions);
    });
  }

  @override
  Widget build(BuildContext context) {
    final categoryName = context.read<QuizProvider>().categoryName;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Loading Quiz'),
        leading: Semantics(
          label: 'Go Back',
          child: IconButton(
            tooltip: 'Go Back',
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              HapticFeedback.lightImpact();
              context.go(AppRoute.home);
            },
          ),
        ),
      ),
      body: FutureBuilder<List<Question>>(
        future: _questionsFuture,
        builder: (context, snapshot) {
          // 1. Loading State
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Hero(
                    tag: 'category-$categoryName',
                    child: Material(
                      type: MaterialType.transparency,
                      child: Text(
                        categoryName,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  const CircularProgressIndicator(),
                  const SizedBox(height: 16),
                  const Text('Loading quiz questions...'),
                ],
              ),
            );
          }

          // 2. Error State
          if (snapshot.hasError) {
            final errorMessage = snapshot.error
                .toString()
                .replaceAll('Exception: ', '');

            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.error_outline, size: 64, color: Colors.red),
                    const SizedBox(height: 16),
                    Text(
                      'Failed to load quiz',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      errorMessage,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.grey),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        OutlinedButton(
                          onPressed: () => context.go(AppRoute.home),
                          child: const Text('Go Home'),
                        ),
                        const SizedBox(width: 12),
                        ElevatedButton.icon(
                          onPressed: _fetchQuestions,
                          icon: const Icon(Icons.refresh),
                          label: const Text('Retry'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          }

          // 3. Success State with Data
          if (snapshot.hasData && snapshot.data!.isNotEmpty) {
            _navigateToQuiz(snapshot.data!);
            return const SizedBox.shrink();
          }

          // 4. Empty State (If API returns empty array)
          if (snapshot.hasData && snapshot.data!.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.quiz_outlined, size: 64, color: Colors.amber),
                  const SizedBox(height: 16),
                  const Text('No questions available for this category.'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => context.go(AppRoute.home),
                    child: const Text('Back to Categories'),
                  ),
                ],
              ),
            );
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }
}
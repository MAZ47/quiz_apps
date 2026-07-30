import 'package:flutter/material.dart';
import 'package:quiz_apps/models/quiz_result.dart';

class ScoreCircle extends StatelessWidget {
  final QuizResult result;
  final Color color;

  const ScoreCircle({super.key, required this.result, required this.color});

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        SizedBox(
          width: 120,
          height: 120,
          child: CircularProgressIndicator(
            value: result.accuracy,
            strokeWidth: 10,
            backgroundColor: color.withValues(alpha: 0.15),
            valueColor: AlwaysStoppedAnimation<Color>(color),
            strokeCap: StrokeCap.round,
          ),
        ),
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TweenAnimationBuilder<int>(
              tween: IntTween(begin: 0, end: result.score),
              duration: const Duration(seconds: 1),
              curve: Curves.easeOut,
              builder: (context, value, child) {
                return Text(
                  '$value',
                  style: TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                );
              },
            ),
            Text(
              'of ${result.totalQuestions}',
              style: TextStyle(
                fontSize: 13,
                color: color.withValues(alpha: 0.8),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:quiz_apps/providers/quiz_provider.dart';
import 'package:go_router/go_router.dart';
import 'package:quiz_apps/app_route.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../models/quiz_category.dart';
import 'quiz_category_icon.dart';

class QuizCategoryWidget extends StatelessWidget {
  const QuizCategoryWidget({super.key, required this.category});

  final QuizCategory category;

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.hardEdge,
      child: InkWell(
        onTap: () {
          context.read<QuizProvider>().setCategoryName(category.name);
          context.push(AppRoute.quizLoading);
        },
        child: Stack(
          fit: StackFit.expand,
          children: [
            CachedNetworkImage(
              imageUrl: category.imageUrl,
              fit: BoxFit.cover,
              placeholder: (context, url) => const Center(
                child: SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
              errorWidget: (context, url, error) => Container(
                color: Colors.grey.shade200,
                child: const Center(
                  child: Icon(Icons.cloud_off, color: Colors.grey, size: 32),
                ),
              ),
            ),
            Container(
              color: Colors.black.withValues(alpha: 0.4),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  QuizCategoryIcon(icon: category.icon, color: Colors.white),
                  const SizedBox(height: 12),
                  Hero(
                    tag: 'category-${category.name}',
                    child: Material(
                      type: MaterialType.transparency,
                      child: Text(
                        category.name,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${category.questionCount} Questions',
                    style: const TextStyle(color: Colors.white70),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

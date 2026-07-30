import 'package:flutter/material.dart';

import '../models/quiz_category.dart';
import 'quiz_category_widget.dart';

class CategoryTypeWidget extends StatelessWidget {
  const CategoryTypeWidget({super.key, required this.categories});

  final List<QuizCategory> categories;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      itemCount: categories.length,
      itemBuilder: (context, index) {
        return QuizCategoryWidget(category: categories[index]);
      },
      padding: EdgeInsets.all(16),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
        childAspectRatio: 1.2,
      ),
    );
  }
}

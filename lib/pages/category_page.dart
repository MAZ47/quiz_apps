import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../app_route.dart';
import '../models/quiz_category.dart';
import '../widgets/category_type_widget.dart';

class CategoryPage extends StatefulWidget {
  const CategoryPage({super.key});

  @override
  State<CategoryPage> createState() => _CategoryPageState();
}

class _CategoryPageState extends State<CategoryPage> {
  // const এর পরিবর্তে final ব্যবহার করা হয়েছে
  final List<QuizCategory> categories = [
    QuizCategory(
      name: 'Mathematics',
      questionCount: 10,
      icon: Icons.calculate,
      color: Colors.blue,
      imageUrl: 'https://picsum.photos/seed/math/400/300',
    ),
    QuizCategory(
      name: 'Science & Nature',
      questionCount: 13,
      icon: Icons.science,
      color: Colors.green,
      imageUrl: 'https://picsum.photos/seed/science/400/300',
    ),
    QuizCategory(
      name: 'History',
      questionCount: 12,
      icon: Icons.history,
      color: Colors.orange,
      imageUrl: 'https://picsum.photos/seed/history/400/300',
    ),
    QuizCategory(
      name: 'Geography',
      questionCount: 11,
      icon: Icons.map,
      color: Colors.purple,
      imageUrl: 'https://picsum.photos/seed/geography/400/300',
    ),
    QuizCategory(
      name: 'Sports',
      questionCount: 14,
      icon: Icons.sports_soccer,
      color: Colors.red,
      imageUrl: 'https://picsum.photos/seed/sports/400/300',
    ),
    QuizCategory(
      name: 'Entertainment',
      questionCount: 15,
      icon: Icons.movie,
      color: Colors.pink,
      imageUrl: 'https://picsum.photos/seed/entertainment/400/300',
    ),
    QuizCategory(
      name: 'Art & Literature',
      questionCount: 16,
      icon: Icons.art_track,
      color: Colors.indigo,
      imageUrl: 'https://picsum.photos/seed/art/400/300',
    ),
    QuizCategory(
      name: 'Technology',
      questionCount: 17,
      icon: Icons.computer,
      color: Colors.teal,
      imageUrl: 'https://picsum.photos/seed/tech/400/300',
    ),
    QuizCategory(
      name: 'Music',
      questionCount: 18,
      icon: Icons.music_note,
      color: Colors.yellow,
      imageUrl: 'https://picsum.photos/seed/music/400/300',
    ),
    QuizCategory(
      name: 'General Knowledge',
      questionCount: 19,
      icon: Icons.question_answer,
      color: Colors.brown,
      imageUrl: 'https://picsum.photos/seed/general/400/300',
    ),
  ];

  /// ফিল্টারিং লজিক
  List<QuizCategory> _filterCategories(String type) {
    switch (type) {
      case 'Popular':
        return categories
            .where(
              (c) => [
            'Science & Nature',
            'History',
            'Sports',
            'Entertainment',
          ].contains(c.name),
        )
            .toList();
      case 'New':
        return categories
            .where(
              (c) => [
            'Art & Literature',
            'Technology',
            'Music',
            'General Knowledge',
          ].contains(c.name),
        )
            .toList();
      default:
        return categories;
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Theme.of(context).colorScheme.inversePrimary,
          title: const Text('Quiz Categories'),
          automaticallyImplyActions: true,
          bottom: const TabBar(
            tabs: [
              Tab(text: 'All', icon: Icon(Icons.list)),
              Tab(text: 'Popular', icon: Icon(Icons.star)),
              Tab(text: 'New', icon: Icon(Icons.new_releases)),
            ],
          ),
          actions: [
            Semantics(
              label: 'Subscriptions',
              child: IconButton(
                tooltip: 'Subscriptions',
                icon: const Icon(Icons.access_time_filled),
                onPressed: () {
                  HapticFeedback.lightImpact();
                  context.push(AppRoute.subscription);
                },
              ),
            ),
          ],
        ),
        body: TabBarView(
          children: [
            CategoryTypeWidget(categories: categories),
            CategoryTypeWidget(categories: _filterCategories('Popular')),
            CategoryTypeWidget(categories: _filterCategories('New')),
          ],
        ),
        floatingActionButton: Semantics(
          label: 'Manage Quizzes',
          child: FloatingActionButton(
            heroTag: 'category_manage_fab',
            tooltip: 'Manage Quizzes',
            child: const Icon(Icons.add),
            onPressed: () {
              HapticFeedback.lightImpact();
              context.push(AppRoute.quizManagement);
            },
          ),
        ),
      ),
    );
  }
}
import 'package:flutter/material.dart';

import 'category_page.dart';
import 'profile_page.dart';
import 'scoreboard_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _currentIndex = 0;

  final List<Widget> _pages = const [
    CategoryPage(),
    ScoreboardPage(),
    ProfilePage(),
  ];

  // Note: there used to be a subscription guard here that re-checked
  // SubscriptionProvider.isSubscribed on every HomePage mount and force-
  // navigated to /landing if false. That was redundant with — and raced
  // against — AppRoute's own `redirect` callback, which already runs on
  // every isSubscribed change via `refreshListenable: subscriptionProvider`.
  // Two independent redirect triggers on the same volatile state caused a
  // visible bounce back to /landing immediately after a successful
  // subscribe/login, before the router's own logic even needed to act.
  // The router is now the single source of truth for this check.

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (value) {
          setState(() {
            _currentIndex = value;
          });
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.leaderboard),
            label: 'Leaderboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
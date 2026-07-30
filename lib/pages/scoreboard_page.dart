import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:quiz_apps/providers/scoreboard_provider.dart';
import 'package:quiz_apps/widgets/podium_widget.dart';

import '../widgets/score_card_widget.dart';
import '../widgets/scoreboard_time_toggle.dart';

class ScoreboardPage extends StatefulWidget {
  const ScoreboardPage({super.key});

  @override
  State<ScoreboardPage> createState() => _ScoreboardPageState();
}

class _ScoreboardPageState extends State<ScoreboardPage> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<ScoreboardProvider>().fetchNextGlobalPage();
    });
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;

    final provider = context.read<ScoreboardProvider>();

    // Prevent redundant network requests while already fetching
    if (provider.isLoading) return;

    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      provider.fetchNextGlobalPage();
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Consumer<ScoreboardProvider>(
      builder: (context, scoreboard, child) {
        final history = scoreboard.history;

        return Scaffold(
          appBar: AppBar(
            backgroundColor: colorScheme.inversePrimary,
            title: const Text('Scoreboard'),
            actions: [
              if (history.isNotEmpty)
                IconButton(
                  icon: const Icon(Icons.delete_sweep),
                  tooltip: 'Clear History',
                  onPressed: () {},
                ),
            ],
          ),
          body: Column(
            children: [
              ScoreboardTimeToggle(
                selectedFilter: scoreboard.selectedScoreboardFilter,
                onFilterChanged: (String value) {
                  scoreboard.selectedScoreboardFilter = value;
                },
              ),
              Expanded(
                child: history.isEmpty && scoreboard.isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: history.isEmpty
                      ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.leaderboard_outlined,
                            size: 72,
                            color: colorScheme.outline.withValues(
                              alpha: 0.5,
                            ),
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'No Scores Recorded Yet',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Complete a quiz to record your score here and track your learning progress!',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.grey),
                          ),
                          TextButton(
                            onPressed: () {
                              scoreboard.fetchNextGlobalPage(
                                refresh: true,
                              );
                            },
                            child: const Text('Refresh'),
                          ),
                        ],
                      ),
                    ),
                  )
                      : RefreshIndicator(
                    onRefresh: () =>
                        scoreboard.onRefreshGlobalScores(),
                    child: CustomScrollView(
                      // Pass the controller here to trigger pagination
                      controller: _scrollController,
                      slivers: [
                        SliverToBoxAdapter(
                          child: PodiumWidget(
                            topUsers: history.take(3).toList(),
                          ),
                        ),
                        SliverPadding(
                          padding: const EdgeInsets.only(top: 16),
                          sliver: SliverList(
                            delegate: SliverChildBuilderDelegate(
                                  (context, index) {
                                final remainingScores =
                                history.skip(3).toList();

                                if (index >= remainingScores.length) {
                                  return const Center(
                                    child: Padding(
                                      padding: EdgeInsets.symmetric(
                                        vertical: 16,
                                      ),
                                      child:
                                      CircularProgressIndicator(),
                                    ),
                                  );
                                }

                                final score = remainingScores[index];
                                return ScoreCardWidget(entry: score);
                              },
                              childCount: history.skip(3).length +
                                  (scoreboard.hasMoreGlobalScores
                                      ? 1
                                      : 0),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
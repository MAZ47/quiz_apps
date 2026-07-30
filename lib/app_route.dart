import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'models/question.dart';
import 'models/quiz_result.dart';
import 'pages/ai_page.dart';
import 'pages/home_page.dart';
import 'pages/landing_page.dart';
import 'pages/profile_page.dart';
import 'pages/quiz_loading_page.dart';
import 'pages/quiz_management_page.dart';
import 'pages/quiz_question_page.dart';
import 'pages/result_page.dart';
import 'pages/scoreboard_page.dart';
import 'pages/subscription_page.dart';
import 'providers/subscription_provider.dart';

class AppRoute {
  static const String home = '/home';
  static const String quizQuestion = '/quiz-question';
  static const String quizLoading = '/quiz-loading';
  static const String quizManagement = '/quiz-management';
  static const String quizResult = '/quiz-result';
  static const String scoreboard = '/scoreboard';
  static const String profile = '/profile';
  static const String ai = '/ai-interaction';
  static const String subscription = '/subscription';
  static const String landing = '/landing';
  static const String login = '/login';
  static const String signup = '/signup';

  static GoRouter? _router;

  /// The single live [GoRouter] instance for the app — the same one
  /// mounted as `routerConfig` in main.dart. Use this (not `router(...)`)
  /// anywhere you just need to navigate, such as
  /// PushNotificationService, since you won't have a SubscriptionProvider
  /// reference there and calling `router(...)` again would build a second,
  /// disconnected GoRouter that isn't attached to the actual widget tree.
  static GoRouter get instance {
    assert(
      _router != null,
      'AppRoute.router(subscriptionProvider) must be called once from '
      'main.dart before AppRoute.instance is used elsewhere.',
    );
    return _router!;
  }

  /// Builds the router. Must be given the SAME [SubscriptionProvider]
  /// instance that's registered in the app's MultiProvider (see main.dart),
  /// so that:
  ///   1. `redirect` reads live state directly (no Provider.of lookup that
  ///      can throw if called before the widget tree has this context), and
  ///   2. `refreshListenable: subscriptionProvider` makes GoRouter
  ///      automatically re-run `redirect` against the CURRENT location the
  ///      moment `isSubscribed` changes — e.g. when a mid-session check
  ///      (like ProfilePage's checkSubscriptionStatus()) flips it, with no
  ///      explicit context.go() needed. Without this, notifyListeners() on
  ///      the provider does nothing to the router, and the user stays
  ///      exactly where they were even though they're no longer subscribed.
  ///
  /// Caches the result so calling this more than once (e.g. if MyApp ever
  /// rebuilds) doesn't spawn a second, disconnected router.
  static GoRouter router(SubscriptionProvider subscriptionProvider) {
    return _router ??= GoRouter(
    initialLocation: landing,
    refreshListenable: subscriptionProvider,
    redirect: (context, state) {
      final isLanding = state.matchedLocation == landing;
      final isSubscribed = subscriptionProvider.isSubscribed;

      // ১. যদি সাবস্ক্রাইব করা না থাকে এবং সে ল্যান্ডিং ছাড়া অন্য কোথাও যেতে চায়
      if (!isSubscribed && !isLanding) {
        return landing;
      }

      // ২. যদি সাবস্ক্রাইব করা থাকে এবং সে ল্যান্ডিং পেজে থাকে
      if (isSubscribed && isLanding) {
        return home;
      }

      return null;
    },
    routes: [
      GoRoute(path: home, builder: (context, state) => const HomePage()),
      GoRoute(
        path: quizQuestion,
        builder: (context, state) =>
            QuizQuestionPage(questions: state.extra as List<Question>),
      ),
      GoRoute(
        path: quizLoading,
        builder: (context, state) => const QuizLoadingPage(),
      ),
      GoRoute(
        path: quizManagement,
        builder: (context, state) => const QuizManagementPage(),
      ),
      GoRoute(
        path: quizResult,
        builder: (context, state) {
          final extra = state.extra;
          if (extra is! QuizResult) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('No quiz result to show. Start a new quiz.'),
                ),
              );
              context.go(home);
            });
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }
          return ResultPage(result: extra);
        },
      ),
      GoRoute(
        path: AppRoute.scoreboard,
        builder: (context, state) => const ScoreboardPage(),
      ),
      GoRoute(
        path: AppRoute.profile,
        builder: (context, state) => const ProfilePage(),
      ),
      GoRoute(
        path: AppRoute.ai,
        builder: (context, state) => const AiPage(),
      ),
      GoRoute(
        path: AppRoute.subscription,
        builder: (context, state) => const SubscriptionPage(),
      ),
      GoRoute(
        path: AppRoute.landing,
        builder: (context, state) => const LandingPage(),
      ),
    ],
    );
  }
}
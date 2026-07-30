import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'app_route.dart';
import 'firebase_options.dart';
import 'providers/ai_provider.dart';
import 'providers/auth_provider.dart';
import 'providers/profile_provider.dart';
import 'providers/quiz_provider.dart';
import 'providers/scoreboard_provider.dart';
import 'providers/subscription_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ফায়ারবেস ইনিশিয়ালাইজেশন
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Created once here (instead of inside MultiProvider's `create:`) so the
    // exact same instance can also be handed to AppRoute.router() below as
    // its refreshListenable — that's what lets the router react immediately
    // to isSubscribed changes anywhere in the app, not just after an
    // explicit context.go().
    final subscriptionProvider = SubscriptionProvider();

    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => QuizProvider()),
        ChangeNotifierProvider(create: (_) => ScoreboardProvider()),
        ChangeNotifierProvider(create: (_) => ProfileProvider()),
        ChangeNotifierProvider.value(value: subscriptionProvider),
        ChangeNotifierProvider(create: (_) => AiProvider()),
      ],
      child: MaterialApp.router(
        title: 'Quiz App',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
          useMaterial3: true,
        ),
        routerConfig: AppRoute.router(subscriptionProvider),
      ),
    );
  }
}
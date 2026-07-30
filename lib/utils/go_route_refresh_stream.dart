import 'dart:async';
import 'package:flutter/foundation.dart';

/// Stream listener to trigger GoRouter refresh on auth state changes
class GoRouteRefreshStream extends ChangeNotifier {
  late final StreamSubscription<dynamic> _subscription;

  GoRouteRefreshStream(Stream<dynamic> stream) {
    _subscription = stream.asBroadcastStream().listen((event) {
      notifyListeners();
    });
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}
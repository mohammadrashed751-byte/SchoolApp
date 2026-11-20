import 'dart:async';

import 'package:flutter/foundation.dart';

/// Bridges a [Stream] (here, an `AuthCubit`'s state stream) to go_router's
/// `refreshListenable`, so a redirect re-evaluates on every new auth state.
class GoRouterRefreshStream extends ChangeNotifier {
  late final StreamSubscription<dynamic> _subscription;

  GoRouterRefreshStream(Stream<dynamic> stream) {
    _subscription = stream.asBroadcastStream().listen((_) => notifyListeners());
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}

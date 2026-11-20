import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_app/core/network/token_manager.dart';

void main() {
  test('setAccessToken stores the token and a computed expiry', () {
    final tokenManager = TokenManager();

    tokenManager.setAccessToken('token123', 60);

    expect(tokenManager.currentAccessToken, 'token123');
    expect(tokenManager.currentExpiry, isNotNull);
    expect(
      tokenManager.currentExpiry!.isAfter(DateTime.now()),
      isTrue,
    );
  });

  test('clear resets both the token and the expiry', () {
    final tokenManager = TokenManager();
    tokenManager.setAccessToken('token123', 60);

    tokenManager.clear();

    expect(tokenManager.currentAccessToken, isNull);
    expect(tokenManager.currentExpiry, isNull);
  });
}

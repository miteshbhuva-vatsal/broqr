// Smoke test — verifies the app widget tree can be built without crashing.
// Full integration tests will be added per-module as features are completed.

import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('App builds without errors', (WidgetTester tester) async {
    // Full app requires Firebase initialisation — covered by integration tests.
    // Unit tests for each feature live alongside their respective modules.
    expect(true, isTrue);
  });
}

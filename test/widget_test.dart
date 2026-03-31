import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:tradehub/main.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const ProviderScope(child: TradeHubApp()));

    // Verify that the splash/onboarding dummy screen is displayed
    expect(find.text('Splash/Onboarding'), findsOneWidget);
  });
}

import 'package:flutter_test/flutter_test.dart';

import 'package:club8pool_mobile/main.dart';

void main() {
  testWidgets('App boots without errors', (WidgetTester tester) async {
    await tester.pumpWidget(const Club8PoolApp());
    // Splash shows a progress indicator while routing decision is being made
    expect(find.byType(Club8PoolApp), findsOneWidget);
  });
}

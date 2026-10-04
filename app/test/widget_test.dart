import 'package:flutter_test/flutter_test.dart';

import 'package:sangyan/main.dart';

void main() {
  testWidgets(
    'Sangyan app loads correctly',
    (WidgetTester tester) async {
      await tester.pumpWidget(
        const SangyanApp(),
      );

      expect(
        find.byType(SangyanApp),
        findsOneWidget,
      );

      expect(
        find.text('Sangyan'),
        findsOneWidget,
      );

      expect(
        find.text('What Sangyan can check'),
        findsOneWidget,
      );

      expect(
        find.text('Suspicious Links'),
        findsOneWidget,
      );
    },
  );
}
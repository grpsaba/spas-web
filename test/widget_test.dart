// Boilerplate smoke test of the app shell. `package:spas_web/main.dart`
// imports web-only libraries (dart:html, dart:ui_web...), so this file can
// only compile in a browser: `flutter test --platform chrome
// test/widget_test.dart`. The default `flutter test` (VM) skips it.
@TestOn('browser')
library widget_test;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:spas_web/main.dart';

void main() {
  testWidgets('Counter increments smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const MyApp());

    // Verify that our counter starts at 0.
    expect(find.text('0'), findsOneWidget);
    expect(find.text('1'), findsNothing);

    // Tap the '+' icon and trigger a frame.
    await tester.tap(find.byIcon(Icons.add));
    await tester.pump();

    // Verify that our counter has incremented.
    expect(find.text('0'), findsNothing);
    expect(find.text('1'), findsOneWidget);
  });
}

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spas_web/mobile_config/background_tracking_control.dart';

void main() {
  for (final enabled in [true, false]) {
    for (final saving in [true, false]) {
      testWidgets('global switch respects access and saving: $enabled/$saving',
          (tester) async {
        bool? saved;
        await tester.pumpWidget(MaterialApp(
            home: Scaffold(
                body: BackgroundTrackingControl(
          value: false,
          enabled: enabled,
          saving: saving,
          onChanged: (value) => saved = value,
        ))));
        await tester.tap(find.byType(Switch));
        expect(saved, enabled && !saving ? true : null);
        expect(find.textContaining('Désactivé pour tous les pays'),
            findsOneWidget);
      });
    }
  }
}

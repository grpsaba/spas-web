import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spas_web/zone_member/zone_member_list_actions.dart';

void main() {
  testWidgets('list actions share a compact height and remain usable',
      (tester) async {
    var adds = 0;
    var pointings = 0;
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
          body: ZoneMemberListActions(
        onAdd: () => adds++,
        onManualPointing: () => pointings++,
      )),
    ));
    final add = find.byType(ElevatedButton);
    final manual = find.byType(OutlinedButton);
    expect(tester.getSize(add).height, tester.getSize(manual).height);
    expect(tester.getSize(add).height, lessThanOrEqualTo(42));
    await tester.tap(add);
    await tester.tap(manual);
    expect(adds, 1);
    expect(pointings, 1);
    await tester.binding.setSurfaceSize(const Size(280, 500));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(
        tester.getTopLeft(add).dy, greaterThan(tester.getTopLeft(manual).dy));
  });
}

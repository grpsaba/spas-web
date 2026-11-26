import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spas_web/model.dart';
import 'package:spas_web/zone_member/zone_member_card.dart';

ZoneMember _member({bool global = false}) => ZoneMember(
      UID: 'chief-1',
      code: 'CZ-001',
      firstName: 'Aminata',
      lastName: 'Très Long Nom',
      phone: '+223 70 00 00 00',
      email: 'aminata.tres.long.nom@example-security.test',
      actif: true,
      poste: 'Chef de zone principal',
      zone: global ? null : Zone(codeZone: 'A', name: 'Zone A'),
      tenantId: 'ml',
      hasTenantId: true,
      departmentId: 'security',
      zoneScope: global ? ZoneMemberScope.global : ZoneMemberScope.assigned,
    );

void main() {
  testWidgets('compact card shows email and global security scope',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(320, 480));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: ZoneMemberCard(
              member: _member(global: true),
              statusControl: const ZoneMemberStatusControl(active: true),
            ),
          ),
        ),
      ),
    );

    expect(find.text('aminata.tres.long.nom@example-security.test'),
        findsOneWidget);
    expect(find.text('Toutes les zones · Sécurité'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('grid adapts to viewport and large text without overflowing',
      (tester) async {
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final members = [
      _member(global: true),
      _member()..actif = false,
      _member()
        ..email = ''
        ..phone = ''
        ..poste = null,
      _member(),
    ];

    for (final width in [280.0, 320.0, 360.0, 652.0, 1000.0, 1500.0]) {
      for (final scale in [1.0, 2.0]) {
        await tester.binding.setSurfaceSize(Size(width, 900));
        await tester.pumpWidget(MaterialApp(
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context).copyWith(
              textScaler: TextScaler.linear(scale),
            ),
            child: child!,
          ),
          home: Scaffold(
            body: SingleChildScrollView(
              child: ZoneMemberCardGrid(
                children: [
                  for (final member in members)
                    ZoneMemberCard(
                      member: member,
                      onEdit: () {},
                      statusControl: ZoneMemberStatusControl(
                        active: member.actif == true,
                        onChanged: (_) {},
                      ),
                    ),
                ],
              ),
            ),
          ),
        ));
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull,
            reason: 'viewport $width, text scale $scale');
        final cards = find.byType(ZoneMemberCard);
        expect(cards, findsNWidgets(4));
        final first = tester.getRect(cards.at(0));
        final second = tester.getRect(cards.at(1));
        if (width == 360 && scale == 1) {
          expect(first.height, lessThan(190), reason: 'Keep cards compact');
        }
        if (width < 652) {
          expect(second.top, greaterThanOrEqualTo(first.bottom));
        } else {
          expect(second.top, first.top);
          expect(second.left, greaterThanOrEqualTo(first.right));
        }
      }
    }
  });

  testWidgets('edit and status actions work on their Material surface',
      (tester) async {
    final member = _member();
    var edits = 0;
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: Container(
          color: Colors.white,
          alignment: Alignment.topLeft,
          child: SizedBox(
            width: 360,
            child: StatefulBuilder(builder: (context, setState) {
              return ZoneMemberCard(
                member: member,
                onEdit: () => edits++,
                statusControl: ZoneMemberStatusControl(
                  active: member.actif == true,
                  onChanged: (value) => setState(() => member.actif = value),
                ),
              );
            }),
          ),
        ),
      ),
    ));
    await tester.tap(find.byIcon(Icons.edit_outlined));
    expect(edits, 1);
    expect(find.byTooltip('Désactiver le compte'), findsOneWidget);
    await tester.tap(find.byType(Switch));
    await tester.pumpAndSettle();
    expect(member.actif, isFalse);
    expect(find.text('Inactif'), findsOneWidget);
    expect(find.byTooltip('Activer le compte'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('read-only and missing details remain clear', (tester) async {
    final member = _member()
      ..email = ' '
      ..phone = ''
      ..actif = false;
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: Align(
          alignment: Alignment.topLeft,
          child: SizedBox(width: 360, child: ZoneMemberCard(member: member)),
        ),
      ),
    ));
    expect(find.text('Email non renseigné'), findsOneWidget);
    expect(find.text('Téléphone non renseigné'), findsOneWidget);
    expect(find.text('Zone A'), findsOneWidget);
    expect(find.text('Inactif'), findsOneWidget);
    expect(find.byType(Switch), findsNothing);
    expect(find.byType(IconButton), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'pending status update replaces the toggle with a progress indicator',
      (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: ZoneMemberStatusControl(
          active: true,
          updating: true,
          onChanged: (_) => fail('Cannot toggle during an update'),
        ),
      ),
    ));
    expect(find.byType(Switch), findsNothing);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

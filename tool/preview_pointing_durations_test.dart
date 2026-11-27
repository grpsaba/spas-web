// Preview images of « Durée des pointages » with SYNTHETIC data only.
//
//   flutter test tool/preview_pointing_durations_test.dart
//
// Writes docs/images/pointing-durations.png (the tab) and
// docs/images/pointing-durations-detail.png (a row opened). Not part of the
// default `flutter test` run (files under tool/ are not collected).
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spas_web/geo_tracking/pointing_duration_tab.dart';
import 'package:spas_web/pointage_redesign/presentation/design_system.dart';

import '../test/geo_tracking/duration_fixtures.dart';

Future<void> _loadFont(String family, List<String> paths) async {
  final loader = FontLoader(family);
  for (final path in paths) {
    final bytes = await File(path).readAsBytes();
    loader.addFont(Future.value(ByteData.view(bytes.buffer)));
  }
  await loader.load();
}

String _materialIconsPath() {
  // flutter_tester lives in <flutter>/bin/cache/artifacts/engine/<host>/.
  final artifacts =
      File(Platform.resolvedExecutable).parent.parent.parent.path;
  final candidates = [
    '$artifacts/material_fonts/MaterialIcons-Regular.otf',
    if (Platform.environment['FLUTTER_ROOT'] != null)
      '${Platform.environment['FLUTTER_ROOT']}/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf',
  ];
  return candidates.firstWhere((p) => File(p).existsSync(),
      orElse: () => candidates.first);
}

Future<void> _capture(WidgetTester tester, GlobalKey key, String path) async {
  await tester.runAsync(() async {
    final boundary =
        key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
    final image = await boundary.toImage(pixelRatio: 1);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    final file = File(path);
    await file.parent.create(recursive: true);
    await file.writeAsBytes(bytes!.buffer.asUint8List());
    // ignore: avoid_print
    print('Aperçu : ${file.path} (${image.width}×${image.height})');
  });
}

void main() {
  testWidgets('preview « Durée des pointages »', (tester) async {
    await tester.runAsync(() async {
      await _loadFont('Roboto', [
        'assets/fonts/Roboto-Regular.ttf',
        'assets/fonts/Roboto-Bold.ttf',
      ]);
      await _loadFont('MaterialIcons', [_materialIconsPath()]);
    });
    tester.view.physicalSize = const Size(1440, 2200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final key = GlobalKey();
    final result = syntheticDurationResult();
    await tester.pumpWidget(MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(fontFamily: 'Roboto', useMaterial3: true),
      builder: (context, child) => RepaintBoundary(key: key, child: child),
      home: DefaultTabController(
        length: 3,
        initialIndex: 1,
        child: Scaffold(
          backgroundColor: PointageColors.background,
          appBar: AppBar(
            title: const Text('Suivi géolocalisation'),
            backgroundColor: Colors.white,
            elevation: 1,
          ),
          body: Column(
            children: [
              const Material(
                color: Colors.white,
                child: TabBar(
                  labelColor: PointageColors.primary,
                  unselectedLabelColor: PointageColors.textSecondary,
                  indicatorColor: PointageColors.primary,
                  tabs: [
                    Tab(icon: Icon(Icons.insights), text: 'Statistiques'),
                    Tab(
                        icon: Icon(Icons.timer_outlined),
                        text: 'Durée des pointages'),
                    Tab(
                        icon: Icon(Icons.list_alt),
                        text: 'Journal des actions mobiles'),
                  ],
                ),
              ),
              Expanded(
                child: TabBarView(children: [
                  const SizedBox(),
                  PointingDurationTab(
                    initialRange: DateTimeRange(
                        start: DateTime(2026, 11, 20),
                        end: DateTime(2026, 11, 26)),
                    loader: (start, end) async => result,
                  ),
                  const SizedBox(),
                ]),
              ),
            ],
          ),
        ),
      ),
    ));
    await tester.pumpAndSettle();
    await _capture(tester, key, 'docs/images/pointing-durations.png');

    // A day opened on a laptop-sized screen: widest variant of the details
    // (person and site columns), with measured, estimated and « non mesuré »
    // pointings; « Source » must stay visible next to « Durée totale ».
    tester.view.physicalSize = const Size(1280, 860);
    await tester.pumpAndSettle();
    final day = find.descendant(
        of: find.byKey(const ValueKey('duration-by-day')),
        matching: find.text('ven. 20/11'));
    // The tab's ListView builds the tables lazily: scroll down to the day.
    await tester.scrollUntilVisible(day, 300,
        scrollable: find
            .descendant(
                of: find.byType(PointingDurationTab),
                matching: find.byType(Scrollable))
            .first);
    await tester.pumpAndSettle();
    await tester.tap(day);
    await tester.pumpAndSettle();
    await _capture(tester, key, 'docs/images/pointing-durations-detail.png');
  });
}

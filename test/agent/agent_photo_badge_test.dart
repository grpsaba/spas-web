import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:spas_web/agent/agent_badge_details.dart';
import 'package:spas_web/model.dart';
import 'package:spas_web/pdf/agent_photo_badge_pdf.dart';
import 'package:spas_web/services/agent_photo.dart';
import 'package:spas_web/services/agent_photo_badge.dart';

Agent agent({String? department, String type = 'FIXE'}) => Agent.fromJson({
      'code': 'DEMO-0248',
      'firstName': 'Amadou',
      'lastName': 'Traoré',
      'phone': '',
      'email': '',
      'tracking': false,
      'department': department == null ? null : {'label': department},
      'AgentType': {'label': type},
    });

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('Role follows department, including accents, casing and legacy IDs', () {
    expect(
        agentBadgeRole(agent(department: ' SÉCURITÉ ')), 'Agent de sécurité');
    expect(agentBadgeRole(agent(department: 'security')), 'Agent de sécurité');
    expect(
        agentBadgeRole(agent(department: 'NETTOYAGE')), 'Agent de nettoyage');
    expect(agentBadgeRole(agent(department: 'Maintenance')), 'Maintenance');
    expect(agentBadgeRole(agent()), 'Agent');
    expect(agentBadgeRole(agent(department: '  ')), 'Agent');
  });

  test('Operational types do not override the profession', () {
    for (final type in ['FIXE', 'RONDIER', 'POINT ZERO']) {
      expect(agentBadgeRole(agent(department: 'Nettoyage', type: type)),
          'Agent de nettoyage');
      expect(agentBadgeRole(agent(type: type)), 'Agent');
    }
  });

  test(
      'Department ID works without embedded department; catalog resolves custom IDs',
      () {
    final value = agent()..departmentId = 'cleaning';
    expect(agentBadgeRole(value), 'Agent de nettoyage');
    value.departmentId = 'maintenance';
    expect(
        agentBadgeRole(value, departments: [
          Department(id: 'maintenance', label: 'Maintenance technique')
        ]),
        'Maintenance technique');
  });

  test('Old agent data and photo add/replace/remove survive serialization', () {
    final value = agent();
    expect(value.photoUrl, isNull);
    expect(agentBadgeSite(value), 'Non affecté');
    for (final photo in [
      'https://example.test/photo.png',
      'https://example.test/new.png',
      null
    ]) {
      value.photoUrl = photo;
      expect(Agent.fromJson(value.toJson()).photoUrl, photo);
    }
  });

  test('Invalid or oversized images are rejected before upload', () async {
    await expectLater(
        AgentPhotoService.prepare(Uint8List(0)), throwsFormatException);
    await expectLater(
        AgentPhotoService.prepare(
            Uint8List(AgentPhotoService.maxFileBytes + 1)),
        throwsFormatException);
    await expectLater(AgentPhotoService.prepare(Uint8List.fromList([1, 2, 3])),
        throwsA(anything));
  });

  test('Photo normalization produces a decodable image', () async {
    final source = await rootBundle.load('assets/logo.png');
    final result = await AgentPhotoService.prepare(source.buffer.asUint8List());
    expect(result.take(8), [137, 80, 78, 71, 13, 10, 26, 10]);
  });

  test(
      'Missing and failed photos are reported without losing badges; shared photos load once',
      () async {
    final logo = await rootBundle.load('assets/logo.png');
    final good = agent()..photoUrl = 'https://example.test/photo.png';
    final broken = agent()..photoUrl = 'https://example.test/broken.png';
    final calls = <String>[];
    final progress = <int>[];
    final result = await AgentPhotoBadgeService.generate(
      [good, broken, agent(), good],
      photoLoader: (url) async {
        calls.add(url);
        if (url.endsWith('broken.png')) throw StateError('Photo indisponible');
        return pw.MemoryImage(logo.buffer.asUint8List());
      },
      onProgress: (completed, total) {
        expect(total, 4);
        progress.add(completed);
      },
    );
    expect(result.missingPhotos, hasLength(2));
    expect(calls, hasLength(2));
    expect(progress, [1, 2, 3, 4]);
    expect(String.fromCharCodes(result.bytes.take(5)), '%PDF-');
  });

  test('PDF handles multiple sheets, missing photos and long values', () async {
    final logo = await rootBundle.load('assets/logo.png');
    final bytes = await AgentPhotoBadgePdf.build(
      logoBytes: logo.buffer.asUint8List(),
      regularFont: await rootBundle.load('assets/fonts/Roboto-Regular.ttf'),
      boldFont: await rootBundle.load('assets/fonts/Roboto-Bold.ttf'),
      agents: List.generate(
          17,
          (index) => AgentPhotoBadgeData(
                code: 'SEC0123456789012345-$index',
                firstName: 'Jean-Baptiste Mohamed',
                lastName: 'OUÉDRAOGO TRAORÉ',
                role: index.isEven ? 'Agent de sécurité' : 'Agent de nettoyage',
                site:
                    'Résidence Les Acacias - Bâtiment administratif et annexe',
              )),
    );
    expect(String.fromCharCodes(bytes.take(5)), '%PDF-');
    expect(bytes.length, greaterThan(1000));
  });
}

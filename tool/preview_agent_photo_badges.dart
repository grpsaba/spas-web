// Local PDF fixture: dart --packages=.dart_tool/package_config.json tool/preview_agent_photo_badges.dart <output.pdf>
import 'dart:io';
import 'package:pdf/widgets.dart' as pw;
import 'package:spas_web/pdf/agent_photo_badge_pdf.dart';

Future<void> main(List<String> arguments) async {
  final logo = await File('assets/logo.png').readAsBytes();
  final regularFont =
      await File('assets/fonts/Roboto-Regular.ttf').readAsBytes();
  final boldFont = await File('assets/fonts/Roboto-Bold.ttf').readAsBytes();
  final samplePhoto =
      pw.MemoryImage(await File('assets/agent.png').readAsBytes());
  final badges = List.generate(
      17,
      (index) => AgentPhotoBadgeData(
            code: index == 1 ? 'SEC01234567890123456789' : 'DEMO-${index + 1}',
            firstName: index == 1 ? 'Jean-Baptiste Mohamed' : 'Amadou',
            lastName: index == 1 ? 'OUÉDRAOGO TRAORÉ' : 'TRAORÉ',
            role: index.isEven ? 'Agent de sécurité' : 'Agent de nettoyage',
            site: index == 1
                ? 'Résidence Les Acacias - Bâtiment administratif et annexe'
                : index == 2
                    ? 'Non affecté'
                    : 'Résidence Les Acacias',
            photo: index == 2 ? null : samplePhoto,
          ));
  final bytes = await AgentPhotoBadgePdf.build(
      agents: badges,
      logoBytes: logo,
      regularFont: regularFont.buffer.asByteData(),
      boldFont: boldFont.buffer.asByteData());
  final output = File(arguments.single);
  await output.parent.create(recursive: true);
  await output.writeAsBytes(bytes);
  stdout.writeln(
      'PDF de test : ${output.path} (${bytes.length} octets, 17 badges)');
}

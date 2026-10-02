import 'package:flutter/services.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../agent/agent_badge_details.dart';
import '../model.dart';
import '../pdf/agent_photo_badge_pdf.dart';

class AgentPhotoBadgeResult {
  const AgentPhotoBadgeResult(
      {required this.bytes, required this.missingPhotos});
  final Uint8List bytes;
  final List<String> missingPhotos;
}

class AgentPhotoBadgeService {
  static Future<AgentPhotoBadgeResult> generate(
    List<Agent> agents, {
    Iterable<Department> departments = const [],
    void Function(int completed, int total)? onProgress,
    Future<pw.ImageProvider> Function(String url)? photoLoader,
  }) async {
    final logo = await rootBundle.load('assets/logo.png');
    final regularFont =
        await rootBundle.load('assets/fonts/Roboto-Regular.ttf');
    final boldFont = await rootBundle.load('assets/fonts/Roboto-Bold.ttf');
    final badges = <AgentPhotoBadgeData>[];
    final missing = <String>[];
    final photos = <String, pw.ImageProvider?>{};
    // Load sequentially to avoid saturating Storage during large selections.
    for (final agent in agents) {
      final url = agent.photoUrl?.trim() ?? '';
      pw.ImageProvider? photo;
      if (url.isNotEmpty) {
        if (photos.containsKey(url)) {
          photo = photos[url];
        } else {
          try {
            photo = await (photoLoader?.call(url) ??
                    networkImage(url, cache: false))
                .timeout(const Duration(seconds: 15));
          } catch (_) {
            // The preview lists failures; a failed photo never drops an agent.
          }
          photos[url] = photo;
        }
      }
      if (photo == null) {
        missing.add('${agent.firstName} ${agent.lastName} (${agent.code})');
      }
      badges.add(AgentPhotoBadgeData(
        code: agent.code,
        firstName: agent.firstName,
        lastName: agent.lastName,
        role: agentBadgeRole(agent, departments: departments),
        site: agentBadgeSite(agent),
        photo: photo,
      ));
      onProgress?.call(badges.length, agents.length);
    }
    return AgentPhotoBadgeResult(
      bytes: await AgentPhotoBadgePdf.build(
          agents: badges,
          logoBytes: logo.buffer.asUint8List(),
          regularFont: regularFont,
          boldFont: boldFont),
      missingPhotos: List.unmodifiable(missing),
    );
  }
}

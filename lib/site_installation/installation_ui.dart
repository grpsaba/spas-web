import 'package:flutter/material.dart';
import 'installation_order.dart';

export 'installation_detail_widgets.dart';
export 'installation_list.dart';

/// Shared visual language of the module (web back-office and mobile app).
class InstallationStyle {
  static const background = Color(0xFFF5F7FB);
  static const ink = Color(0xFF17243B);
  static const muted = Color(0xFF5F6B80);
  static const line = Color(0xFFE3E8F0);
  static const strongLine = Color(0xFFCDD5E2);
  static const primary = Color(0xFF4F46C8);
  static const primarySoft = Color(0xFFEEECFC);
  static const green = Color(0xFF147D68);
  static const greenSoft = Color(0xFFE7F5F1);
  static const warning = Color(0xFF9A5A13);
  static const warningSoft = Color(0xFFFFF6E7);
  static const danger = Color(0xFFB42318);
  static const dangerSoft = Color(0xFFFEF3F2);
  static const infoSoft = Color(0xFFEEF1FD);

  /// Below this width, layouts switch to the one-column phone layout.
  static const compactWidth = 600.0;

  static const pageTitle = TextStyle(
      fontSize: 24, height: 1.25, fontWeight: FontWeight.w700, color: ink);
  static const sectionTitle =
      TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: ink);
  static const body = TextStyle(fontSize: 14, height: 1.45, color: ink);
  static const caption = TextStyle(fontSize: 12, height: 1.4, color: muted);
  static const overline = TextStyle(
      fontSize: 10.5,
      fontWeight: FontWeight.w700,
      letterSpacing: 1.1,
      color: primary);

  static ThemeData theme(BuildContext context) => Theme.of(context).copyWith(
        colorScheme: ColorScheme.fromSeed(seedColor: primary),
        scaffoldBackgroundColor: background,
        dividerColor: line,
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          isDense: false,
          errorMaxLines: 3,
          helperMaxLines: 2,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 15),
          labelStyle: const TextStyle(color: muted, fontSize: 14),
          hintStyle: const TextStyle(color: muted, fontSize: 14),
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: line)),
          enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: strongLine)),
          focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: primary, width: 1.6)),
          disabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: line)),
          errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: danger)),
          focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: danger, width: 1.6)),
          errorStyle: const TextStyle(color: danger, fontSize: 12),
        ),
        filledButtonTheme: FilledButtonThemeData(
            style: FilledButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          minimumSize: const Size(0, 48),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 13),
          textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        )),
        outlinedButtonTheme: OutlinedButtonThemeData(
            style: OutlinedButton.styleFrom(
          foregroundColor: ink,
          side: const BorderSide(color: strongLine),
          minimumSize: const Size(0, 48),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
          textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        )),
        textButtonTheme: TextButtonThemeData(
            style: TextButton.styleFrom(
          foregroundColor: primary,
          minimumSize: const Size(0, 44),
          textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        )),
        snackBarTheme: const SnackBarThemeData(
            behavior: SnackBarBehavior.floating,
            backgroundColor: ink,
            contentTextStyle: TextStyle(color: Colors.white, fontSize: 14)),
        appBarTheme: const AppBarTheme(
            backgroundColor: Colors.white,
            foregroundColor: ink,
            elevation: 0,
            scrolledUnderElevation: 0),
      );
}

class InstallationPanel extends StatelessWidget {
  const InstallationPanel(
      {super.key,
      required this.child,
      this.padding = const EdgeInsets.all(20)});
  final Widget child;
  final EdgeInsetsGeometry padding;
  @override
  Widget build(BuildContext context) => Container(
        padding: padding,
        decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: InstallationStyle.line)),
        child: child,
      );
}

Color installationStatusColor(InstallationStatus status) => const {
      InstallationStatus.draft: InstallationStyle.muted,
      InstallationStatus.submitted: Color(0xFF2F5FB3),
      InstallationStatus.changesRequested: Color(0xFFA85F0F),
      InstallationStatus.approved: InstallationStyle.primary,
      InstallationStatus.awaitingSignature: Color(0xFF7A5A26),
      InstallationStatus.signedReturned: InstallationStyle.green,
      InstallationStatus.finalized: InstallationStyle.green,
    }[status]!;

IconData installationStatusIcon(InstallationStatus status) => const {
      InstallationStatus.draft: Icons.edit_note_outlined,
      InstallationStatus.submitted: Icons.fact_check_outlined,
      InstallationStatus.changesRequested: Icons.undo_outlined,
      InstallationStatus.approved: Icons.print_outlined,
      InstallationStatus.awaitingSignature: Icons.draw_outlined,
      InstallationStatus.signedReturned: Icons.assignment_turned_in_outlined,
      InstallationStatus.finalized: Icons.check_circle_outline,
    }[status]!;

class InstallationStatusBadge extends StatelessWidget {
  const InstallationStatusBadge(this.status, {super.key, this.label});
  final InstallationStatus status;
  final String? label;
  @override
  Widget build(BuildContext context) {
    final color = installationStatusColor(status);
    return Container(
      constraints: const BoxConstraints(maxWidth: 245),
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
          color: color.withValues(alpha: .09),
          borderRadius: BorderRadius.circular(20)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 6),
        Flexible(
            child: Text(label ?? status.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                    color: color, fontSize: 12, fontWeight: FontWeight.w600))),
      ]),
    );
  }
}

/// Who acts next and what to do, in plain French.
class InstallationGuidance {
  const InstallationGuidance(
      {required this.owner, required this.title, required this.detail});

  /// « À vous », « Au bureau », « Chez le client » or « Terminé ».
  final String owner;
  final String title;
  final String detail;
}

InstallationGuidance installationGuidance(InstallationStatus status,
    {bool mobile = false, bool reviewer = false}) {
  final office = !mobile && reviewer;
  const owners = {
    InstallationStatus.draft: ['À vous', 'Chez l’initiateur'],
    InstallationStatus.changesRequested: ['À vous', 'Chez l’initiateur'],
    InstallationStatus.submitted: ['Au bureau', 'À vous'],
    InstallationStatus.approved: ['Au bureau', 'À vous'],
    InstallationStatus.awaitingSignature: ['À vous', 'Chez le client'],
    InstallationStatus.signedReturned: ['Au bureau', 'À vous'],
    InstallationStatus.finalized: ['Terminé', 'Terminé'],
  };
  const titles = {
    InstallationStatus.draft: [
      'Compléter puis transmettre',
      'Demande en cours de saisie'
    ],
    InstallationStatus.changesRequested: [
      'Corriger puis transmettre',
      'Correction demandée'
    ],
    InstallationStatus.submitted: [
      'Vérification au bureau',
      'Vérifier puis valider'
    ],
    InstallationStatus.approved: [
      'Bon validé, impression au bureau',
      'Imprimer, signer et remettre le bon'
    ],
    InstallationStatus.awaitingSignature: [
      'Faire signer le client',
      'En attente du bon signé'
    ],
    InstallationStatus.signedReturned: [
      'Ouverture du site au bureau',
      'Créer le site actif'
    ],
    InstallationStatus.finalized: ['Site actif', 'Site actif'],
  };
  final index = office ? 1 : 0;
  return InstallationGuidance(
      owner: owners[status]![index],
      title: titles[status]![index],
      detail: installationNextStep(status, mobile: mobile, reviewer: office));
}

String installationNextStep(InstallationStatus status,
    {bool mobile = false, bool reviewer = true}) {
  final office = !mobile && reviewer;
  return {
    InstallationStatus.draft: office
        ? 'L’initiateur complète la demande avant de la transmettre au bureau.'
        : 'Complétez la demande, puis transmettez-la au bureau pour vérification.',
    InstallationStatus.changesRequested: office
        ? 'La demande attend les corrections de l’initiateur.'
        : 'Consultez les commentaires, apportez les corrections et transmettez à nouveau la demande.',
    InstallationStatus.submitted: office
        ? 'Vérifiez les informations, puis validez ou demandez une correction. Le numéro est attribué automatiquement à la première validation.'
        : 'Le bureau vérifie les informations. Vous pouvez échanger avec le responsable dans le suivi.',
    InstallationStatus.approved: office
        ? 'Imprimez le bon, signez-le et remettez-le à l’initiateur pour la signature du client.'
        : 'Le bon est validé. Le bureau prépare son impression et sa remise pour signature.',
    InstallationStatus.awaitingSignature: office
        ? 'Le document est chez l’initiateur pour signature du client. Confirmez son retour une fois l’original reçu.'
        : 'Faites signer le bon par le client, puis rapportez l’original au bureau. Une photo peut être jointe.',
    InstallationStatus.signedReturned: office
        ? 'Le retour signé est confirmé. Vous pouvez maintenant créer le site actif et son compte.'
        : 'Le bon signé est revenu au bureau. Le responsable peut maintenant ouvrir le site.',
    InstallationStatus.finalized:
        'Le site est actif. Ce dossier conserve le bon et l’historique des échanges.',
  }[status]!;
}

const installationProgressSteps = [
  'Demande',
  'Vérification',
  'Signature',
  'Site actif'
];

int installationProgressStep(InstallationStatus status) => const {
      InstallationStatus.draft: 0,
      InstallationStatus.changesRequested: 0,
      InstallationStatus.submitted: 1,
      InstallationStatus.approved: 2,
      InstallationStatus.awaitingSignature: 2,
      InstallationStatus.signedReturned: 2,
      InstallationStatus.finalized: 3,
    }[status]!;

class InstallationProgress extends StatelessWidget {
  const InstallationProgress(this.status, {super.key});
  final InstallationStatus status;
  int get step => installationProgressStep(status);
  @override
  Widget build(BuildContext context) => Semantics(
      label:
          'Avancement : étape ${step + 1} sur 4, ${installationProgressSteps[step]}',
      child: ExcludeSemantics(
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        for (var i = 0; i < 4; i++)
          Expanded(
              child: Column(children: [
            Row(children: [
              Expanded(
                  child: Container(
                      height: 2,
                      color: i == 0
                          ? Colors.transparent
                          : i <= step
                              ? InstallationStyle.primary
                              : InstallationStyle.line)),
              Container(
                  width: 24,
                  height: 24,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: i <= step
                          ? null
                          : Border.all(color: InstallationStyle.line),
                      color:
                          i <= step ? InstallationStyle.primary : Colors.white),
                  child: i < step || status == InstallationStatus.finalized
                      ? const Icon(Icons.check, size: 14, color: Colors.white)
                      : Text('${i + 1}',
                          style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: i == step
                                  ? Colors.white
                                  : InstallationStyle.muted))),
              Expanded(
                  child: Container(
                      height: 2,
                      color: i == 3
                          ? Colors.transparent
                          : i < step
                              ? InstallationStyle.primary
                              : InstallationStyle.line)),
            ]),
            const SizedBox(height: 6),
            Text(installationProgressSteps[i],
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                    fontSize: 11,
                    color: i == step
                        ? InstallationStyle.primary
                        : InstallationStyle.muted,
                    fontWeight: i == step ? FontWeight.w700 : FontWeight.w400)),
          ])),
      ])));
}

enum InstallationTone { info, warning, error, success }

class _Palette {
  const _Palette(this.background, this.foreground, this.icon);
  final Color background;
  final Color foreground;
  final IconData icon;
}

Color installationToneColor(InstallationTone tone) => const {
      InstallationTone.info: InstallationStyle.primary,
      InstallationTone.warning: InstallationStyle.warning,
      InstallationTone.error: InstallationStyle.danger,
      InstallationTone.success: InstallationStyle.green,
    }[tone]!;

class InstallationNotice extends StatelessWidget {
  const InstallationNotice(
      {super.key,
      required this.message,
      this.icon,
      this.warning = false,
      this.tone,
      this.title,
      this.lines = const [],
      this.action});
  final String message;
  final IconData? icon;
  final bool warning;
  final InstallationTone? tone;
  final String? title;

  /// Optional bullet list displayed under the message (e.g. missing fields).
  final List<String> lines;
  final Widget? action;

  InstallationTone get _tone =>
      tone ?? (warning ? InstallationTone.warning : InstallationTone.info);

  static const _palettes = {
    InstallationTone.info: _Palette(InstallationStyle.infoSoft,
        InstallationStyle.primary, Icons.info_outline),
    InstallationTone.warning: _Palette(InstallationStyle.warningSoft,
        InstallationStyle.warning, Icons.warning_amber_rounded),
    InstallationTone.error: _Palette(InstallationStyle.dangerSoft,
        InstallationStyle.danger, Icons.error_outline),
    InstallationTone.success: _Palette(InstallationStyle.greenSoft,
        InstallationStyle.green, Icons.check_circle_outline),
  };

  @override
  Widget build(BuildContext context) {
    final palette = _palettes[_tone]!;
    final background = palette.background;
    final foreground = palette.foreground;
    final defaultIcon = palette.icon;
    return Semantics(
        liveRegion: _tone == InstallationTone.error,
        child: Container(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
          decoration: BoxDecoration(
              color: background, borderRadius: BorderRadius.circular(12)),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Padding(
                  padding: const EdgeInsets.only(top: 1),
                  child:
                      Icon(icon ?? defaultIcon, size: 19, color: foreground)),
              const SizedBox(width: 10),
              Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                    if (title != null) ...[
                      Text(title!,
                          style: const TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w700,
                              color: InstallationStyle.ink)),
                      const SizedBox(height: 3),
                    ],
                    Text(message,
                        style: const TextStyle(
                            fontSize: 13,
                            height: 1.45,
                            color: InstallationStyle.ink)),
                    for (final line in lines)
                      Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('•  ',
                                    style: TextStyle(
                                        fontSize: 13,
                                        height: 1.45,
                                        color: foreground)),
                                Expanded(
                                    child: Text(line,
                                        style: const TextStyle(
                                            fontSize: 13,
                                            height: 1.45,
                                            color: InstallationStyle.ink))),
                              ])),
                  ])),
            ]),
            if (action != null)
              Padding(
                  padding: const EdgeInsets.only(top: 6, left: 25),
                  child: action!),
          ]),
        ));
  }
}

/// Centered state for loading, empty, error, offline or locked screens.
class InstallationStateMessage extends StatelessWidget {
  const InstallationStateMessage(
      {super.key,
      required this.title,
      this.message,
      this.icon = Icons.inbox_outlined,
      this.loading = false,
      this.tone = InstallationTone.info,
      this.action});
  final String title;
  final String? message;
  final IconData icon;
  final bool loading;
  final InstallationTone tone;
  final Widget? action;
  @override
  Widget build(BuildContext context) {
    final color = installationToneColor(tone);
    return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          if (loading)
            const SizedBox(
                width: 32,
                height: 32,
                child: CircularProgressIndicator(strokeWidth: 3))
          else
            Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                    color: color.withValues(alpha: .08),
                    shape: BoxShape.circle),
                child: Icon(icon, size: 30, color: color)),
          const SizedBox(height: 16),
          Text(title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: InstallationStyle.ink)),
          if (message != null) ...[
            const SizedBox(height: 8),
            ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 440),
                child: Text(message!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        color: InstallationStyle.muted,
                        fontSize: 13.5,
                        height: 1.5))),
          ],
          if (action != null) ...[const SizedBox(height: 16), action!],
        ]));
  }
}

String installationDateLabel(DateTime? date) => date == null
    ? 'À l’instant'
    : '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';

String installationTimeLabel(DateTime date) =>
    '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';

/// Lower case without accents, for searches typed without diacritics.
String installationNormalize(String text) {
  const from = 'àáâäãåçéèêëíìîïñóòôöõúùûüýÿœæ';
  const to = 'aaaaaaceeeeiiiinooooouuuuyy';
  final buffer = StringBuffer();
  for (final rune in text.toLowerCase().runes) {
    final char = String.fromCharCode(rune);
    final index = from.indexOf(char);
    if (index < 0) {
      buffer.write(char);
    } else if (char == 'œ') {
      buffer.write('oe');
    } else if (char == 'æ') {
      buffer.write('ae');
    } else {
      buffer.write(to[index]);
    }
  }
  return buffer.toString().trim();
}

/// User-facing message without Dart or plugin technical prefixes.
String installationReadableError(Object error) {
  if (error is StateError) return error.message;
  if (error is FormatException) return error.message;
  var text = '$error'.trim();
  for (final prefix in [
    'Bad state: ',
    'FormatException: ',
    'Exception: ',
    'Invalid argument(s): '
  ]) {
    if (text.startsWith(prefix)) text = text.substring(prefix.length);
  }
  final plugin =
      RegExp(r'^\[[\w_]+/([\w-]+)\]\s*(.*)$', dotAll: true).firstMatch(text);
  if (plugin != null) {
    final code = plugin.group(1)!;
    const known = {
      'unavailable':
          'Connexion impossible. Vérifiez le réseau, puis réessayez.',
      'network-request-failed':
          'Connexion impossible. Vérifiez le réseau, puis réessayez.',
      'deadline-exceeded':
          'Le serveur met trop de temps à répondre. Réessayez dans un instant.',
      'permission-denied':
          'Action refusée : votre profil ne dispose pas des droits nécessaires.',
      'unauthenticated': 'Session expirée. Reconnectez-vous, puis réessayez.',
      'not-found': 'Document introuvable. Il a peut-être été supprimé.',
    };
    return known[code] ?? plugin.group(2)!.trim();
  }
  return text;
}

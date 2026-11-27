import 'package:spas_web/error_logs/models/geo_diagnostic.dart';
import 'package:spas_web/model.dart' show dateTimeFromJsonValue;
import 'package:spas_web/models/pointing_method.dart';

import 'pointing_duration.dart';

/// One document of the `mobile_events` collection (actions logged by phones).
class MobileEvent {
  const MobileEvent({
    required this.id,
    required this.event,
    this.timestamp,
    this.clientTimestamp,
    this.visitId,
    this.siteId,
    this.siteCode,
    this.role,
    this.userId,
    this.userCode,
    this.userName,
    this.tenantId,
    this.appVersion,
    this.device,
    this.isOnline,
    this.data = const {},
  });

  static const String collection = 'mobile_events';

  final String id;
  final String event;

  /// Server time (when the event reached Firestore, may be late offline).
  final DateTime? timestamp;

  /// Phone time when the action happened.
  final DateTime? clientTimestamp;
  final String? visitId;
  final String? siteId;
  final String? siteCode;
  final String? role;
  final String? userId;
  final String? userCode;
  final String? userName;
  final String? tenantId;
  final String? appVersion;
  final DeviceInfoView? device;
  final bool? isOnline;
  final Map<String, dynamic> data;

  factory MobileEvent.fromMap(String id, Map<String, dynamic> json) {
    String? text(String key) {
      final value = json[key]?.toString().trim();
      return value == null || value.isEmpty ? null : value;
    }

    return MobileEvent(
      id: id,
      event: text('event') ?? 'inconnu',
      timestamp: dateTimeFromJsonValue(json['timestamp']),
      clientTimestamp: dateTimeFromJsonValue(json['clientTimestamp']),
      visitId: text('visitId'),
      siteId: text('siteId'),
      siteCode: text('siteCode'),
      role: text('role'),
      userId: text('userId'),
      userCode: text('userCode'),
      userName: text('userName'),
      tenantId: text('tenantId'),
      appVersion: text('appVersion'),
      device: DeviceInfoView.fromMap(json['deviceInfo']),
      isOnline: json['isOnline'] is bool ? json['isOnline'] as bool : null,
      data: asStringMap(json['data']) ?? const {},
    );
  }

  /// Best time of the action: phone time first, server time otherwise.
  DateTime? get time => clientTimestamp ?? timestamp;

  String get label => MobileEventLabels.label(event);

  /// Label with its key figure: « Pointage enregistré · 1 min 05 s »,
  /// « Essai GPS terminé · Photo choisie pendant la recherche ».
  String get title {
    switch (event) {
      case 'pointing_saved':
        final duration = PointingDurationBreakdown.fromMap(data);
        return duration == null
            ? label
            : '$label · ${formatDuration(duration.totalMs)}';
      case 'geo_attempt_finished':
        final outcome = data['outcome']?.toString();
        return outcome == AttemptOutcome.photoChosen
            ? '$label · ${AttemptOutcome.label(outcome)}'
            : label;
      default:
        return label;
    }
  }

  String get roleLabel => role == 'zone_chief'
      ? 'Chef de zone'
      : role == 'supervisor'
          ? 'Superviseur'
          : (role ?? '—');

  /// Readable view of `data` for lists and the timeline: French sentences
  /// for the events the web knows, compact "key: value" otherwise.
  String get dataSummary {
    if (data.isEmpty) return '';
    final readable = MobileEventDetails.describe(event, data);
    if (readable != null) return readable;
    return data.entries
        .where((e) => e.value != null && e.value is! Map && e.value is! List)
        .map((e) => '${e.key}: ${e.value}')
        .join(' · ');
  }
}

/// French labels for known events; unknown names are shown as-is because
/// the mobile app will keep adding events.
class MobileEventLabels {
  static const Map<String, String> known = {
    'app_opened': 'Application ouverte',
    'login': 'Connexion',
    'logout': 'Déconnexion',
    'sync_started': 'Synchronisation lancée',
    'sync_finished': 'Synchronisation terminée',
    'site_list_opened': 'Liste des sites ouverte',
    'pointing_started': 'Pointage commencé',
    'geo_attempt_started': 'Essai GPS commencé',
    'geo_attempt_finished': 'Essai GPS terminé',
    'geo_retry_tapped': 'Nouvel essai GPS demandé',
    'geo_cancel_tapped': 'Essai GPS annulé',
    'photo_fallback_offered': 'Photo de secours proposée',
    'photo_fallback_tapped': 'Photo de secours choisie',
    'photo_captured': 'Photo prise',
    'pointing_saved': 'Pointage enregistré',
    'gps_enable_prompt_shown': 'Demande d\'activer le GPS',
    'location_permission_result': 'Réponse à la permission de localisation',
    'site_position_report_tapped': 'Position du site signalée',
    'diagnostic_copied': 'Diagnostic copié',
    'gps_health': 'État du GPS',
    'gps_first_fix': 'Première position',
    'gps_stream_restarted': 'GPS relancé',
  };

  static String label(String event) => known[event] ?? event;
}

/// French details of the events whose `data` has a known shape.
class MobileEventDetails {
  /// Null when the event has no dedicated formatting.
  static String? describe(String event, Map<String, dynamic> data) {
    switch (event) {
      case 'gps_health':
        return _join(gpsHealth(data));
      case 'gps_first_fix':
        return _join([
          if (_num(data['ms']) != null)
            'après ${formatDuration(_num(data['ms']))}',
          if (_num(data['accuracyM']) != null)
            'précision ± ${_num(data['accuracyM'])!.round()} m',
        ]);
      case 'gps_stream_restarted':
        final reason = _text(data['reason']);
        return reason == null ? null : 'Raison : $reason';
      case 'geo_attempt_finished':
        final outcome = _text(data['outcome']);
        final duration = _num(data['durationMs']);
        if (outcome == null && duration == null) return null;
        final rest = _rest(data, const {'outcome', 'durationMs'});
        return _join([
          if (outcome != null) 'Résultat : ${AttemptOutcome.label(outcome)}',
          if (duration != null) 'durée ${formatDuration(duration)}',
          ...rest,
        ]);
      case 'pointing_saved':
        final duration = PointingDurationBreakdown.fromMap(data);
        if (duration == null) return null;
        final rest = _rest(data, const {
          'durationMs',
          'totalMs',
          'gpsWaitMs',
          'firstFixMs',
          'decisionMs',
          'photoMs',
          'saveMs',
          'relaunches',
          'startedAt',
          'version',
          'pointingMethod',
        });
        final method = PointingMethodInfo.parse(data['pointingMethod']);
        return _join([
          'Durée ${formatDuration(duration.totalMs)}',
          if (method != null) 'Méthode : ${DurationMethodLabels.label(method)}',
          if (duration.summary.isNotEmpty) duration.summary,
          ...rest,
        ]);
      default:
        return null;
    }
  }

  /// « Permission : toujours · GPS : activé · … » for `gps_health`.
  static List<String> gpsHealth(Map<String, dynamic> data) {
    final permission = _text(data['permission']);
    final age = _num(data['lastFixAgeMs']);
    final accuracy = _num(data['lastFixAccuracyM']);
    final fixes = _num(data['fixesLast5Min']);
    final inView = _num(data['satellitesInView']);
    final used = _num(data['satellitesUsed']);
    final cn0 = _num(data['bestCn0DbHz']);
    final battery = _num(data['batteryPercent']);
    final restarts = _num(data['streamRestarts']);
    final trigger = _text(data['trigger']);
    final error = _text(data['lastStreamError']);
    return [
      if (trigger != null) 'Déclencheur : $trigger',
      if (permission != null) 'Permission : ${permissionLabel(permission)}',
      if (data['locationServiceEnabled'] is bool)
        'Localisation : ${_onOff(data['locationServiceEnabled'] as bool)}',
      if (data['gpsProviderEnabled'] is bool)
        'GPS : ${_onOff(data['gpsProviderEnabled'] as bool)}',
      if (data['networkProviderEnabled'] is bool)
        'Réseau : ${_onOff(data['networkProviderEnabled'] as bool)}',
      if (data['powerSaveMode'] is bool)
        'Économie d\'énergie : ${data['powerSaveMode'] == true ? 'oui' : 'non'}',
      if (battery != null) 'Batterie : ${battery.round()} %',
      if (data['trackerActive'] is bool)
        'Suivi continu : ${data['trackerActive'] == true ? 'actif' : 'inactif'}',
      if (data['backgroundRequested'] is bool)
        'Arrière-plan demandé : ${data['backgroundRequested'] == true ? 'oui' : 'non'}',
      if (age != null || accuracy != null)
        'Dernière position : '
            '${age == null ? 'âge inconnu' : 'il y a ${formatDuration(age)}'}'
            '${accuracy == null ? '' : ' (± ${accuracy.round()} m)'}'
      else if (data.containsKey('lastFixAgeMs'))
        'Dernière position : aucune',
      if (fixes != null) 'Positions sur 5 min : ${fixes.round()}',
      if (inView != null || used != null)
        'Satellites : ${used == null ? '?' : used.round()} utilisés'
            ' / ${inView == null ? '?' : inView.round()} vus',
      if (cn0 != null) 'Meilleur signal : ${cn0.round()} dB-Hz',
      if (restarts != null) 'Relances du GPS : ${restarts.round()}',
      if (error != null) 'Dernière erreur : $error',
    ];
  }

  static String permissionLabel(String value) {
    switch (value) {
      case 'always':
        return 'toujours';
      case 'whileInUse':
      case 'while_in_use':
        return 'pendant l\'utilisation';
      case 'granted':
        return 'accordée';
      case 'denied':
        return 'refusée';
      case 'deniedForever':
      case 'denied_forever':
        return 'refusée définitivement';
      case 'unableToDetermine':
        return 'inconnue';
      default:
        return value;
    }
  }

  static String _onOff(bool value) => value ? 'activé' : 'désactivé';

  static num? _num(Object? value) =>
      value is num && !value.isNaN ? value : null;

  static String? _text(Object? value) {
    final text = value?.toString().trim();
    return text == null || text.isEmpty ? null : text;
  }

  /// Simple values not already described, as "key: value".
  static List<String> _rest(Map<String, dynamic> data, Set<String> known) => [
        for (final entry in data.entries)
          if (!known.contains(entry.key) &&
              entry.value != null &&
              entry.value is! Map &&
              entry.value is! List)
            '${entry.key}: ${entry.value}',
      ];

  static String? _join(List<String> parts) =>
      parts.isEmpty ? null : parts.join(' · ');
}

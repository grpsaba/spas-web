import 'package:spas_web/error_logs/models/geo_diagnostic.dart';
import 'package:spas_web/model.dart' show dateTimeFromJsonValue;

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

  String get roleLabel => role == 'zone_chief'
      ? 'Chef de zone'
      : role == 'supervisor'
          ? 'Superviseur'
          : (role ?? '—');

  /// Compact "key: value" view of `data` for lists and the timeline.
  String get dataSummary {
    if (data.isEmpty) return '';
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
  };

  static String label(String event) => known[event] ?? event;
}

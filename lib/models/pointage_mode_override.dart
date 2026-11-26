import 'package:cloud_firestore/cloud_firestore.dart';

/// Per-person pointing mode (`pointageModeOverride` on `Supervisors` and
/// `ZoneMembers` documents). Absent/null = follow the country setting.
class PointageModeOverride {
  static const String field = 'pointageModeOverride';
  static const String photo = 'photo';
  static const String geo = 'geo';

  /// Only explicit values force a mode; anything unknown means "country".
  static String? normalize(Object? value) {
    final mode = value
        ?.toString()
        .trim()
        .toLowerCase()
        .replaceAll('é', 'e')
        .replaceAll('è', 'e');
    switch (mode) {
      case photo:
        return photo;
      case geo:
      case 'gps':
      case 'geolocation':
      case 'geolocalisation':
        return geo;
      default:
        return null;
    }
  }

  static String? fromJson(Map<String, dynamic> json) => normalize(json[field]);

  /// Fields for an update of an existing person: the default deletes the
  /// field so the document goes back to "absent = follow the country".
  static Map<String, Object> updateFields(String? override) => {
        field: normalize(override) ?? FieldValue.delete(),
      };

  /// Fields for a newly created person: nothing is written for the default.
  static Map<String, Object> createFields(String? override) {
    final value = normalize(override);
    return value == null ? const {} : {field: value};
  }

  /// Mode the phone will use for this person.
  static String effectiveMode(String? override, String countryMode) =>
      normalize(override) ?? (countryMode == geo ? geo : photo);

  static String modeLabel(String mode) =>
      mode == geo ? 'Géolocalisation' : 'Photo';

  static String optionLabel(String? override, {String? countryMode}) {
    switch (normalize(override)) {
      case photo:
        return 'Toujours Photo';
      case geo:
        return 'Toujours Géolocalisation';
      default:
        return countryMode == null
            ? 'Selon le pays'
            : 'Selon le pays (${modeLabel(countryMode)})';
    }
  }

  /// Short label for list badges; null when the person follows the country.
  static String? badgeLabel(Object? override) {
    switch (normalize(override)) {
      case photo:
        return 'Toujours Photo';
      case geo:
        return 'Toujours Géo';
      default:
        return null;
    }
  }
}

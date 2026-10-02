import 'package:cloud_firestore/cloud_firestore.dart';

import '../../model.dart';

class PointingSheetActor {
  const PointingSheetActor({
    required this.uid,
    required this.name,
    required this.email,
  });

  final String uid;
  final String name;
  final String email;

  factory PointingSheetActor.fromJson(Map<String, dynamic>? json) {
    return PointingSheetActor(
      uid: json?['uid']?.toString() ?? '',
      name: json?['name']?.toString() ?? 'Utilisateur inconnu',
      email: json?['email']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'uid': uid,
        'name': name,
        'email': email,
      };
}

class PointingDayNote {
  const PointingDayNote({
    required this.category,
    required this.details,
    required this.updatedBy,
    this.updatedAt,
  });

  final String category;
  final String details;
  final PointingSheetActor updatedBy;
  final DateTime? updatedAt;

  String get displayText {
    if (category.trim().isEmpty) return details.trim();
    if (details.trim().isEmpty) return category.trim();
    return '${category.trim()} - ${details.trim()}';
  }

  factory PointingDayNote.fromJson(Map<String, dynamic> json) {
    return PointingDayNote(
      category: json['category']?.toString() ?? '',
      details: json['details']?.toString() ?? '',
      updatedBy: PointingSheetActor.fromJson(
        json['updatedBy'] is Map
            ? Map<String, dynamic>.from(json['updatedBy'] as Map)
            : null,
      ),
      updatedAt: dateTimeFromJsonValue(json['updatedAt']),
    );
  }

  Map<String, dynamic> toJson({Object? updatedAtValue}) => <String, dynamic>{
        'category': category.trim(),
        'details': details.trim(),
        'updatedBy': updatedBy.toJson(),
        'updatedAt': updatedAtValue ?? updatedAt,
      };
}

class MonthlyPointingSheet {
  const MonthlyPointingSheet({
    required this.id,
    required this.monthKey,
    required this.month,
    required this.supervisorId,
    required this.supervisorFirstName,
    required this.supervisorLastName,
    required this.supervisorPhone,
    required this.expectedDay,
    required this.expectedNight,
    required this.tenantId,
    required this.notes,
    required this.createdBy,
    required this.updatedBy,
    this.departmentId,
    this.zoneCode,
    this.zoneName,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String monthKey;
  final DateTime month;
  final String supervisorId;
  final String supervisorFirstName;
  final String supervisorLastName;
  final String supervisorPhone;
  final int expectedDay;
  final int expectedNight;
  final String tenantId;
  final String? departmentId;
  final String? zoneCode;
  final String? zoneName;
  final Map<String, PointingDayNote> notes;
  final PointingSheetActor createdBy;
  final PointingSheetActor updatedBy;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  String get supervisorName {
    final name = '$supervisorFirstName $supervisorLastName'.trim();
    return name.isEmpty ? 'Superviseur inconnu' : name;
  }

  String get initials {
    final first = supervisorFirstName.trim();
    final last = supervisorLastName.trim();
    return '${first.isEmpty ? '' : first[0]}${last.isEmpty ? '' : last[0]}'
        .toUpperCase();
  }

  factory MonthlyPointingSheet.fromDocument(
    DocumentSnapshot<Map<String, dynamic>> document,
  ) {
    return MonthlyPointingSheet.fromJson(
      document.data() ?? <String, dynamic>{},
      id: document.id,
    );
  }

  factory MonthlyPointingSheet.fromJson(
    Map<String, dynamic> json, {
    required String id,
  }) {
    final rawNotes = json['notes'];
    final notes = <String, PointingDayNote>{};
    if (rawNotes is Map) {
      rawNotes.forEach((key, value) {
        if (value is Map) {
          notes[key.toString()] = PointingDayNote.fromJson(
            Map<String, dynamic>.from(value),
          );
        }
      });
    }

    final parsedMonth = dateTimeFromJsonValue(json['month']);
    final monthKey = json['monthKey']?.toString() ?? '';
    final fallbackMonth = _monthFromKey(monthKey) ?? DateTime.now();

    return MonthlyPointingSheet(
      id: id,
      monthKey: monthKey,
      month: DateTime(
        (parsedMonth ?? fallbackMonth).year,
        (parsedMonth ?? fallbackMonth).month,
      ),
      supervisorId: json['supervisorId']?.toString() ?? '',
      supervisorFirstName: json['supervisorFirstName']?.toString() ?? '',
      supervisorLastName: json['supervisorLastName']?.toString() ?? '',
      supervisorPhone: json['supervisorPhone']?.toString() ?? '',
      expectedDay: _readInt(json['expectedDay']),
      expectedNight: _readInt(json['expectedNight']),
      tenantId: tenantIdFromJson(json),
      departmentId: departmentIdFromJson(json),
      zoneCode: json['zoneCode']?.toString(),
      zoneName: json['zoneName']?.toString(),
      notes: notes,
      createdBy: PointingSheetActor.fromJson(
        json['createdBy'] is Map
            ? Map<String, dynamic>.from(json['createdBy'] as Map)
            : null,
      ),
      updatedBy: PointingSheetActor.fromJson(
        json['updatedBy'] is Map
            ? Map<String, dynamic>.from(json['updatedBy'] as Map)
            : null,
      ),
      createdAt: dateTimeFromJsonValue(json['createdAt']),
      updatedAt: dateTimeFromJsonValue(json['updatedAt']),
    );
  }

  static int _readInt(Object? value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  static DateTime? _monthFromKey(String value) {
    final parts = value.split('-');
    if (parts.length != 2) return null;
    final year = int.tryParse(parts[0]);
    final month = int.tryParse(parts[1]);
    if (year == null || month == null || month < 1 || month > 12) return null;
    return DateTime(year, month);
  }
}

class PointingSheetAuditEntry {
  const PointingSheetAuditEntry({
    required this.id,
    required this.action,
    required this.actor,
    required this.changes,
    this.dayKey,
    this.createdAt,
  });

  final String id;
  final String action;
  final String? dayKey;
  final PointingSheetActor actor;
  final Map<String, dynamic> changes;
  final DateTime? createdAt;

  factory PointingSheetAuditEntry.fromDocument(
    DocumentSnapshot<Map<String, dynamic>> document,
  ) {
    final json = document.data() ?? <String, dynamic>{};
    return PointingSheetAuditEntry(
      id: document.id,
      action: json['action']?.toString() ?? '',
      dayKey: json['dayKey']?.toString(),
      actor: PointingSheetActor.fromJson(
        json['actor'] is Map
            ? Map<String, dynamic>.from(json['actor'] as Map)
            : null,
      ),
      changes: json['changes'] is Map
          ? Map<String, dynamic>.from(json['changes'] as Map)
          : <String, dynamic>{},
      createdAt: dateTimeFromJsonValue(json['createdAt']),
    );
  }
}

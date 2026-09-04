import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../../model.dart';
import '../../services/authentication.dart';
import '../../services/department_scope.dart';
import '../../services/tenant_scope.dart';
import '../models/monthly_pointing_sheet.dart';
import 'monthly_pointing_calculator.dart';

class MonthlyPointingSheetService {
  MonthlyPointingSheetService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  static const String collectionName = 'supervisorPointingSheets';

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _sheets =>
      _firestore.collection(collectionName);

  CollectionReference<Map<String, dynamic>> get _pointings =>
      _firestore.collection('sitePointings');

  Stream<List<MonthlyPointingSheet>> watchMonth(DateTime month) {
    Query<Map<String, dynamic>> query =
        _sheets.where('monthKey', isEqualTo: monthKey(month));
    query = DepartmentScope.applyToDepartmentQuery(
      TenantScope.applyToQuery(query),
    );

    return TenantScope.watchQuery(
      'MonthlyPointingSheetService.watchMonth',
      query,
    ).map((snapshot) {
      final sheets = snapshot.docs
          .map(MonthlyPointingSheet.fromDocument)
          .toList(growable: false);
      return sheets.toList()
        ..sort((a, b) => a.supervisorName
            .toLowerCase()
            .compareTo(b.supervisorName.toLowerCase()));
    });
  }

  Stream<MonthlyPointingSheet?> watchSheet(String sheetId) {
    return _sheets.doc(sheetId).snapshots().map((document) {
      if (!document.exists) return null;
      final sheet = MonthlyPointingSheet.fromDocument(document);
      if (!TenantScope.matchesTenant(sheet.tenantId) ||
          !DepartmentScope.matchesDepartment(
            sheet.departmentId,
            tenantId: sheet.tenantId,
          )) {
        return null;
      }
      return sheet;
    });
  }

  Stream<List<PointingSite>> watchPointingsForMonth(DateTime month) {
    final start = DateTime(month.year, month.month);
    final end = DateTime(month.year, month.month + 1);
    Query<Map<String, dynamic>> query = _pointings
        .where('datetimestamp', isGreaterThanOrEqualTo: start)
        .where('datetimestamp', isLessThan: end);
    query = DepartmentScope.applyToDepartmentQuery(
      TenantScope.applyToQuery(query),
    );

    return TenantScope.watchQuery(
      'MonthlyPointingSheetService.watchPointingsForMonth',
      query,
    ).map(_parsePointings);
  }

  Stream<List<PointingSite>> watchPointingsForSheet(
    MonthlyPointingSheet sheet,
  ) {
    return watchPointingsForMonth(sheet.month).map(
      (pointings) => pointings
          .where((pointing) => pointing.supervisor?.UID == sheet.supervisorId)
          .toList(growable: false),
    );
  }

  Stream<List<PointingSheetAuditEntry>> watchAudit(String sheetId) {
    return _sheets
        .doc(sheetId)
        .collection('history')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map(PointingSheetAuditEntry.fromDocument)
            .toList(growable: false));
  }

  Future<String> createSheet({
    required Supervisor supervisor,
    required DateTime month,
    required int expectedDay,
    required int expectedNight,
  }) async {
    final actor = _currentActor();
    final key = monthKey(month);
    final tenantId = effectiveTenantId(
      supervisor.tenantId,
      <String?>[TenantScope.tenantIdForWrite],
    );
    final departmentId = normalizeDepartmentId(
      supervisor.departmentId ?? supervisor.department?.id,
    );
    final sheetId = _sheetId(tenantId, supervisor.UID, key);
    final sheetReference = _sheets.doc(sheetId);
    final historyReference = sheetReference.collection('history').doc();

    await _firestore.runTransaction((transaction) async {
      final existing = await transaction.get(sheetReference);
      if (existing.exists) {
        throw StateError(
          'Une fiche existe déjà pour ce superviseur et ce mois.',
        );
      }

      final now = FieldValue.serverTimestamp();
      transaction.set(sheetReference, <String, dynamic>{
        'monthKey': key,
        'month': Timestamp.fromDate(DateTime(month.year, month.month)),
        'supervisorId': supervisor.UID,
        'supervisorFirstName': supervisor.firstName,
        'supervisorLastName': supervisor.lastName,
        'supervisorPhone': supervisor.phone,
        'expectedDay': expectedDay,
        'expectedNight': expectedNight,
        'zoneCode': supervisor.zone?.codeZone,
        'zoneName': supervisor.zone?.name,
        'tenantId': tenantId,
        if (departmentId.isNotEmpty) 'departmentId': departmentId,
        'notes': <String, dynamic>{},
        'createdBy': actor.toJson(),
        'updatedBy': actor.toJson(),
        'createdAt': now,
        'updatedAt': now,
      });
      transaction.set(historyReference, <String, dynamic>{
        'action': 'created',
        'actor': actor.toJson(),
        'changes': <String, dynamic>{
          'expectedDay': <String, dynamic>{
            'before': null,
            'after': expectedDay
          },
          'expectedNight': <String, dynamic>{
            'before': null,
            'after': expectedNight,
          },
        },
        'createdAt': now,
      });
    });

    return sheetId;
  }

  Future<void> updateTargets({
    required MonthlyPointingSheet sheet,
    required int expectedDay,
    required int expectedNight,
  }) async {
    final actor = _currentActor();
    final sheetReference = _sheets.doc(sheet.id);
    final historyReference = sheetReference.collection('history').doc();

    await _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(sheetReference);
      if (!snapshot.exists) {
        throw StateError('Cette fiche n’existe plus.');
      }
      final current = MonthlyPointingSheet.fromDocument(snapshot);
      if (current.expectedDay == expectedDay &&
          current.expectedNight == expectedNight) {
        return;
      }

      final now = FieldValue.serverTimestamp();
      transaction.update(sheetReference, <String, dynamic>{
        'expectedDay': expectedDay,
        'expectedNight': expectedNight,
        'updatedBy': actor.toJson(),
        'updatedAt': now,
      });
      transaction.set(historyReference, <String, dynamic>{
        'action': 'targets_updated',
        'actor': actor.toJson(),
        'changes': <String, dynamic>{
          'expectedDay': <String, dynamic>{
            'before': current.expectedDay,
            'after': expectedDay,
          },
          'expectedNight': <String, dynamic>{
            'before': current.expectedNight,
            'after': expectedNight,
          },
        },
        'createdAt': now,
      });
    });
  }

  Future<void> saveNote({
    required MonthlyPointingSheet sheet,
    required DateTime date,
    required String category,
    required String details,
  }) async {
    final actor = _currentActor();
    final key = MonthlyPointingCalculator.dayKey(date);
    final sheetReference = _sheets.doc(sheet.id);
    final historyReference = sheetReference.collection('history').doc();

    await _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(sheetReference);
      if (!snapshot.exists) {
        throw StateError('Cette fiche n’existe plus.');
      }
      final current = MonthlyPointingSheet.fromDocument(snapshot);
      final previous = current.notes[key];
      final next = PointingDayNote(
        category: category,
        details: details,
        updatedBy: actor,
      );
      final now = FieldValue.serverTimestamp();
      transaction.update(sheetReference, <String, dynamic>{
        'notes.$key': next.toJson(updatedAtValue: now),
        'updatedBy': actor.toJson(),
        'updatedAt': now,
      });
      transaction.set(historyReference, <String, dynamic>{
        'action': 'note_updated',
        'dayKey': key,
        'actor': actor.toJson(),
        'changes': <String, dynamic>{
          'note': <String, dynamic>{
            'before': previous?.displayText,
            'after': next.displayText,
          },
        },
        'createdAt': now,
      });
    });
  }

  Future<void> removeNote({
    required MonthlyPointingSheet sheet,
    required DateTime date,
  }) async {
    final key = MonthlyPointingCalculator.dayKey(date);
    final actor = _currentActor();
    final sheetReference = _sheets.doc(sheet.id);
    final historyReference = sheetReference.collection('history').doc();

    await _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(sheetReference);
      if (!snapshot.exists) {
        throw StateError('Cette fiche n’existe plus.');
      }
      final current = MonthlyPointingSheet.fromDocument(snapshot);
      final previous = current.notes[key];
      if (previous == null) return;

      final now = FieldValue.serverTimestamp();
      transaction.update(sheetReference, <String, dynamic>{
        'notes.$key': FieldValue.delete(),
        'updatedBy': actor.toJson(),
        'updatedAt': now,
      });
      transaction.set(historyReference, <String, dynamic>{
        'action': 'note_removed',
        'dayKey': key,
        'actor': actor.toJson(),
        'changes': <String, dynamic>{
          'note': <String, dynamic>{
            'before': previous.displayText,
            'after': null,
          },
        },
        'createdAt': now,
      });
    });
  }

  List<PointingSite> _parsePointings(
    QuerySnapshot<Map<String, dynamic>> snapshot,
  ) {
    final pointings = <PointingSite>[];
    for (final document in snapshot.docs) {
      try {
        pointings.add(PointingSite.fromJson(document.data()));
      } catch (error) {
        debugPrint(
          'Pointage ignoré dans le contrôle mensuel (${document.id}): $error',
        );
      }
    }
    return pointings;
  }

  PointingSheetActor _currentActor() {
    final manager = AuthService.currentManager;
    if (manager == null) {
      throw StateError('Aucun utilisateur connecté.');
    }
    return PointingSheetActor(
      uid: manager.UID,
      name: '${manager.firstName} ${manager.lastName}'.trim(),
      email: manager.email,
    );
  }

  static String monthKey(DateTime month) {
    return '${month.year.toString().padLeft(4, '0')}-'
        '${month.month.toString().padLeft(2, '0')}';
  }

  String _sheetId(String tenantId, String supervisorId, String monthKey) {
    final raw = '${tenantId}_${supervisorId}_$monthKey';
    return raw.replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_');
  }
}

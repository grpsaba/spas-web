import 'dart:typed_data';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../model.dart';
import '../services/access_control.dart';
import '../services/department_scope.dart';
import '../services/tenant_scope.dart';
import 'installation_order.dart';
import 'installation_catalog.dart';
import 'installation_numbering.dart';

class InstallationService {
  final _db = FirebaseFirestore.instance;
  CollectionReference<Map<String, dynamic>> get _orders =>
      _db.collection(installationOrdersCollection);

  bool get canView => AccessControl.canView(ModuleName.BON_MISE_EN_PLACE);
  bool get canAdd => AccessControl.canAdd(ModuleName.BON_MISE_EN_PLACE);
  bool get canReview => AccessControl.canValidate(ModuleName.BON_MISE_EN_PLACE);
  bool get canPrint => AccessControl.canPrint(ModuleName.BON_MISE_EN_PLACE);
  bool get canConfigureNumbering => AccessControl.isAdministrator;

  DocumentReference<Map<String, dynamic>> get _counter => _db
      .collection(InstallationNumbering.collection)
      .doc(InstallationNumbering.document);

  Stream<InstallationNumbering?> watchNumbering() {
    _require(canView && canReview);
    return _counter.snapshots().map((doc) =>
        doc.exists ? InstallationNumbering.fromJson(doc.data()!) : null);
  }

  Future<void> initializeNumbering(String lastUsedNumber) async {
    _require(canConfigureNumbering);
    final number = InstallationNumbering.parseLastNumber(lastUsedNumber);
    await _db.runTransaction((transaction) async {
      final existing = await transaction.get(_counter);
      if (existing.exists) {
        throw StateError('Le compteur est déjà initialisé. Rechargez la page.');
      }
      transaction.set(_counter, {
        'lastNumber': number,
        'lastOrderId': '',
        'updatedBy': actor['uid'],
        'updatedAt': FieldValue.serverTimestamp(),
      });
    });
  }

  List<String> get departments => ['security', 'cleaning']
      .where((id) => DepartmentScope.matchesDepartment(id))
      .toList();

  Map<String, dynamic> get actor {
    final manager = AccessControl.currentManager;
    if (manager == null) throw StateError('Connexion requise.');
    return {
      'uid': manager.UID,
      'type': 'manager',
      'name': '${manager.firstName} ${manager.lastName}'.trim()
    };
  }

  InstallationOrder newDraft() {
    _require(canView && canAdd);
    if (departments.isEmpty) throw StateError('Aucune prestation autorisée.');
    return InstallationOrder(
        id: _orders.doc().id,
        tenantId: TenantScope.tenantIdForWrite ?? TenantScope.currentTenantId,
        departmentId: departments.first,
        createdBy: actor,
        agents: [InstallationAgent()],
        equipment: [InstallationEquipment()]);
  }

  void _require(bool value) {
    if (!value) {
      throw StateError('Vous ne disposez pas des droits nécessaires.');
    }
  }

  void _scope(InstallationOrder order) {
    _require(canView &&
        TenantScope.matchesTenant(order.tenantId) &&
        DepartmentScope.matchesDepartment(order.departmentId));
  }

  bool canEdit(InstallationOrder order) => canReview
      ? order.status.reviewerCanEdit
      : canAdd && order.authorUid == actor['uid'] && order.status.authorCanEdit;

  Stream<List<InstallationOrder>> watchAll() {
    _require(canView);
    final query = DepartmentScope.applyToDepartmentQuery(
        TenantScope.applyToQuery(_orders));
    return query.snapshots().map((snapshot) {
      final result = snapshot.docs
          .map((doc) => InstallationOrder.fromJson(doc.id, doc.data()))
          .toList();
      result.sort((a, b) => (b.updatedAt ?? DateTime(2000))
          .compareTo(a.updatedAt ?? DateTime(2000)));
      return result;
    });
  }

  Future<InstallationOrder> one(String id) async {
    _require(canView);
    final snapshot = await _orders.doc(id).get();
    if (!snapshot.exists) throw StateError('Fiche introuvable.');
    final order = InstallationOrder.fromJson(id, snapshot.data()!);
    _scope(order);
    return order;
  }

  Future<InstallationOrder> save(InstallationOrder order) async {
    _scope(order);
    final ref = _orders.doc(order.id);
    await _db.runTransaction((transaction) async {
      final snapshot = await transaction.get(ref);
      final current = snapshot.exists
          ? InstallationOrder.fromJson(snapshot.id, snapshot.data()!)
          : null;
      if (current == null) {
        _require(canAdd &&
            order.revision == 0 &&
            order.status == InstallationStatus.draft &&
            order.authorUid == actor['uid']);
      } else {
        _scope(current);
        _require(canEdit(current));
        _sameVersion(current, order);
        _require(order.tenantId == current.tenantId);
        if (current.status == InstallationStatus.submitted) {
          final errors = order.validate();
          if (errors.isNotEmpty) throw StateError(errors.join('\n'));
        }
      }
      final data = order.toJson()
        ..['createdBy'] = current?.createdBy ?? actor
        ..['createdAt'] =
            snapshot.data()?['createdAt'] ?? FieldValue.serverTimestamp()
        ..['updatedAt'] = FieldValue.serverTimestamp()
        ..['revision'] = (current?.revision ?? 0) + 1
        ..['status'] = current?.status.name ?? InstallationStatus.draft.name
        ..['bonNumber'] = current?.bonNumber ?? ''
        ..['siteId'] = current?.siteId
        ..['attachments'] = current?.attachments ?? [];
      transaction.set(ref, data);
      transaction.set(
          ref.collection('events').doc(),
          _event(current == null ? 'created' : 'updated',
              current == null ? 'Fiche créée' : 'Informations mises à jour'));
    });
    return one(order.id);
  }

  Future<InstallationOrder> move(
      InstallationOrder order, InstallationStatus next,
      {String message = ''}) async {
    _scope(order);
    final ref = _orders.doc(order.id);
    // A conflicting counter can fail rules before its version precondition is
    // checked. Retry that case only when a server read proves it advanced.
    for (var attempt = 0;; attempt++) {
      int? counterBefore;
      try {
        await _db.runTransaction((transaction) async {
          final snapshot = await transaction.get(ref);
          if (!snapshot.exists) {
            throw StateError('Enregistrer la fiche avant de la transmettre.');
          }
          final current =
              InstallationOrder.fromJson(snapshot.id, snapshot.data()!);
          _scope(current);
          _sameVersion(current, order);
          _require(canReview || (canAdd && current.authorUid == actor['uid']));
          if (!current.status.canMoveTo(next, reviewer: canReview)) {
            throw StateError(
                'Cette étape n’est pas disponible pour cette fiche.');
          }
          if (next == InstallationStatus.changesRequested &&
              message.trim().isEmpty) {
            throw StateError('Indiquer les corrections demandées.');
          }
          int? allocatedNumber;
          if (next == InstallationStatus.approved &&
              current.bonNumber.isEmpty) {
            // Read before any write. Firestore retries if another approval uses
            // the counter, so allocation and approval always commit together.
            final counter = await transaction.get(_counter);
            if (!counter.exists) {
              throw StateError(
                  'Numérotation non initialisée : un administrateur doit renseigner '
                  'le dernier numéro utilisé dans la liste des bons.');
            }
            final numbering = InstallationNumbering.fromJson(counter.data()!);
            counterBefore = numbering.lastNumber;
            allocatedNumber = numbering.nextNumber;
            current.bonNumber = allocatedNumber.toString();
          }
          if (next == InstallationStatus.submitted ||
              next == InstallationStatus.approved) {
            final errors = current.validate(
                forApproval: next == InstallationStatus.approved,
                forSite: next == InstallationStatus.approved);
            if (errors.isNotEmpty) throw StateError(errors.join('\n'));
          }
          if (allocatedNumber != null) {
            transaction.update(_counter, {
              'lastNumber': allocatedNumber,
              'lastOrderId': current.id,
              'updatedBy': actor['uid'],
              'updatedAt': FieldValue.serverTimestamp(),
            });
          }
          transaction.update(ref, {
            if (allocatedNumber != null) 'bonNumber': current.bonNumber,
            'status': next.name,
            'revision': current.revision + 1,
            'updatedAt': FieldValue.serverTimestamp()
          });
          transaction.set(ref.collection('events').doc(), {
            ..._event(
                'status',
                message.trim().isEmpty
                    ? '${next.label}${allocatedNumber == null ? '' : ' · Bon n° ${current.bonNumber}'}'
                    : message.trim()),
            'from': current.status.name,
            'to': next.name,
          });
        });
        break;
      } on FirebaseException catch (error) {
        if (error.code != 'permission-denied' ||
            counterBefore == null ||
            attempt >= 3) {
          rethrow;
        }
        final latest =
            await _counter.get(const GetOptions(source: Source.server));
        if (!latest.exists ||
            InstallationNumbering.fromJson(latest.data()!).lastNumber <=
                counterBefore!) {
          rethrow;
        }
      }
    }
    return one(order.id);
  }

  void _sameVersion(InstallationOrder current, InstallationOrder edited) {
    if (current.revision != edited.revision) {
      throw StateError(
          'Cette fiche a été modifiée entre-temps. Rechargez-la avant de continuer.');
    }
  }

  Map<String, dynamic> _event(String kind, String message) => {
        'kind': kind,
        'message': message,
        'author': actor,
        'at': FieldValue.serverTimestamp(),
      };

  Stream<QuerySnapshot<Map<String, dynamic>>> events(InstallationOrder order) {
    _scope(order);
    return _orders.doc(order.id).collection('events').orderBy('at').snapshots();
  }

  Future<void> comment(InstallationOrder order, String message) async {
    _scope(await one(order.id));
    _require(canReview || (canAdd && order.authorUid == actor['uid']));
    if (message.trim().isEmpty) return;
    if (message.length > 4000) {
      throw StateError('Commentaire limité à 4 000 caractères.');
    }
    await _orders
        .doc(order.id)
        .collection('events')
        .add(_event('comment', message.trim()));
  }

  Future<Map<String, List<InstallationOption>>> options(
      InstallationOrder order) async {
    _scope(order);
    final results = await Future.wait([
      _db
          .collection('Zones')
          .where('tenantId', isEqualTo: order.tenantId)
          .get(),
      DepartmentScope.applyToDepartmentQuery(_db
              .collection('Supervisors')
              .where('tenantId', isEqualTo: order.tenantId))
          .get(),
      _db.collection('categorieTools').get(),
    ]);
    List<InstallationOption> map(
            int index, String Function(Map<String, dynamic>) label) =>
        results[index].docs.map((doc) {
          final data = Map<String, dynamic>.from(doc.data());
          data['departmentId'] = departmentIdFromJson(data);
          return InstallationOption(doc.id, label(data), data);
        }).toList()
          ..sort((a, b) => a.label.compareTo(b.label));
    return {
      'zones': map(0, (data) => data['name'] as String? ?? ''),
      'supervisors':
          map(1, (data) => '${data['firstName']} ${data['lastName']}'),
      'catalog': installationCatalogOptions(
          {for (final doc in results[2].docs) doc.id: doc.data()}, departments),
    };
  }

  Future<InstallationOption> createEquipment(
      InstallationOrder order, String label, String departmentId) async {
    _scope(order);
    _require(canAdd || canReview);
    _require(DepartmentScope.matchesDepartment(departmentId));
    label = label.trim();
    if (label.isEmpty || label.contains('/') || label.length > 120) {
      throw StateError(
          'Désignation requise, sans / et limitée à 120 caractères.');
    }
    final ref = _db.collection('categorieTools').doc(label);
    final data = {
      'label': label,
      'tenantId': order.tenantId,
      'departmentId': departmentId,
      'department': {
        'id': departmentId,
        'label': departmentId == 'security' ? 'Sécurité' : 'Nettoyage',
        'active': true
      }
    };
    await _db.runTransaction((transaction) async {
      final existing = await transaction.get(ref);
      if (existing.exists) {
        final value = existing.data()!;
        if (departmentIdFromJson(value) != departmentId) {
          throw StateError(
              'Cette désignation existe pour une autre prestation. Utilisez une désignation distincte.');
        }
      } else {
        transaction.set(ref, data);
      }
    });
    return InstallationOption(ref.id, label, data);
  }

  Future<InstallationOrder> attach(
      InstallationOrder order, String filename, Uint8List bytes) async {
    final current = await one(order.id);
    _scope(current);
    _require(canReview || (canAdd && current.authorUid == actor['uid']));
    if (current.status == InstallationStatus.finalized) {
      throw StateError('La fiche finalisée ne peut plus être modifiée.');
    }
    if (bytes.isEmpty || bytes.length > 10 * 1024 * 1024) {
      throw StateError('Le document doit peser moins de 10 Mo.');
    }
    final extension = filename.split('.').last.toLowerCase();
    final types = {
      'pdf': 'application/pdf',
      'png': 'image/png',
      'jpg': 'image/jpeg',
      'jpeg': 'image/jpeg'
    };
    final type = types[extension];
    if (type == null) throw StateError('Choisir une photo JPG/PNG ou un PDF.');
    final path =
        'site-installation-orders/${order.tenantId}/${order.id}/${_orders.doc().id}.$extension';
    await _orders
        .doc(order.id)
        .collection('uploads')
        .doc(path.split('/').last)
        .set({
      'uid': actor['uid'],
      'tenantId': order.tenantId,
      'path': path,
      'contentType': type,
      'at': FieldValue.serverTimestamp(),
      'expiresAt':
          Timestamp.fromDate(DateTime.now().add(const Duration(minutes: 15))),
    });
    final storage = FirebaseStorage.instance.ref(path);
    await storage.putData(bytes, SettableMetadata(contentType: type));
    final url = await storage.getDownloadURL();
    try {
      await _db.runTransaction((transaction) async {
        final snapshot = await transaction.get(_orders.doc(order.id));
        final latest =
            InstallationOrder.fromJson(snapshot.id, snapshot.data()!);
        _scope(latest);
        if (latest.status == InstallationStatus.finalized) {
          throw StateError('La fiche a déjà été finalisée.');
        }
        transaction.update(snapshot.reference, {
          'attachments': [
            ...latest.attachments,
            {'name': filename, 'path': path, 'url': url, 'contentType': type}
          ],
          'revision': latest.revision + 1,
          'updatedAt': FieldValue.serverTimestamp(),
        });
        transaction.set(snapshot.reference.collection('events').doc(),
            _event('attachment', 'Document ajouté : $filename'));
      });
    } catch (_) {
      await storage.delete();
      rethrow;
    }
    return one(order.id);
  }

  Future<InstallationOrder> finalize(InstallationOrder order,
      {required String code,
      required String email,
      required String password}) async {
    _scope(order);
    _require(canReview);
    final current = await one(order.id);
    if (current.status == InstallationStatus.finalized) return current;
    _sameVersion(current, order);
    if (current.status != InstallationStatus.signedReturned) {
      throw StateError('Confirmer le retour signé avant de créer le site.');
    }
    final errors = current.validate(forSite: true);
    if (code.trim().isEmpty) errors.add('Code du site requis.');
    if (!RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(email.trim())) {
      errors.add('Email invalide.');
    }
    if (password.length < 8) {
      errors.add('Mot de passe de huit caractères minimum.');
    }
    if (errors.isNotEmpty) throw StateError(errors.join('\n'));

    // Keep only non-secret recovery information if the browser loses the
    // connection between Auth account creation and the Firestore transaction.
    final preferences = await SharedPreferences.getInstance();
    final recoveryKey =
        'installation-account:${Firebase.app().options.projectId}:${current.id}';
    final raw = preferences.getString(recoveryKey);
    final recovery = raw == null ? null : installationMap(jsonDecode(raw));
    final app = await Firebase.initializeApp(
        name: 'installation-${current.id}', options: Firebase.app().options);
    final secondaryAuth = FirebaseAuth.instanceFor(app: app);
    try {
      User user;
      if (recovery != null) {
        if (recovery['email'] != email.trim()) {
          throw StateError(
              'Reprendre avec l’email ${recovery['email']} utilisé lors de la première tentative.');
        }
        user = (await secondaryAuth.signInWithEmailAndPassword(
                email: email.trim(), password: password))
            .user!;
        if (user.uid != recovery['uid']) {
          throw StateError(
              'Le compte récupéré ne correspond pas à cette fiche.');
        }
      } else {
        user = (await secondaryAuth.createUserWithEmailAndPassword(
                email: email.trim(), password: password))
            .user!;
        final stored = await preferences.setString(
            recoveryKey, jsonEncode({'uid': user.uid, 'email': email.trim()}));
        if (!stored) {
          await user.delete();
          throw StateError(
              'Impossible de conserver les informations de reprise. Réessayer.');
        }
      }
      final siteRef = _db.collection('Sites').doc(user.uid);
      await _db.runTransaction((tx) async {
        final snapshot = await tx.get(_orders.doc(current.id));
        final existingSite = await tx.get(siteRef);
        final latest = InstallationOrder.fromJson(current.id, snapshot.data()!);
        _scope(latest);
        _require(canReview);
        if (latest.status == InstallationStatus.finalized &&
            latest.siteId != null) {
          return;
        }
        _sameVersion(latest, current);
        if (latest.status != InstallationStatus.signedReturned) {
          throw StateError('Le statut de la fiche a changé.');
        }
        final primary = await tx.get(_db
            .collection('Supervisors')
            .doc(latest.supervisor!['UID'] as String));
        final secondaryId = latest.supervisor2?['UID'] as String?;
        final secondary = secondaryId == null
            ? null
            : await tx.get(_db.collection('Supervisors').doc(secondaryId));
        final zone = await tx.get(
            _db.collection('Zones').doc(latest.zone!['codeZone'] as String));
        for (final supervisor in [primary, if (secondary != null) secondary]) {
          final value = supervisor.data();
          if (value == null ||
              value['actif'] == false ||
              value['isPortal'] == true ||
              value['tenantId'] != latest.tenantId ||
              departmentIdFromJson(value) != latest.departmentId) {
            throw StateError(
                'Superviseur inactif ou hors du périmètre de la fiche.');
          }
        }
        if (!zone.exists ||
            zone.data()!['tenantId'] != latest.tenantId ||
            secondaryId == primary.id) {
          throw StateError(
              'Vérifier la zone et choisir des superviseurs distincts.');
        }
        if (existingSite.exists) {
          throw StateError('Ce compte est déjà lié à un site.');
        }
        tx.set(siteRef, {
          'UID': user.uid,
          'codeSite': code.trim(),
          'name': latest.siteName.trim(),
          'adresse': latest.address.trim(),
          'phone': latest.phone,
          'email': email.trim(),
          'latLng': latest.latitude == null
              ? null
              : {'lat': latest.latitude, 'lng': latest.longitude},
          'supervisor': primary.data(),
          'supervisor_2': secondary?.data(),
          'zone': zone.data(),
          'actif': true,
          'tenantId': latest.tenantId,
          'departmentIds': [latest.departmentId],
          'nbAgent': latest.agentCount,
          'nbRonde': latest.roundCount,
          'pointageType': latest.pointageType,
          'dateContrat': latest.contractDate!.toIso8601String(),
          'token': '',
          'sos': false,
          'installationOrderId': latest.id,
        });
        tx.update(snapshot.reference, {
          'status': 'finalized',
          'siteId': user.uid,
          'revision': latest.revision + 1,
          'updatedAt': FieldValue.serverTimestamp(),
          'finalizedBy': actor['uid'],
          'finalizedAt': FieldValue.serverTimestamp()
        });
        tx.set(snapshot.reference.collection('events').doc(), {
          ..._event('status', 'Site actif créé'),
          'from': 'signedReturned',
          'to': 'finalized'
        });
      });
      final finalized = await one(order.id);
      if (finalized.siteId != user.uid) await user.delete();
      await preferences.remove(recoveryKey);
      return finalized;
    } finally {
      await secondaryAuth.signOut();
      await app.delete();
    }
  }
}

import 'package:cloud_firestore/cloud_firestore.dart';

const installationOrdersCollection = 'siteInstallationOrders';

enum InstallationStatus {
  draft,
  submitted,
  changesRequested,
  approved,
  awaitingSignature,
  signedReturned,
  finalized,
}

extension InstallationStatusLabel on InstallationStatus {
  String get label => const {
        InstallationStatus.draft: 'Brouillon',
        InstallationStatus.submitted: 'À vérifier',
        InstallationStatus.changesRequested: 'À corriger',
        InstallationStatus.approved: 'Bon prêt à imprimer',
        InstallationStatus.awaitingSignature: 'En attente du retour signé',
        InstallationStatus.signedReturned: 'Retour signé reçu',
        InstallationStatus.finalized: 'Site créé',
      }[this]!;

  bool get authorCanEdit =>
      this == InstallationStatus.draft ||
      this == InstallationStatus.changesRequested;

  bool get reviewerCanEdit =>
      authorCanEdit || this == InstallationStatus.submitted;

  bool canMoveTo(InstallationStatus next, {required bool reviewer}) {
    if (!reviewer) {
      return authorCanEdit && next == InstallationStatus.submitted;
    }
    if (next == InstallationStatus.changesRequested) {
      return this != InstallationStatus.draft &&
          this != InstallationStatus.finalized &&
          this != InstallationStatus.changesRequested;
    }
    return (authorCanEdit && next == InstallationStatus.submitted) ||
        (this == InstallationStatus.submitted &&
            next == InstallationStatus.approved) ||
        (this == InstallationStatus.approved &&
            next == InstallationStatus.awaitingSignature) ||
        (this == InstallationStatus.awaitingSignature &&
            next == InstallationStatus.signedReturned);
    // Finalization uses a separate transaction, restricted to web reviewers.
  }
}

DateTime? installationDate(dynamic value) {
  if (value is Timestamp) return value.toDate();
  if (value is DateTime) return value;
  return value is String ? DateTime.tryParse(value) : null;
}

Map<String, dynamic> installationMap(dynamic value) =>
    value is Map ? Map<String, dynamic>.from(value) : <String, dynamic>{};

class InstallationOption {
  const InstallationOption(this.id, this.label, [this.data = const {}]);
  final String id;
  final String label;
  final Map<String, dynamic> data;
}

class InstallationAgent {
  InstallationAgent(
      {String? id, this.name = '', this.type = '', this.phone = ''})
      : id = id ?? FirebaseFirestoreId.next();
  final String id;
  String name;
  String type;
  String phone;
  factory InstallationAgent.fromJson(Map<String, dynamic> data) =>
      InstallationAgent(
        id: data['id'] as String?,
        name: data['name'] as String? ?? '',
        type: data['type'] as String? ?? '',
        phone: data['phone'] as String? ?? '',
      );
  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name.trim(),
        'type': type.trim(),
        'phone': phone.trim()
      };
}

class InstallationEquipment {
  InstallationEquipment({
    String? id,
    this.catalogId,
    this.designation = '',
    this.quantity = 1,
  }) : id = id ?? FirebaseFirestoreId.next();
  final String id;
  String? catalogId;
  String designation;
  int quantity;
  bool get needsCatalogEntry => catalogId == null || catalogId!.isEmpty;
  factory InstallationEquipment.fromJson(Map<String, dynamic> data) =>
      InstallationEquipment(
        id: data['id'] as String?,
        catalogId: data['catalogId'] as String?,
        designation: data['designation'] as String? ?? '',
        quantity: (data['quantity'] as num?)?.toInt() ?? 0,
      );
  Map<String, dynamic> toJson() => {
        'id': id,
        'catalogId': catalogId,
        'designation': designation.trim(),
        'quantity': quantity,
        'needsCatalogEntry': needsCatalogEntry,
      };
}

// Stable local row keys; order IDs are Firestore-generated, including offline.
class FirebaseFirestoreId {
  static int _sequence = 0;
  static String next() =>
      '${DateTime.now().microsecondsSinceEpoch}_${_sequence++}';
}

class InstallationOrder {
  InstallationOrder({
    required this.id,
    required this.tenantId,
    required this.departmentId,
    required this.createdBy,
    this.status = InstallationStatus.draft,
    this.revision = 0,
    this.siteName = '',
    this.clientName = '',
    this.address = '',
    this.phone = '',
    this.bonNumber = '',
    this.latitude,
    this.longitude,
    this.contractDate,
    this.zone,
    this.supervisor,
    this.supervisor2,
    this.agentCount = 0,
    this.roundCount = 1,
    this.pointageType = 'jour',
    List<InstallationAgent>? agents,
    List<InstallationEquipment>? equipment,
    this.createdAt,
    this.updatedAt,
    this.siteId,
    List<Map<String, dynamic>>? attachments,
  })  : agents = agents ?? [],
        equipment = equipment ?? [],
        attachments = attachments ?? [];

  final String id;
  final String tenantId;
  String departmentId;
  final Map<String, dynamic> createdBy;
  InstallationStatus status;
  int revision;
  String siteName;
  String clientName;
  String address;
  String phone;
  String bonNumber;
  double? latitude;
  double? longitude;
  DateTime? contractDate;
  Map<String, dynamic>? zone;
  Map<String, dynamic>? supervisor;
  Map<String, dynamic>? supervisor2;
  int agentCount;
  int roundCount;
  String pointageType;
  final List<InstallationAgent> agents;
  final List<InstallationEquipment> equipment;
  DateTime? createdAt;
  DateTime? updatedAt;
  String? siteId;
  final List<Map<String, dynamic>> attachments;

  bool get isSecurity => departmentId == 'security';
  String get serviceLabel => isSecurity ? 'Sécurité' : 'Nettoyage';
  String get authorName => createdBy['name'] as String? ?? '';
  String get authorUid => createdBy['uid'] as String? ?? '';

  factory InstallationOrder.fromJson(String id, Map<String, dynamic> data) {
    final statusName = data['status'];
    // Unknown remote states must never become editable drafts.
    final status = InstallationStatus.values.firstWhere(
      (value) => value.name == statusName,
      orElse: () => throw const FormatException('Statut de fiche inconnu.'),
    );
    return InstallationOrder(
      id: id,
      tenantId: data['tenantId'] as String? ?? '',
      departmentId: data['departmentId'] as String? ?? '',
      createdBy: installationMap(data['createdBy']),
      status: status,
      revision: (data['revision'] as num?)?.toInt() ?? 0,
      siteName: data['siteName'] as String? ?? '',
      clientName: data['clientName'] as String? ?? '',
      address: data['address'] as String? ?? '',
      phone: data['phone'] as String? ?? '',
      bonNumber: data['bonNumber'] as String? ?? '',
      latitude: (data['latitude'] as num?)?.toDouble(),
      longitude: (data['longitude'] as num?)?.toDouble(),
      contractDate: installationDate(data['contractDate']),
      zone: data['zone'] is Map ? installationMap(data['zone']) : null,
      supervisor: data['supervisor'] is Map
          ? installationMap(data['supervisor'])
          : null,
      supervisor2: data['supervisor2'] is Map
          ? installationMap(data['supervisor2'])
          : null,
      agentCount: (data['agentCount'] as num?)?.toInt() ?? 0,
      roundCount: (data['roundCount'] as num?)?.toInt() ?? 1,
      pointageType: data['pointageType'] as String? ?? 'jour',
      agents: (data['agents'] as List? ?? [])
          .map((value) => InstallationAgent.fromJson(installationMap(value)))
          .toList(),
      equipment: (data['equipment'] as List? ?? [])
          .map(
              (value) => InstallationEquipment.fromJson(installationMap(value)))
          .toList(),
      createdAt: installationDate(data['createdAt']),
      updatedAt: installationDate(data['updatedAt']),
      siteId: data['siteId'] as String?,
      attachments:
          (data['attachments'] as List? ?? []).map(installationMap).toList(),
    );
  }

  Map<String, dynamic> toJson() => {
        'schemaVersion': 1,
        'tenantId': tenantId,
        'departmentId': departmentId,
        'createdBy': createdBy,
        'status': status.name,
        'revision': revision,
        'siteName': siteName.trim(),
        'clientName': clientName.trim(),
        'address': address.trim(),
        'phone': phone.trim(),
        'bonNumber': bonNumber.trim(),
        'latitude': latitude,
        'longitude': longitude,
        'contractDate': contractDate?.toIso8601String(),
        'zone': zone,
        'supervisor': supervisor,
        'supervisor2': supervisor2,
        'agentCount': agentCount,
        'roundCount': roundCount,
        'pointageType': pointageType,
        'agents': agents.map((value) => value.toJson()).toList(),
        'equipment': equipment.map((value) => value.toJson()).toList(),
        'createdAt': createdAt?.toIso8601String(),
        'updatedAt': updatedAt?.toIso8601String(),
        'siteId': siteId,
        'attachments': attachments,
      };

  InstallationOrder copy() => InstallationOrder.fromJson(id, toJson());

  List<String> validate({bool forApproval = false, bool forSite = false}) {
    final errors = <String>[];
    if (siteName.trim().isEmpty) errors.add('Renseigner le nom du site.');
    if (clientName.trim().isEmpty) errors.add('Renseigner le client.');
    if (address.trim().isEmpty) errors.add('Renseigner l’adresse du site.');
    if (!['security', 'cleaning'].contains(departmentId)) {
      errors.add('Choisir la prestation.');
    }
    if (agents.any((agent) => agent.name.trim().isEmpty)) {
      errors
          .add('Compléter le nom de chaque agent ou supprimer la ligne vide.');
    }
    if (equipment
        .any((item) => item.designation.trim().isEmpty || item.quantity <= 0)) {
      errors.add(
          'Chaque équipement doit avoir une désignation et une quantité positive.');
    }
    if ((forApproval || forSite) && bonNumber.trim().isEmpty) {
      errors.add('Le numéro du bon doit être attribué à la validation.');
    }
    if (forSite) {
      if (zone?['codeZone'] is! String ||
          (zone!['codeZone'] as String).isEmpty) {
        errors.add('Choisir une zone.');
      }
      if (supervisor?['UID'] is! String ||
          (supervisor!['UID'] as String).isEmpty) {
        errors.add('Choisir le superviseur du site.');
      }
      if (supervisor2?['UID'] != null &&
          supervisor2?['UID'] == supervisor?['UID']) {
        errors.add('Choisir deux superviseurs distincts.');
      }
      if (!['jour', 'nuit', 'jour_nuit'].contains(pointageType)) {
        errors.add('Choisir un type de pointage valide.');
      }
      if (contractDate == null) errors.add('Renseigner la date du contrat.');
      if (agentCount <= 0) errors.add('Renseigner l’effectif prévu.');
      if (roundCount <= 0) errors.add('Le nombre de rondes doit être positif.');
      if (latitude == null ||
          !latitude!.isFinite ||
          latitude!.abs() > 90 ||
          longitude == null ||
          !longitude!.isFinite ||
          longitude!.abs() > 180) {
        errors.add('Renseigner des coordonnées GPS valides.');
      }
    }
    return errors;
  }
}

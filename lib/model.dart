import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

class TenantDefaults {
  static const String maliTenantId = 'ml';
  static const String defaultTenantId = maliTenantId;
}

class TenantPointageMode {
  static const String photo = 'photo';
  static const String geo = 'geo';

  static String normalize(Object? value) {
    final mode = value
        ?.toString()
        .trim()
        .toLowerCase()
        .replaceAll('\u00e9', 'e')
        .replaceAll('\u00e8', 'e')
        .replaceAll('\u00ea', 'e')
        .replaceAll('\u00eb', 'e');
    if (mode == geo ||
        mode == 'gps' ||
        mode == 'location' ||
        mode == 'geolocation' ||
        mode == 'geolocalisation') {
      return geo;
    }
    return photo;
  }
}

String normalizeProfileNameForAccess(String? value) {
  return (value ?? '')
      .trim()
      .toLowerCase()
      .replaceAll('\u00e0', 'a')
      .replaceAll('\u00e2', 'a')
      .replaceAll('\u00e7', 'c')
      .replaceAll('\u00e9', 'e')
      .replaceAll('\u00e8', 'e')
      .replaceAll('\u00ea', 'e')
      .replaceAll('\u00eb', 'e')
      .replaceAll('\u00ee', 'i')
      .replaceAll('\u00ef', 'i')
      .replaceAll('\u00f4', 'o')
      .replaceAll('\u00f9', 'u')
      .replaceAll('\u00fb', 'u')
      .replaceAll('\u00fc', 'u');
}

bool canBypassTenantForProfile(Profil? profil) {
  final profileName = normalizeProfileNameForAccess(profil?.name);
  return profileName == 'administrateur' ||
      profileName == 'directeur general';
}

String tenantIdFromJson(Map<String, dynamic> json) {
  final value = json['tenantId'];
  if (value is String && value.trim().isNotEmpty) return value.trim();
  return TenantDefaults.defaultTenantId;
}

bool hasTenantIdInJson(Map<String, dynamic> json) {
  final value = json['tenantId'];
  return value is String && value.trim().isNotEmpty;
}

DateTime? dateTimeFromJsonValue(Object? value) {
  if (value == null) return null;
  if (value is DateTime) return value;
  if (value is Timestamp) return value.toDate();
  if (value is String) return DateTime.tryParse(value);
  return null;
}

String? departmentIdFromJson(Map<String, dynamic> json) {
  final value = json['departmentId'];
  if (value is String && value.trim().isNotEmpty) {
    return normalizeDepartmentId(value);
  }

  final department = json['department'];
  if (department is Map) {
    final id = department['id'];
    if (id is String && id.trim().isNotEmpty) return normalizeDepartmentId(id);

    final label = department['label'];
    if (label is String && label.trim().isNotEmpty) {
      return normalizeDepartmentId(label);
    }
  }

  return null;
}

class DepartmentScopeValue {
  static const String all = 'all';
  static const String limited = 'limited';

  static String normalize(String? value) {
    final normalized = value?.trim().toLowerCase();
    if (normalized == limited) return limited;
    if (_isLegacyDepartmentScope(normalized)) return limited;
    return all;
  }
}

String departmentScopeFromJson(Map<String, dynamic> json) {
  final value = json['departmentScope'];
  return DepartmentScopeValue.normalize(value is String ? value.trim() : null);
}

List<String> departmentIdsFromJson(Map<String, dynamic> json) {
  final value = json['departmentIds'];
  if (value is List) {
    final ids = value
        .whereType<String>()
        .map(normalizeDepartmentId)
        .where((id) => id.isNotEmpty)
        .toSet()
        .toList();
    if (ids.isNotEmpty) return ids;
  }

  final legacyScope = json['departmentScope'];
  if (legacyScope is String && _isLegacyDepartmentScope(legacyScope)) {
    return <String>[normalizeDepartmentId(legacyScope)];
  }

  return <String>[];
}

bool _isLegacyDepartmentScope(String? value) {
  const departmentIds = <String>{'security', 'cleaning', 'direction'};
  return departmentIds.contains(normalizeDepartmentId(value));
}

String normalizeDepartmentId(String? value) {
  final normalized = (value ?? '')
      .trim()
      .toLowerCase()
      .replaceAll('\u00e0', 'a')
      .replaceAll('\u00e2', 'a')
      .replaceAll('\u00e7', 'c')
      .replaceAll('\u00e9', 'e')
      .replaceAll('\u00e8', 'e')
      .replaceAll('\u00ea', 'e')
      .replaceAll('\u00eb', 'e')
      .replaceAll('\u00ee', 'i')
      .replaceAll('\u00ef', 'i')
      .replaceAll('\u00f4', 'o')
      .replaceAll('\u00f9', 'u')
      .replaceAll('\u00fb', 'u')
      .replaceAll('\u00fc', 'u')
      .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
      .replaceAll(RegExp(r'^-+|-+$'), '');

  switch (normalized) {
    case 'securite':
    case 'security':
      return 'security';
    case 'nettoyage':
    case 'cleaning':
      return 'cleaning';
    case 'direction':
      return 'direction';
    default:
      return normalized;
  }
}

String effectiveTenantId(
  String tenantId,
  Iterable<String?> candidates,
) {
  if (tenantId.trim().isNotEmpty &&
      tenantId != TenantDefaults.defaultTenantId) {
    return tenantId;
  }

  for (final candidate in candidates) {
    if (candidate != null &&
        candidate.trim().isNotEmpty &&
        candidate != TenantDefaults.defaultTenantId) {
      return candidate.trim();
    }
  }

  return tenantId.trim().isNotEmpty
      ? tenantId.trim()
      : TenantDefaults.defaultTenantId;
}

class Tenant extends Equatable {
  final String id;
  final String label;
  final String countryCode;
  final bool active;
  final String pointageMode;
  final String zoneChiefPointageMode;

  const Tenant({
    required this.id,
    required this.label,
    required this.countryCode,
    this.active = true,
    this.pointageMode = TenantPointageMode.photo,
    this.zoneChiefPointageMode = TenantPointageMode.photo,
  });

  factory Tenant.fromJson(Map<String, dynamic> json) {
    final pointageMode = TenantPointageMode.normalize(json['pointageMode']);
    return Tenant(
      id: json['id'] ?? '',
      label: json['label'] ?? '',
      countryCode: json['countryCode'] ?? '',
      active: json['active'] ?? true,
      pointageMode: pointageMode,
      zoneChiefPointageMode: TenantPointageMode.normalize(
        json['zoneChiefPointageMode'] ??
            json['zonePointageMode'] ??
            json['zoneChefPointageMode'] ??
            json['chefZonePointageMode'] ??
            pointageMode,
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'label': label,
      'countryCode': countryCode,
      'active': active,
      'pointageMode': pointageMode,
      'zoneChiefPointageMode': zoneChiefPointageMode,
    };
  }

  bool get usesPhotoPointing => pointageMode == TenantPointageMode.photo;
  bool get usesGeoPointing => pointageMode == TenantPointageMode.geo;
  bool get usesZoneChiefPhotoPointing =>
      zoneChiefPointageMode == TenantPointageMode.photo;
  bool get usesZoneChiefGeoPointing =>
      zoneChiefPointageMode == TenantPointageMode.geo;

  @override
  List<Object?> get props => [id];
}

class LatLngModel {
  double lat;
  double lng;

  LatLngModel({
    required this.lat,
    required this.lng,
  });

  factory LatLngModel.fromJson(Map<String, dynamic> json) {
    return LatLngModel(
      lat: json["lat"],
      lng: json["lng"],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "lat": lat,
      "lng": lng,
    };
  }
//
}

class SuperviseurLocaion {
  DateTime date;
  LatLngModel latlng;
  Supervisor? supervisor;
  String tenantId;
  String? departmentId;

  SuperviseurLocaion({
    required this.latlng,
    required this.date,
    required this.supervisor,
    this.tenantId = TenantDefaults.defaultTenantId,
    this.departmentId,
  });

  factory SuperviseurLocaion.fromJson(Map<String, dynamic> json) {
    return SuperviseurLocaion(
      date: DateTime.parse(json["date"]),
      latlng: LatLngModel.fromJson(json["latlng"]),
      supervisor: Supervisor.fromJson(json["supervisor"]),
      tenantId: tenantIdFromJson(json),
      departmentId: departmentIdFromJson(json),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "date": date.toIso8601String(),
      "latlng": latlng.toJson(),
      "supervisor": supervisor?.toJson(),
      "tenantId": effectiveTenantId(tenantId, [supervisor?.tenantId]),
      "departmentId": departmentId ?? supervisor?.departmentId,
    };
  }

  bool isToday() {
    DateTime today = DateTime.now();
    return date.year == today.year &&
        date.day == today.day &&
        date.month == today.month;
  }
}

class Supervisor {
  String UID;
  String code;
  String firstName;
  String lastName;
  String phone;
  String email;
  bool tracking;
  LatLngModel? latlng;
  String token;
  bool? actif;
  String tenantId;
  String? departmentId;
  bool hasTenantId;
  final bool isSpecial;
  Department? department;
  Zone? zone;
  Supervisor(
      {required this.UID,
      required this.code,
      required this.firstName,
      required this.lastName,
      required this.phone,
      required this.email,
      required this.token,
      required this.tracking,
      required this.latlng,
      required this.actif,
      this.tenantId = TenantDefaults.defaultTenantId,
      this.departmentId,
      this.hasTenantId = false,
      this.isSpecial = false,
      this.zone,
      required this.department});

  factory Supervisor.fromJson(Map<String, dynamic> json) {
    if (json["UID"] == null ||
        json["code"] == null ||
        json["firstName"] == null ||
        json["lastName"] == null ||
        json["phone"] == null ||
        json["email"] == null ||
        json['token'] == null ||
        json["tracking"] == null) {
      print("object");
    }
    return Supervisor(
      UID: json["UID"],
      code: json["code"] ?? "",
      firstName: json["firstName"],
      lastName: json["lastName"],
      phone: json["phone"],
      email: json["email"] ?? "",
      token: json['token'] ?? "",
      zone: json["zone"] == null ? null : Zone.fromJson(json["zone"]),
      actif: json['actif'] ?? true,
      tenantId: tenantIdFromJson(json),
      departmentId: departmentIdFromJson(json),
      hasTenantId: hasTenantIdInJson(json),
      isSpecial: json['isSpecial'] ?? false,
      tracking: json["tracking"] ?? true,
      department: json['department'] == null
          ? null
          : Department.fromJson(json['department']),
      latlng:
          json["latlng"] != null ? LatLngModel.fromJson(json["latlng"]) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "UID": UID,
      "code": code,
      "firstName": firstName,
      "lastName": lastName,
      "phone": phone,
      "email": email,
      'token': token,
      "tracking": tracking,
      'actif': actif,
      "tenantId": tenantId,
      "departmentId": departmentId ?? department?.id,
      "latlng": latlng?.toJson(),
      "isSpecial": isSpecial,
      "zone": zone?.toJson(),
      "department": department?.toJson()
    };
  }
//
}

class DocumentFile extends Equatable {
  String title;
  String path;
  String extention;
  DocumentFile(
      {required this.title, required this.path, required this.extention});

  factory DocumentFile.fromJson(Map<String, dynamic> json) {
    return DocumentFile(
      title: json["title"],
      path: json["path"],
      extention: json["extention"],
    );
  }

  Map<String, dynamic> toJson() {
    return {"title": title, "path": path, "extention": extention};
  }

  @override
  // TODO: implement props
  List<Object?> get props => [path];
//
}

class ConactReference extends Equatable {
  String title;
  String contact;
  bool certified;
  ConactReference(
      {required this.title, required this.contact, required this.certified});

  factory ConactReference.fromJson(Map<String, dynamic> json) {
    return ConactReference(
      title: json["title"],
      contact: json["contact"],
      certified: json["certified"],
    );
  }

  Map<String, dynamic> toJson() {
    return {"title": title, "contact": contact, "certified": certified};
  }

  @override
  // TODO: implement props
  List<Object?> get props => [contact];
//
}

class Agent extends Equatable {
  String code;
  String firstName;
  String lastName;
  String phone;
  String email;
  bool tracking;
  Department? department;
  String tenantId;
  String? departmentId;
  Site? site;
  AgentType? typeAgent;
  bool? actif;
  bool? active;
  List<DocumentFile>? docs;
  List<ConactReference>? contacts;
  DateTime? dateEmbauche;
  DateTime? dateArret;
  Agent(
      {required this.code,
      required this.firstName,
      required this.lastName,
      required this.phone,
      required this.email,
      required this.tracking,
      required this.site,
      required this.department,
      this.tenantId = TenantDefaults.defaultTenantId,
      this.departmentId,
      required this.typeAgent,
      required this.actif,
      required this.docs,
      required this.contacts,
      required this.dateEmbauche,
      required this.dateArret});

  factory Agent.fromJson(Map<String, dynamic> json) {
    List docs = json["docs"] ?? [];
    List contacts = json["contacts"] ?? [];
    return Agent(
      code: json["code"],
      dateEmbauche: json["dateEmbauche"] != null
          ? DateTime.tryParse(json["dateEmbauche"])
          : null,
      dateArret: json["dateArret"] != null
          ? DateTime.tryParse(json["dateArret"])
          : null,
      firstName: json["firstName"],
      lastName: json["lastName"],
      phone: json["phone"],
      email: json["email"],
      tracking: json["tracking"],
      docs: docs.map((e) => DocumentFile.fromJson(e)).toList(),
      contacts: contacts.map((e) => ConactReference.fromJson(e)).toList(),
      typeAgent: json["AgentType"] == null
          ? AgentType(label: "FIXE")
          : AgentType.fromJson(json["AgentType"]),
      site: json["site"] == null ? null : Site.fromJson(json["site"]),
      actif: json["actif"] ?? true,
      tenantId: tenantIdFromJson(json),
      departmentId: departmentIdFromJson(json),
      department: json["department"] == null
          ? null
          : Department.fromJson(json["department"]),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "docs": docs?.map((e) => e.toJson()),
      "contacts": contacts?.map((e) => e.toJson()),
      "code": code,
      "firstName": firstName,
      "lastName": lastName,
      "phone": phone,
      "email": email,
      "tracking": tracking,
      "site": site?.toJson(),
      "actif": actif,
      "tenantId": effectiveTenantId(tenantId, [site?.tenantId]),
      "departmentId": departmentId ?? department?.id,
      "department": department?.toJson(),
      "AgentType": typeAgent?.toJson(),
      "dateEmbauche": dateEmbauche?.toIso8601String(),
      "dateArret": dateArret?.toIso8601String()
    };
  }

  @override
  // TODO: implement props
  List<Object?> get props => [code];

  // void genererCode() {}
  void genererCode() {
    for (int i = 1; i <= 4; i++) {
      int num = Random().nextInt(9);
      code += "$num";
    }

    code = "${department?.label.substring(0, 3) ?? "SEC"}$code$phone";
  }
//

//
}

class Site extends Equatable {
  String UID;
  String codeSite;
  String name;
  String adresse;
  String email;
  String phone;
  Supervisor? supervisor;
  Supervisor? supervisor_2;
  LatLngModel latLng;
  String token;
  int nbAgent;
  bool? actif;
  bool sos;
  Zone? zone;
  String tenantId;
  List<String> departmentIds;
  int? nbRonde;
  DateTime? dateContrat;
  String pointageType;
  Site(
      {required this.UID,
      required this.codeSite,
      required this.name,
      required this.adresse,
      required this.email,
      required this.phone,
      required this.latLng,
      required this.token,
      required this.nbAgent,
      required this.supervisor,
      required this.supervisor_2,
      this.sos = false,
      required this.actif,
      required this.zone,
      this.tenantId = TenantDefaults.defaultTenantId,
      List<String>? departmentIds,
      required this.dateContrat,
      required this.nbRonde,
      this.pointageType = 'jour'})
      : departmentIds = (departmentIds ?? <String>[])
            .map(normalizeDepartmentId)
            .where((id) => id.isNotEmpty)
            .toSet()
            .toList();

  factory Site.fromJson(Map<String, dynamic> json) {
    //verifier si une valeuir est null avant de la parser

    return Site(
        UID: json["UID"] ?? "",
        codeSite: json["codeSite"] ?? "",
        name: json["name"] ?? "",
        adresse: json["adresse"] ?? "",
        email: json["email"] ?? "",
        token: json['token'] ?? "",
        actif: json['actif'] ?? true,
        nbRonde: json['nbRonde'] ?? 1,
        nbAgent: json['nbAgent'] ?? 0,
        tenantId: tenantIdFromJson(json),
        departmentIds: (json['departmentIds'] as List?)
                ?.whereType<String>()
                .map(normalizeDepartmentId)
                .where((id) => id.isNotEmpty)
                .toList() ??
            <String>[],
        dateContrat: json['dateContrat'] != null
            ? dateTimeFromJsonValue(json['dateContrat'])
            : DateTime.now(),
        zone: json["zone"] == null ? null : Zone.fromJson(json["zone"]),
        supervisor: json["supervisor"] == null
            ? null
            : Supervisor.fromJson(json["supervisor"]),
        supervisor_2: json["supervisor_2"] == null
            ? null
            : Supervisor.fromJson(json["supervisor_2"]),
        latLng: json["latLng"] == null
            ? LatLngModel(lat: 0, lng: 0)
            : LatLngModel.fromJson(json["latLng"]),
        sos: json["sos"] ?? false,
        phone: json["phone"] ?? "",
        pointageType: json['pointageType'] ?? 'jour');
  }

  Map<String, dynamic> toJson() {
    return {
      "UID": UID,
      "codeSite": codeSite,
      "name": name,
      "adresse": adresse,
      "email": email,
      "zone": zone?.toJson(),
      "supervisor": supervisor?.toJson(),
      "supervisor_2": supervisor_2?.toJson(),
      "latLng": latLng.toJson(),
      "sos": sos,
      'token': token,
      'phone': phone,
      'nbAgent': nbAgent,
      'actif': actif,
      'tenantId': tenantId,
      'departmentIds': _effectiveDepartmentIds(),
      'nbRonde': nbRonde ?? 1,
      'pointageType': pointageType,
      'dateContrat': dateContrat != null
          ? dateContrat?.toIso8601String()
          : DateTime.now().toIso8601String()
    };
  }

  List<String> _effectiveDepartmentIds() {
    final ids = <String>{
      ...departmentIds.map(normalizeDepartmentId),
      normalizeDepartmentId(supervisor?.departmentId),
      normalizeDepartmentId(supervisor?.department?.id),
      normalizeDepartmentId(supervisor_2?.departmentId),
      normalizeDepartmentId(supervisor_2?.department?.id),
    }..removeWhere((id) => id.isEmpty);

    return ids.toList();
  }

  @override
  // TODO: implement props
  List<Object?> get props => [UID];
//

//

//
}

class Zone extends Equatable {
  String codeZone;
  String name;
  String tenantId;
  Zone({
    required this.codeZone,
    required this.name,
    this.tenantId = TenantDefaults.defaultTenantId,
  });

  factory Zone.fromJson(Map<String, dynamic> json) {
    if (json["codeZone"] == null || json["name"] == null) {
      print("object");
    }
    return Zone(
      codeZone: json["codeZone"],
      name: json["name"],
      tenantId: tenantIdFromJson(json),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "codeZone": codeZone,
      "name": name,
      "tenantId": tenantId,
    };
  }

  @override
  // TODO: implement props
  List<Object?> get props => [codeZone];
//

//

//
}

class ZoneMember extends Equatable {
  String UID;
  String code;
  String firstName;
  String lastName;
  String phone;
  String email;
  bool? actif;
  String? poste;
  Zone? zone;
  String token;
  String tenantId;
  String? departmentId;
  ZoneMember(
      {required this.UID,
      required this.code,
      required this.firstName,
      required this.lastName,
      required this.phone,
      required this.email,
      required this.actif,
      required this.poste,
      required this.zone,
      this.tenantId = TenantDefaults.defaultTenantId,
      this.departmentId,
      this.token = ""});

  factory ZoneMember.fromJson(Map<String, dynamic> json) {
    return ZoneMember(
      UID: json["UID"],
      code: json["code"],
      firstName: json["firstName"],
      lastName: json["lastName"],
      phone: json["phone"],
      email: json["email"],
      token: json["token"],
      actif: json['actif'] ?? true,
      tenantId: tenantIdFromJson(json),
      departmentId: departmentIdFromJson(json),
      poste: json['poste'],
      zone: Zone.fromJson(json['zone']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "UID": UID,
      "code": code,
      "firstName": firstName,
      "lastName": lastName,
      "phone": phone,
      "email": email,
      "token": token,
      "zone": zone?.toJson(),
      "tenantId": effectiveTenantId(tenantId, [zone?.tenantId]),
      "departmentId": departmentId,
      'actif': actif,
      "poste": poste
    };
  }

  @override
  // TODO: implement props
  List<Object?> get props => [UID];
//
}

class PointingZone {
  DateTime date;
  LatLngModel? latlng;
  Site site;
  ZoneMember? zoneMember;
  double distance;
  String tenantId;
  String? departmentId;
  PointingZone(
      {required this.site,
      required this.latlng,
      required this.date,
      required this.distance,
      required this.zoneMember,
      this.tenantId = TenantDefaults.defaultTenantId,
      this.departmentId});

  factory PointingZone.fromJson(Map<String, dynamic> json) {
    DateTime? parsedDate;
    if (json["datetimestamp"] != null) {
      if (json["datetimestamp"] is Timestamp) {
        parsedDate = (json["datetimestamp"] as Timestamp).toDate();
      } else if (json["datetimestamp"] is String) {
        parsedDate = DateTime.tryParse(json["datetimestamp"]);
      }
    }
    parsedDate ??= DateTime.parse(json["date"]);
    return PointingZone(
        date: parsedDate,
        latlng: LatLngModel.fromJson(json["latlng"]),
        site: Site.fromJson(json["site"]),
        zoneMember: ZoneMember.fromJson(json["zoneMember"]),
        distance: json["distance"],
        tenantId: tenantIdFromJson(json),
        departmentId: departmentIdFromJson(json));
  }

  Map<String, dynamic> toJson() {
    return {
      "date": date.toIso8601String(),
      "latlng": latlng?.toJson(),
      "site": site.toJson(),
      "distance": distance,
      "zoneMember": zoneMember?.toJson(),
      "datetimestamp": date,
      "tenantId":
          effectiveTenantId(tenantId, [site.tenantId, zoneMember?.tenantId]),
      "departmentId": departmentId ?? zoneMember?.departmentId,
    };
  }

  bool isToday() {
    DateTime today = DateTime.now();
    return date.year == today.year &&
        date.day == today.day &&
        date.month == today.month;
  }
}

class PointingSite {
  DateTime date;
  LatLngModel? latlng;
  Site site;
  Supervisor? supervisor;
  double distance;
  String? agentPhotoUrl;
  String tenantId;
  String? departmentId;
  PointingSite(
      {required this.site,
      required this.latlng,
      required this.date,
      required this.distance,
      required this.supervisor,
      this.tenantId = TenantDefaults.defaultTenantId,
      this.departmentId,
      this.agentPhotoUrl});

  factory PointingSite.fromJson(Map<String, dynamic> json) {
    DateTime? parsedDate;
    if (json["datetimestamp"] != null) {
      if (json["datetimestamp"] is Timestamp) {
        parsedDate = (json["datetimestamp"] as Timestamp).toDate();
      } else if (json["datetimestamp"] is String) {
        parsedDate = DateTime.tryParse(json["datetimestamp"]);
      }
    }
    if (parsedDate == null && json["date"] != null) {
      if (json["date"] is String) {
        parsedDate = DateTime.tryParse(json["date"]);
      }
    }
    parsedDate ??= DateTime.now();
    return PointingSite(
        date: parsedDate,
        latlng: json['latlng'] != null ? LatLngModel.fromJson(json["latlng"]) : null,
        site: Site.fromJson(json["site"]),
        supervisor: Supervisor.fromJson(json["supervisor"]),
        distance: json["distance"],
        tenantId: tenantIdFromJson(json),
        departmentId: departmentIdFromJson(json),
        agentPhotoUrl: json["agentPhotoUrl"] as String?);
  }

  Map<String, dynamic> toJson() {
    return {
      "date": date.toIso8601String(),
      "latlng": latlng?.toJson(),
      "site": site.toJson(),
      "datetimestamp": date,
      "distance": distance,
      "supervisor": supervisor?.toJson(),
      "agentPhotoUrl": agentPhotoUrl,
      "tenantId":
          effectiveTenantId(tenantId, [site.tenantId, supervisor?.tenantId]),
      "departmentId": departmentId ?? supervisor?.departmentId,
    };
  }

  bool isToday() {
    DateTime today = DateTime.now();
    return date.year == today.year &&
        date.day == today.day &&
        date.month == today.month;
  }
}

class PointingAgent extends Equatable {
  DateTime date;
  LatLngModel latlng;
  Agent agent;
  double distance;
  bool confirmed;
  String tenantId;
  String? departmentId;
  PointingAgent(
      {required this.agent,
      required this.latlng,
      required this.date,
      required this.distance,
      required this.confirmed,
      this.tenantId = TenantDefaults.defaultTenantId,
      this.departmentId});

  factory PointingAgent.fromJson(Map<String, dynamic> json) {
    return PointingAgent(
        date: DateTime.parse(json["date"]),
        latlng: LatLngModel.fromJson(json["latlng"]),
        agent: Agent.fromJson(json["agent"]),
        distance: json["distance"],
        confirmed: json["confirmed"],
        tenantId: tenantIdFromJson(json),
        departmentId: departmentIdFromJson(json));
  }

  Map<String, dynamic> toJson() {
    return {
      "date": date.toIso8601String(),
      "latlng": latlng.toJson(),
      "agent": agent.toJson(),
      "distance": distance,
      "confirmed": confirmed,
      "tenantId": effectiveTenantId(tenantId, [agent.tenantId]),
      "departmentId": departmentId ?? agent.departmentId,
    };
  }

  // bool isToday() {
  //   DateTime today = DateTime.now();
  //   return date.year == today.year &&
  //       date.day == today.day &&
  //       date.month == today.month;
  // }

  @override
  // TODO: implement props
  List<Object?> get props => [date.day, date.month, date.year];
}

class PointingRondier extends Equatable {
  DateTime date;
  LatLngModel latlng;
  Agent agent;
  Site site;
  double distance;
  bool confirmed;
  String tenantId;
  String? departmentId;
  PointingRondier(
      {required this.agent,
      required this.latlng,
      required this.date,
      required this.distance,
      required this.confirmed,
      required this.site,
      this.tenantId = TenantDefaults.defaultTenantId,
      this.departmentId});

  factory PointingRondier.fromJson(Map<String, dynamic> json) {
    return PointingRondier(
        date: DateTime.parse(json["date"]),
        latlng: LatLngModel.fromJson(json["latlng"]),
        agent: Agent.fromJson(json["agent"]),
        site: Site.fromJson(json["site"]),
        distance: json["distance"],
        confirmed: json["confirmed"],
        tenantId: tenantIdFromJson(json),
        departmentId: departmentIdFromJson(json));
  }

  Map<String, dynamic> toJson() {
    return {
      "date": date.toIso8601String(),
      "latlng": latlng.toJson(),
      "agent": agent.toJson(),
      "site": site.toJson(),
      "distance": distance,
      "confirmed": confirmed,
      "tenantId": effectiveTenantId(tenantId, [agent.tenantId, site.tenantId]),
      "departmentId": departmentId ?? agent.departmentId,
    };
  }

  bool isToday() {
    DateTime today = DateTime.now();
    return date.year == today.year &&
        date.day == today.day &&
        date.month == today.month;
  }

  @override
  // TODO: implement props
  List<Object?> get props => [date.day, date.month, date.year];
}

class Note extends Equatable {
  String id;
  DateTime date;
  Site? site;
  String title;
  String source;
  String note;
  bool viewed;
  Department? department;
  String tenantId;
  String? departmentId;
  List<Comment>? comments;
  Note(
      {required this.site,
      required this.date,
      required this.note,
      required this.viewed,
      required this.source,
      required this.title,
      required this.id,
      required this.department,
      this.tenantId = TenantDefaults.defaultTenantId,
      this.departmentId,
      required this.comments});

  factory Note.fromJson(Map<String, dynamic> json) {
    List<dynamic> commentaires = json["comments"] ?? [];

    return Note(
        date: DateTime.parse(json["date"]),
        site: Site.fromJson(json["site"]),
        department: json["department"] == null
            ? null
            : Department.fromJson(json["department"]),
        tenantId: tenantIdFromJson(json),
        departmentId: departmentIdFromJson(json),
        note: json["note"],
        viewed: json["viewed"],
        source: json["source"],
        title: json["title"],
        id: json["id"],
        comments: commentaires.isEmpty
            ? []
            : commentaires.map((e) => Comment.fromJson(e)).toList());
  }

  Map<String, dynamic> toJson() {
    return {
      "date": date.toIso8601String(),
      "site": site?.toJson(),
      "note": note,
      "viewed": viewed,
      "title": title,
      "source": source,
      "id": id,
      "tenantId": effectiveTenantId(tenantId, [site?.tenantId]),
      "departmentId": departmentId ?? department?.id,
      "department": department?.toJson(),
      "comments": comments?.map((e) => e.toJson()).toList()
    };
  }

  @override
  // TODO: implement props
  List<Object?> get props => [id];
}

class Comment extends Equatable {
  Manager manager;
  DateTime date;
  String title;
  Comment({required this.manager, required this.title, required this.date});

  factory Comment.fromJson(Map<String, dynamic> json) {
    return Comment(
        date: DateTime.parse(json["date"]),
        manager: Manager.fromJson(json["manager"]),
        title: json["title"]);
  }
  Map<String, dynamic> toJson() {
    return {
      "date": date.toIso8601String(),
      "manager": manager.toJson(),
      "title": title
    };
  }

  @override
  // TODO: implement props
  List<Object?> get props => [title];
}

class Manager {
  String UID;
  String firstName;
  String lastName;
  String phone;
  String email;
  String token;
  String poste;
  String tenantId;
  bool hasTenantId;
  bool actif;
  String departmentScope;
  List<String> departmentIds;
  Profil? profil;
  Manager(
      {required this.UID,
      required this.email,
      required this.phone,
      required this.firstName,
      required this.lastName,
      required this.poste,
      required this.token,
      this.tenantId = TenantDefaults.defaultTenantId,
      this.hasTenantId = false,
      this.actif = true,
      this.departmentScope = DepartmentScopeValue.all,
      List<String>? departmentIds,
      required this.profil})
      : departmentIds = departmentIds ?? <String>[];

  factory Manager.fromJson(Map<String, dynamic> json) {
    return Manager(
        UID: json["UID"],
        firstName: json["firstName"],
        lastName: json["lastName"],
        phone: json["phone"],
        email: json["email"],
        poste: json["poste"],
        token: json["token"],
        tenantId: tenantIdFromJson(json),
        hasTenantId: hasTenantIdInJson(json),
        actif: json['actif'] ?? true,
        departmentScope: departmentScopeFromJson(json),
        departmentIds: departmentIdsFromJson(json),
        profil: json["profil"] == null
            ? Profil(name: "Inconnu", modules: [
                Module(
                    moduleName: ModuleName.MANAGER,
                    add: true,
                    delete: false,
                    validation: false,
                    view: false,
                    print: true,
                    generBadge: true)
              ])
            : Profil.fromJson(json["profil"]));
  }

  Map<String, dynamic> toJson() {
    return {
      "UID": UID,
      "firstName": firstName,
      "lastName": lastName,
      "phone": phone,
      "email": email,
      "token": token,
      "poste": poste,
      "actif": actif,
      "tenantId": tenantId,
      "departmentScope": departmentScope,
      "departmentIds": departmentIds,
      "profil": profil?.toJson()
    };
  }
//
}

class Tool {
  String label;
  String serialNumber;
  Site? site;
  CategorieTool? catTool;
  String tenantId;
  String? departmentId;
  Tool(
      {required this.label,
      required this.serialNumber,
      required this.site,
      required this.catTool,
      this.tenantId = TenantDefaults.defaultTenantId,
      this.departmentId});

  factory Tool.fromJson(Map<String, dynamic> json) {
    return Tool(
      label: json["label"],
      serialNumber: json["serialNumber"],
      site: Site.fromJson(json["site"]),
      catTool: json["catTool"] == null
          ? null
          : CategorieTool.fromJson(json["catTool"]),
      tenantId: tenantIdFromJson(json),
      departmentId: departmentIdFromJson(json),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "label": label,
      "serialNumber": serialNumber,
      "site": site?.toJson(),
      "catTool": catTool?.toJson(),
      "tenantId": effectiveTenantId(tenantId, [site?.tenantId]),
      "departmentId": departmentId ?? catTool?.departmentId,
    };
  }
//
}

class CategorieTool extends Equatable {
  String label;
  Department? department;
  String? departmentId;
  CategorieTool({
    required this.label,
    required this.department,
    this.departmentId,
  });
  factory CategorieTool.fromJson(Map<String, dynamic> json) {
    return CategorieTool(
      label: json["label"],
      department: json["department"] == null
          ? null
          : Department.fromJson(json["department"]),
      departmentId: departmentIdFromJson(json),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "label": label,
      "departmentId": departmentId ?? department?.id,
      "department": department?.toJson(),
    };
  }

  @override
  // TODO: implement props
  List<Object?> get props => [label];
//
}

class Department extends Equatable {
  String id;
  String label;
  bool active;
  String? documentId;
  Department({
    String? id,
    required this.label,
    this.active = true,
    this.documentId,
  }) : id = normalizeDepartmentId(id ?? label);

  factory Department.fromJson(Map<String, dynamic> json) {
    return Department(
      id: json["id"] ?? json["label"],
      label: json["label"] ?? json["id"] ?? "",
      active: json["active"] is bool ? json["active"] : true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "id": id,
      "label": label,
      "active": active,
    };
  }

  @override
  // TODO: implement props
  List<Object?> get props => [id];
//
}

class AgentType extends Equatable {
  String label;
  AgentType({required this.label});
  factory AgentType.fromJson(Map<String, dynamic> json) {
    String label = json["label"] ?? "FIXE";
    return AgentType(
      label: label,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "label": label,
    };
  }

  @override
  // TODO: implement props
  List<Object?> get props => [label];
//
}

class PointingTools {
  DateTime date;
  LatLngModel latlng;
  Tool tool;
  double distance;
  String status;
  bool supported;
  String tenantId;
  String? departmentId;
  PointingTools(
      {required this.tool,
      required this.latlng,
      required this.date,
      required this.distance,
      required this.status,
      required this.supported,
      this.tenantId = TenantDefaults.defaultTenantId,
      this.departmentId});

  factory PointingTools.fromJson(Map<String, dynamic> json) {
    return PointingTools(
        date: DateTime.parse(json["date"]),
        latlng: LatLngModel.fromJson(json["latlng"]),
        tool: Tool.fromJson(json["tool"]),
        distance: json["distance"],
        status: json["status"],
        supported: json["supported"],
        tenantId: tenantIdFromJson(json),
        departmentId: departmentIdFromJson(json));
  }

  Map<String, dynamic> toJson() {
    return {
      "date": date.toIso8601String(),
      "latlng": latlng.toJson(),
      "tool": tool.toJson(),
      "distance": distance,
      "status": status,
      "supported": supported,
      "tenantId": effectiveTenantId(tenantId, [tool.tenantId]),
      "departmentId": departmentId ?? tool.departmentId,
    };
  }
}

class CheckList {
  Site site;
  CategorieTool cattool;
  String status;
  Supervisor? supervisor;
  DateTime date;
  String tenantId;
  String? departmentId;
  CheckList(
      {required this.cattool,
      required this.status,
      required this.site,
      required this.supervisor,
      required this.date,
      this.tenantId = TenantDefaults.defaultTenantId,
      this.departmentId});

  factory CheckList.fromJson(Map<String, dynamic> json) {
    return CheckList(
        site: Site.fromJson(json["site"]),
        cattool: CategorieTool.fromJson(json["cattool"]),
        status: json["status"],
        date: DateTime.parse(json["date"]),
        supervisor: Supervisor.fromJson(json["supervisor"]),
        tenantId: tenantIdFromJson(json),
        departmentId: departmentIdFromJson(json));
  }

  Map<String, dynamic> toJson() {
    return {
      "date": date.toIso8601String(),
      "site": site.toJson(),
      "cattool": cattool.toJson(),
      "status": status,
      "supervisor": supervisor?.toJson(),
      "tenantId":
          effectiveTenantId(tenantId, [site.tenantId, supervisor?.tenantId]),
      "departmentId":
          departmentId ?? cattool.departmentId ?? supervisor?.departmentId,
    };
  }
}

class Profil extends Equatable {
  String name;
  List<Module> modules;
  Profil({required this.name, required this.modules});

  factory Profil.fromJson(Map<String, dynamic> jsonData) {
    List<dynamic> jsonModules = jsonData["modules"] ?? [];
    List<Module> modules = jsonModules.isEmpty
        ? []
        : jsonModules.map((data) => Module.fromJson(data)).toList();
    return Profil(name: jsonData['name'], modules: modules);
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'modules': modules.map((e) => e.toJson()).toList(),
      };

  @override
  // TODO: implement props
  List<Object?> get props => [name];

  Module? getModule(ModuleName name) {
    if (modules.isEmpty) return null;
    return modules.firstWhere((element) => element.moduleName == name,
        orElse: () => Module(
            moduleName: name,
            add: false,
            delete: false,
            validation: false,
            view: false,
            print: false,
            generBadge: false));
  }
}

class Module {
  ModuleName moduleName;
  bool validation;
  bool delete;
  bool add;
  bool view;
  bool print;
  bool generBadge;
  Module(
      {required this.moduleName,
      required this.add,
      required this.delete,
      required this.validation,
      required this.view,
      required this.print,
      required this.generBadge});

  factory Module.fromJson(Map<String, dynamic> json) {
    ModuleName moduleName = ModuleName.MANAGER;
    switch (json['moduleName'] ?? "") {
      case "TABLEAU_DE_BORD":
        moduleName = ModuleName.TABLEAU_DE_BORD;
        break;
      case "MANAGER":
        moduleName = ModuleName.MANAGER;
        break;
      case "AGENT":
        moduleName = ModuleName.AGENT;
        break;
      case "NOTE":
        moduleName = ModuleName.NOTE;
        break;
      case "SITE":
        moduleName = ModuleName.SITE;
        break;
      case "SUPERVISEUR":
        moduleName = ModuleName.SUPERVISEUR;
        break;
      case "TOOL":
        moduleName = ModuleName.TOOL;
        break;
      case "CATEGORIE_TOOL":
        moduleName = ModuleName.CATEGORIE_TOOL;
        break;
      case "DEPARTMENT":
        moduleName = ModuleName.DEPARTMENT;
        break;
      case "AGENT_TYPE":
        moduleName = ModuleName.AGENT_TYPE;
        break;
      case "ZONE":
        moduleName = ModuleName.ZONE;
        break;
      case "ZONE_MEMBER":
        moduleName = ModuleName.ZONE_MEMBER;
        break;
      case "POINTAGE_SITE":
        moduleName = ModuleName.POINTAGE_SITE;
        break;
      case "POINTAGE_AGENT":
        moduleName = ModuleName.POINTAGE_AGENT;
        break;
      case "POINTAGE_RONDIER":
        moduleName = ModuleName.POINTAGE_RONDIER;
        break;
      case "POINTAGE_TOOL":
        moduleName = ModuleName.POINTAGE_TOOL;
        break;
      case "POINTAGE_ZONE":
        moduleName = ModuleName.POINTAGE_ZONE;
        break;
      case "ERROR_LOG":
        moduleName = ModuleName.ERROR_LOG;
        break;
      case "MOBILE_CONFIG":
        moduleName = ModuleName.MOBILE_CONFIG;
        break;
      default:
        moduleName = ModuleName.MANAGER;
    }
    return Module(
        moduleName: moduleName,
        validation: json['validation'] ?? false,
        delete: json['delete'] ?? false,
        add: json['add'] ?? false,
        print: json['print'] ?? false,
        generBadge: json['generBadge'] ?? false,
        view: json['view'] ?? false);
  }

  Map<String, dynamic> toJson() => {
        'moduleName': moduleName.name,
        'validation': validation,
        'delete': delete,
        'add': add,
        'view': view,
        'print': print,
        'generBadge': generBadge
      };

//
}

enum ModuleName {
  TABLEAU_DE_BORD,
  AGENT,
  SUPERVISEUR,
  SITE,
  TOOL,
  NOTE,
  MANAGER,
  CATEGORIE_TOOL,
  DEPARTMENT,
  AGENT_TYPE,
  ZONE,
  ZONE_MEMBER,
  POINTAGE_SITE,
  POINTAGE_AGENT,
  POINTAGE_RONDIER,
  POINTAGE_TOOL,
  POINTAGE_ZONE,
  ERROR_LOG,
  MOBILE_CONFIG
}

class PushNotification {
  PushNotification({
    this.title,
    this.body,
  });
  String? title;
  String? body;
}

class Autorisation_model {
  String autorisation;
  String interdiction;
  Autorisation_model({required this.autorisation, required this.interdiction});
}

class Consigne_model {
  String consigne;
  String tache;
  Consigne_model({required this.consigne, required this.tache});
}

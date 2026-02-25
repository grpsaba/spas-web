import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

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

  SuperviseurLocaion({
    required this.latlng,
    required this.date,
    required this.supervisor,
  });

  factory SuperviseurLocaion.fromJson(Map<String, dynamic> json) {
    return SuperviseurLocaion(
      date: DateTime.parse(json["date"]),
      latlng: LatLngModel.fromJson(json["latlng"]),
      supervisor: Supervisor.fromJson(json["supervisor"]),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "date": date.toIso8601String(),
      "latlng": latlng.toJson(),
      "supervisor": supervisor?.toJson(),
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
      this.isSpecial = false,
      this.zone,
      required this.department});

  factory Supervisor.fromJson(Map<String, dynamic> json) {
    if(json["UID"] == null || json["code"] == null || json["firstName"] == null || json["lastName"] == null || json["phone"] == null || json["email"] == null || json['token'] == null || json["tracking"] == null){
        
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
          ? null
          : AgentType.fromJson(json["AgentType"]),
      site: json["site"] == null ? null : Site.fromJson(json["site"]),
      actif: json["actif"] ?? true,
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
  int? nbRonde;
  DateTime? dateContrat;
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
      required this.dateContrat,
      required this.nbRonde});

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
        dateContrat: json['dateContrat'] != null
            ? DateTime.tryParse(json['dateContrat'])
            : DateTime.now(),
        zone: json["zone"] == null ? null : Zone.fromJson(json["zone"]),
        supervisor: Supervisor.fromJson(json["supervisor"]),
        supervisor_2:
         json["supervisor_2"] == null
            ? null
            : Supervisor.fromJson(json["supervisor_2"]),
        latLng: LatLngModel.fromJson(json["latLng"]),
        sos: json["sos"],
        phone: json["phone"]);
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
      'nbRonde': nbRonde ?? 1,
      'dateContrat': dateContrat != null
          ? dateContrat?.toIso8601String()
          : DateTime.now().toIso8601String()
    };
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
  Zone({
    required this.codeZone,
    required this.name,
  });

  factory Zone.fromJson(Map<String, dynamic> json) {
    if(json["codeZone"] == null || json["name"] == null){
        print("object");   
         }
    return Zone(
      codeZone: json["codeZone"],
      name: json["name"],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "codeZone": codeZone,
      "name": name,
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
  LatLngModel latlng;
  Site site;
  ZoneMember? zoneMember;
  double distance;
  PointingZone(
      {required this.site,
      required this.latlng,
      required this.date,
      required this.distance,
      required this.zoneMember});

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
        distance: json["distance"]);
  }

  Map<String, dynamic> toJson() {
    return {
      "date": date.toIso8601String(),
      "latlng": latlng.toJson(),
      "site": site.toJson(),
      "distance": distance,
      "zoneMember": zoneMember?.toJson(),
      "datetimestamp": date,
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
  LatLngModel latlng;
  Site site;
  Supervisor? supervisor;
  double distance;
  PointingSite(
      {required this.site,
      required this.latlng,
      required this.date,
      required this.distance,
      required this.supervisor});

  factory PointingSite.fromJson(Map<String, dynamic> json) {
    return PointingSite(
        date: json["date"] != null
            ? DateTime.parse(json["date"])
            : DateTime.now(),
        latlng: LatLngModel.fromJson(json["latlng"]),
        site: Site.fromJson(json["site"]),
        supervisor: Supervisor.fromJson(json["supervisor"]),
        distance: json["distance"]);
  }

  Map<String, dynamic> toJson() {
    return {
      "date": date.toIso8601String(),
      "latlng": latlng.toJson(),
      "site": site.toJson(),
      "datetimestamp": date,
      "distance": distance,
      "supervisor": supervisor?.toJson()
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
  PointingAgent(
      {required this.agent,
      required this.latlng,
      required this.date,
      required this.distance,
      required this.confirmed});

  factory PointingAgent.fromJson(Map<String, dynamic> json) {
    return PointingAgent(
        date: DateTime.parse(json["date"]),
        latlng: LatLngModel.fromJson(json["latlng"]),
        agent: Agent.fromJson(json["agent"]),
        distance: json["distance"],
        confirmed: json["confirmed"]);
  }

  Map<String, dynamic> toJson() {
    return {
      "date": date.toIso8601String(),
      "latlng": latlng.toJson(),
      "agent": agent.toJson(),
      "distance": distance,
      "confirmed": confirmed
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
  PointingRondier(
      {required this.agent,
      required this.latlng,
      required this.date,
      required this.distance,
      required this.confirmed,
      required this.site});

  factory PointingRondier.fromJson(Map<String, dynamic> json) {
    return PointingRondier(
        date: DateTime.parse(json["date"]),
        latlng: LatLngModel.fromJson(json["latlng"]),
        agent: Agent.fromJson(json["agent"]),
        site: Site.fromJson(json["site"]),
        distance: json["distance"],
        confirmed: json["confirmed"]);
  }

  Map<String, dynamic> toJson() {
    return {
      "date": date.toIso8601String(),
      "latlng": latlng.toJson(),
      "agent": agent.toJson(),
      "site": site.toJson(),
      "distance": distance,
      "confirmed": confirmed
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
      required this.comments});

  factory Note.fromJson(Map<String, dynamic> json) {
    List<dynamic> commentaires = json["comments"] ?? [];

    return Note(
        date: DateTime.parse(json["date"]),
        site: Site.fromJson(json["site"]),
        department: json["department"] == null
            ? null
            : Department.fromJson(json["department"]),
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
  Profil? profil;
  Manager(
      {required this.UID,
      required this.email,
      required this.phone,
      required this.firstName,
      required this.lastName,
      required this.poste,
      required this.token,
      required this.profil});

  factory Manager.fromJson(Map<String, dynamic> json) {
    return Manager(
        UID: json["UID"],
        firstName: json["firstName"],
        lastName: json["lastName"],
        phone: json["phone"],
        email: json["email"],
        poste: json["poste"],
        token: json["token"],
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
  Tool(
      {required this.label,
      required this.serialNumber,
      required this.site,
      required this.catTool});

  factory Tool.fromJson(Map<String, dynamic> json) {
    return Tool(
      label: json["label"],
      serialNumber: json["serialNumber"],
      site: Site.fromJson(json["site"]),
      catTool: json["catTool"] == null
          ? null
          : CategorieTool.fromJson(json["catTool"]),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "label": label,
      "serialNumber": serialNumber,
      "site": site?.toJson(),
      "catTool": catTool?.toJson(),
    };
  }
//
}

class CategorieTool extends Equatable {
  String label;
  Department? department;
  CategorieTool({required this.label, required this.department});
  factory CategorieTool.fromJson(Map<String, dynamic> json) {
    return CategorieTool(
        label: json["label"],
        department: Department.fromJson(json["department"]));
  }

  Map<String, dynamic> toJson() {
    return {"label": label, "department": department?.toJson()};
  }

  @override
  // TODO: implement props
  List<Object?> get props => [label];
//
}

class Department extends Equatable {
  String label;
  Department({required this.label});
  factory Department.fromJson(Map<String, dynamic> json) {
    return Department(
      label: json["label"],
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

class AgentType extends Equatable {
  String label;
  AgentType({required this.label});
  factory AgentType.fromJson(Map<String, dynamic> json) {
    return AgentType(
      label: json["label"],
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
  PointingTools(
      {required this.tool,
      required this.latlng,
      required this.date,
      required this.distance,
      required this.status,
      required this.supported});

  factory PointingTools.fromJson(Map<String, dynamic> json) {
    return PointingTools(
        date: DateTime.parse(json["date"]),
        latlng: LatLngModel.fromJson(json["latlng"]),
        tool: Tool.fromJson(json["tool"]),
        distance: json["distance"],
        status: json["status"],
        supported: json["supported"]);
  }

  Map<String, dynamic> toJson() {
    return {
      "date": date.toIso8601String(),
      "latlng": latlng.toJson(),
      "tool": tool.toJson(),
      "distance": distance,
      "status": status,
      "supported": supported
    };
  }
}

class CheckList {
  Site site;
  CategorieTool cattool;
  String status;
  Supervisor? supervisor;
  DateTime date;
  CheckList(
      {required this.cattool,
      required this.status,
      required this.site,
      required this.supervisor,
      required this.date});

  factory CheckList.fromJson(Map<String, dynamic> json) {
    return CheckList(
        site: Site.fromJson(json["site"]),
        cattool: CategorieTool.fromJson(json["cattool"]),
        status: json["status"],
        date: DateTime.parse(json["date"]),
        supervisor: Supervisor.fromJson(json["supervisor"]));
  }

  Map<String, dynamic> toJson() {
    return {
      "date": date.toIso8601String(),
      "site": site.toJson(),
      "cattool": cattool.toJson(),
      "status": status,
      "supervisor": supervisor?.toJson()
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
            moduleName: ModuleName.MANAGER,
            add: true,
            delete: false,
            validation: false,
            view: false,
            print: true,
            generBadge: true));
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
      default:
        moduleName = ModuleName.MANAGER;
    }
    return Module(
        moduleName: moduleName,
        validation: json['validation'],
        delete: json['delete'],
        add: json['add'],
        print: json['print'],
        generBadge: json['generBadge'],
        view: json['view']);
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
  AGENT_TYPE
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

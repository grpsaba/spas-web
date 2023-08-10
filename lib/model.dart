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
      required this.actif});

  factory Supervisor.fromJson(Map<String, dynamic> json) {
    return Supervisor(
      UID: json["UID"],
      code: json["code"],
      firstName: json["firstName"],
      lastName: json["lastName"],
      phone: json["phone"],
      email: json["email"],
      token: json['token'],
      actif: json['actif'] ?? true,
      tracking: json["tracking"],
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
      "latlng": latlng?.toJson()
    };
  }
//
}

class Agent extends Equatable {
  String code;
  String firstName;
  String lastName;
  String phone;
  String email;
  bool tracking;
  String type;
  Site? site;
  String? categorie;
  bool? actif;
  bool? active;
  Agent({
    required this.code,
    required this.firstName,
    required this.lastName,
    required this.phone,
    required this.email,
    required this.tracking,
    required this.site,
    required this.categorie,
    required this.type,
    required this.actif,
  });

  factory Agent.fromJson(Map<String, dynamic> json) {
    return Agent(
      code: json["code"],
      firstName: json["firstName"],
      lastName: json["lastName"],
      phone: json["phone"],
      email: json["email"],
      tracking: json["tracking"],
      type: json["type"] ?? "SECURITÉ",
      site: json["site"] == null ? null : Site.fromJson(json["site"]),
      actif: json["actif"] ?? true,
      categorie: json["categorie"] ?? "FIXE",
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "code": code,
      "firstName": firstName,
      "lastName": lastName,
      "phone": phone,
      "email": email,
      "tracking": tracking,
      "site": site?.toJson(),
      "actif": actif,
      "categorie": categorie,
      "type": type,
    };
  }

  @override
  // TODO: implement props
  List<Object?> get props => [code];
//

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
  Site({
    required this.UID,
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
  });

  factory Site.fromJson(Map<String, dynamic> json) {
    return Site(
        UID: json["UID"],
        codeSite: json["codeSite"],
        name: json["name"],
        adresse: json["adresse"],
        email: json["email"],
        token: json['token'],
        actif: json['actif'] ?? true,
        nbAgent: json['nbAgent'] ?? 0,
        supervisor: Supervisor.fromJson(json["supervisor"]),
        supervisor_2: json["supervisor_2"] == null
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
      "supervisor": supervisor?.toJson(),
      "supervisor_2": supervisor_2?.toJson(),
      "latLng": latLng.toJson(),
      "sos": sos,
      'token': token,
      'phone': phone,
      'nbAgent': nbAgent,
      'actif': actif
    };
  }

  @override
  // TODO: implement props
  List<Object?> get props => [UID];
//

//

//
}

class PointingAgent {
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
        date: DateTime.parse(json["date"]),
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

class Note {
  String id;
  DateTime date;
  Site? site;
  String title;
  String source;
  String note;
  bool viewed;
  Note(
      {required this.site,
      required this.date,
      required this.note,
      required this.viewed,
      required this.source,
      required this.title,
      required this.id});

  factory Note.fromJson(Map<String, dynamic> json) {
    return Note(
        date: DateTime.parse(json["date"]),
        site: Site.fromJson(json["site"]),
        note: json["note"],
        viewed: json["viewed"],
        source: json["source"],
        title: json["title"],
        id: json["id"]);
  }

  Map<String, dynamic> toJson() {
    return {
      "date": date.toIso8601String(),
      "site": site?.toJson(),
      "note": note,
      "viewed": viewed,
      "title": title,
      "source": source,
      "id": id
    };
  }
}

class Manager {
  String UID;
  String firstName;
  String lastName;
  String phone;
  String email;
  String token;
  String poste;
  String role;
  Manager(
      {required this.UID,
      required this.email,
      required this.phone,
      required this.firstName,
      required this.lastName,
      required this.poste,
      required this.token,
      required this.role});

  factory Manager.fromJson(Map<String, dynamic> json) {
    return Manager(
        UID: json["UID"],
        firstName: json["firstName"],
        lastName: json["lastName"],
        phone: json["phone"],
        email: json["email"],
        poste: json["poste"],
        token: json["token"],
        role: json["role"]);
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
      "role": role
    };
  }
//
}

class Tool {
  String label;
  String serialNumber;
  Site? site;
  Tool({required this.label, required this.serialNumber, required this.site});

  factory Tool.fromJson(Map<String, dynamic> json) {
    return Tool(
      label: json["label"],
      serialNumber: json["serialNumber"],
      site: Site.fromJson(json["site"]),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "label": label,
      "serialNumber": serialNumber,
      "site": site?.toJson(),
    };
  }
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

class PushNotification {
  PushNotification({
    this.title,
    this.body,
  });
  String? title;
  String? body;
}

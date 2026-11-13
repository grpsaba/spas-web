import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../const.dart';
import '../model.dart';

class ProfilService {
  Map<String, dynamic> _data(Profil profil) => {
        ...profil.toJson(),
        // Indexed permissions for Firestore/Storage rules (rules cannot search a
        // list of module maps). Persisted only through the existing profile editor.
        'installationAccess': {
          'view': profil.getModule(ModuleName.BON_MISE_EN_PLACE)?.view ?? false,
          'add': profil.getModule(ModuleName.BON_MISE_EN_PLACE)?.add ?? false,
          'validation':
              profil.getModule(ModuleName.BON_MISE_EN_PLACE)?.validation ??
                  false,
          'print':
              profil.getModule(ModuleName.BON_MISE_EN_PLACE)?.print ?? false,
        },
      };
  final CollectionReference _collectionReference =
      FirebaseFirestore.instance.collection("Profils");

  Future<void> add(Profil profil) async {
    profil.modules = AppConstants.moduleList;
    await _collectionReference.doc(profil.name).set(_data(profil));
  }

  Stream<QuerySnapshot> all() {
    return _collectionReference.snapshots();
  }

  Future<void> delete(Profil profil) async {
    return _collectionReference.doc(profil.name).delete();
  }

  Future<Profil?> one(name) async {
    var dataSnapshot = await _collectionReference.doc(name).get();
    var data = jsonEncode(dataSnapshot.data());
    return Profil.fromJson(jsonDecode(data));
  }

  Future<void> update(Profil profil) {
    return _collectionReference.doc(profil.name).update(_data(profil));
  }
}

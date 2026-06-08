import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../model.dart';
import 'manager.dart';
import 'profil.dart';

class TenantAssignmentRequiredException implements Exception {}

class AuthService {
  var auth = FirebaseAuth.instance;
  static Manager? currentManager;
  Future<Manager?> authState({String? selectedTenantId}) async {
    try {
      var user = auth.currentUser;
      if (user != null) {
        final managerService = ManagerService();
        var manager = await managerService.one(user.uid);
        final profileName = manager?.profil?.name;

        if (manager != null && profileName != null && profileName.isNotEmpty) {
          final latestProfile = await ProfilService().one(profileName);
          if (latestProfile != null) {
            manager.profil = latestProfile;
          }
        }

        if (manager != null && !canBypassTenantForProfile(manager.profil)) {
          final hasTenant = await managerService.hasAssignedTenant(manager);
          if (!hasTenant) {
            currentManager = null;
            await logOut();
            if (selectedTenantId != null) {
              throw TenantAssignmentRequiredException();
            }
            return null;
          }
        }

        currentManager = manager;
        return manager;
      }
      return null;
    } on TenantAssignmentRequiredException {
      rethrow;
    } catch (e) {
      debugPrint(e.toString());
      return null;
    }
  }

  Future<User?> loginWithEmail(email, password) async {
    try {
      var credential = await auth.signInWithEmailAndPassword(
          email: email, password: password);

      //saving messasing token in the supervisor file
      return credential.user;
    } catch (e) {
      debugPrint(e.toString());
      return null;
    }
  }

  Future<User?> createUserWithEmail(email, password) async {
    try {
      var credential = await auth.createUserWithEmailAndPassword(
          email: email, password: password);
      return credential.user;
    } catch (e) {
      debugPrint(e.toString());
      return null;
    }
  }

  Future<ConfirmationResult> createUserWithPhone(
      phoneNumber, RecaptchaVerifier recaptchaVerifier) async {
    var confirmation =
        await auth.signInWithPhoneNumber(phoneNumber, recaptchaVerifier);
    return confirmation;
  }

  Future<void> logOut() async {
    currentManager = null;
    await auth.signOut();
  }
}

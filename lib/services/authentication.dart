import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../model.dart';
import 'manager.dart';
import 'profil.dart';

class AuthService {
  var auth = FirebaseAuth.instance;
  static Manager? currentManager;
  Future<Manager?> authState() async {
    try {
      var user = auth.currentUser;
      if (user != null) {
        var manager = await ManagerService().one(user.uid);
        final profileName = manager?.profil?.name;

        if (manager != null && profileName != null && profileName.isNotEmpty) {
          final latestProfile = await ProfilService().one(profileName);
          if (latestProfile != null) {
            manager.profil = latestProfile;
          }
        }

        currentManager = manager;
        return manager;
      }
      return null;
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

  Future<void> logOut() {
    return auth.signOut();
  }
}

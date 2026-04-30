import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../model.dart';
import 'manager.dart';

class AuthService {
  var auth = FirebaseAuth.instance;
  static Manager? currentManager;
  Future<Manager?> authState() async {
    var user = auth.currentUser;
    if (user == null) return null;
    currentManager = await ManagerService().one(user.uid);
    return currentManager;
  }

  Future<User?> loginWithEmail(email, password) async {
    var credential =
        await auth.signInWithEmailAndPassword(email: email, password: password);

    //saving messasing token in the supervisor file
    return credential.user;
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

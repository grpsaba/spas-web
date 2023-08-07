import 'package:firebase_auth/firebase_auth.dart';

import '../model.dart';
import 'manager.dart';

class AuthService {
  var auth = FirebaseAuth.instance;

  Future<Manager?> authState() async {
    var user = auth.currentUser;
    if (user == null) return null;
    var manager = await ManagerService().one(user.uid);
    return manager;
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
      print(e.toString());
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

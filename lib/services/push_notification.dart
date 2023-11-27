/*import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

class NotificationService {
  static void initialize() {
    //pour une application ios et web
    FirebaseMessaging.instance.requestPermission();

    FirebaseMessaging.onMessage.listen((event) {});

    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {});
  }

  static Future<String?> getToken() async {
    //le parametre vpidKey est pour le web
    var token = await FirebaseMessaging.instance.getToken();
    return token;
  }

  Future<void> notify(token, siteName) async {
    HttpsCallable callable = FirebaseFunctions.instance.httpsCallableFromUrl(
        "https://us-central1-spas-cd4c9.cloudfunctions.net/notificationHttp");
    final resp = await callable
        .call(<String, dynamic>{'token': token, 'site': siteName});
    print("result: ${resp.data}");
  }
}
*/

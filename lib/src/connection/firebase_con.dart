import 'package:firebase_core/firebase_core.dart';
import 'package:yolodetection/firebase_options.dart';

class FirebaseConnection {
  void firebaseConn() async {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  }
}

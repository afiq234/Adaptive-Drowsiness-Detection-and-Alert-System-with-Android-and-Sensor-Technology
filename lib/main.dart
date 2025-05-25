import 'package:alarm/alarm.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:yolodetection/src/connection/firebase_con.dart';
import 'package:yolodetection/src/screens/graphdatascreen.dart';
import 'package:yolodetection/src/screens/homescreen.dart';
import 'package:yolodetection/src/screens/yolovideo.dart';
import 'package:yolodetection/src/prototype/prototypescreenbluetooth.dart'; // Import your new file
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Alarm.init();
  FirebaseConnection().firebaseConn();
  // await Firebase.initializeApp(
  //   options: DefaultFirebaseOptions.currentPlatform,
  // );

  runApp(const MainNav());
}

class MainNav extends StatelessWidget {
  const MainNav({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      routes: {
        '/': (ctx) => const Homescreen(),
        '/cameraPage': (ctx) => const YoloVideo(),
        '/graphlayout': (ctx) => const GraphDataScreen(),
        '/bluetoothDashboard': (ctx) => HeartRatePredictionWidget(),
        // Add this route
      },
    );
  }
}

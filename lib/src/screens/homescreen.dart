import 'package:flutter/material.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:yolodetection/src/components/graphdatalayout.dart';
import 'package:yolodetection/src/components/rtdatalayout.dart';
import 'package:yolodetection/src/key/enum.dart';
import 'package:yolodetection/src/prototype/prototypebpmgraph.dart';
import 'package:yolodetection/src/prototype/prototypegooglebucket.dart';
import 'package:yolodetection/src/prototype/prototypetesttocloud.dart';
import 'package:yolodetection/src/screens/bpm_graph.dart';
import 'package:yolodetection/src/prototype/prototypescreenbluetooth.dart';
import 'package:yolodetection/src/screens/yolovideo.dart';

class Homescreen extends StatelessWidget {
  const Homescreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blueAccent,
        title: const Text("Drowsiness Detection"),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              Center(
                child: Column(
                  children: [
                    TextButton(
                      onPressed: () {
                        debugPrint('Real Time Camera Page');
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const Prototypetesttocloud(),
                          ),
                        );
                      },
                      child: const Text('Real Time Camera Page'),
                    ),
                    const SizedBox(height: 5),
                    TextButton(
                      onPressed: () {
                        debugPrint('graph button pressed');
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => BpmGraphPrototype(
                                serverUrl: LinkUrl.latestServerUrl),

                            // (context) => YoloVideo()),
                          ),
                        );
                      },
                      child: const Text('Graph Analysis Page'),
                    ),
                    const SizedBox(height: 80),
                    const Text(
                      'Description',
                      style:
                          TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 70),
                    const Text(
                      'The app introduces a cutting-edge drowsiness detection system designed to enhance safety and prevent accidents caused by fatigue. By integrating YOLOv11 for real-time facial and eye tracking and LSTM networks for heart rate analysis, the app accurately identifies signs of drowsiness, such as prolonged eye closure, irregular blinking, and abnormal heart rate patterns. This multimodal approach ensures reliable detection, while immediate alerts—like sound notifications or vibrations—prompt users to take action and stay alert. With all data processed locally on the device, the app prioritizes privacy and security, offering a seamless and trustworthy solution for individuals in high-risk environments like driving or operating machinery. Stay vigilant and safe with this advanced drowsiness detection feature.',
                      textAlign: TextAlign.justify,
                    ),
                    // SizedBox(
                    //   height: 400, // Adjust height for Graphdatalayout
                    //   child: Rtdatalayout(),
                    // ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

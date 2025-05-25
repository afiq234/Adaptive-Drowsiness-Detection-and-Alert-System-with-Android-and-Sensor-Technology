import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_database/ui/firebase_animated_list.dart';
import 'package:flutter/material.dart';

class Rtdatalayout extends StatefulWidget {
  const Rtdatalayout({super.key});

  @override
  State<Rtdatalayout> createState() => _Rtdatalayout();
}

class _Rtdatalayout extends State<Rtdatalayout> {
  Query dbRef = FirebaseDatabase.instance.ref().child('collectData');

  Widget listItem({required Map collectData}) {
    // Safely retrieve values from the map
    String time = collectData['Time']?.toString() ?? 'No Time';
    String heartRate = collectData['HeartRate'].toString();

    return Container(
      color: const Color.fromARGB(255, 244, 244, 244),
      margin: const EdgeInsets.all(8),
      padding: const EdgeInsets.all(12),
      height: 110,
      child: Card(
        color: Colors.deepOrange,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              "Time: $time",
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(
              height: 5,
            ),
            Text(
              "Heart Rate: $heartRate",
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FirebaseAnimatedList(
      query: dbRef,
      itemBuilder: (BuildContext context, DataSnapshot snapshot,
          Animation<double> animation, int index) {
        Map collectData = snapshot.value as Map;
        collectData['key'] = snapshot.key;
        return listItem(collectData: collectData);
      },
    );
  }
}

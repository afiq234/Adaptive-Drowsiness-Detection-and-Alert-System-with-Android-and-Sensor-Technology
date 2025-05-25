import 'dart:async';

import 'package:flutter/material.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

class HeartRateLayout extends StatefulWidget {
  final WebSocketChannel channel;
  final StreamSubscription subscription;
  final String heartRate;
  final String prediction;
  final bool isConnected;

  final dynamic connectToWebSocket;

  HeartRateLayout({
    super.key,
    required this.channel,
    required this.subscription,
    required this.heartRate,
    required this.prediction,
    required this.connectToWebSocket,
    required this.isConnected,
  });

  @override
  State<HeartRateLayout> createState() => _HearRateLayoutState();
}

class _HearRateLayoutState extends State<HeartRateLayout> {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          'Real-time Heart Rate:',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 10),
        Text(
          widget.heartRate,
          style: TextStyle(fontSize: 18),
        ),
        SizedBox(height: 30),
        Text(
          'Predicted Heart Rate:',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 10),
        Text(
          widget.prediction,
          style: TextStyle(fontSize: 18),
        ),
        if (!widget.isConnected)
          ElevatedButton(
            onPressed: widget.connectToWebSocket,
            child: Text('Reconnect'),
          ),
      ],
    );
  }
}

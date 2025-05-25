import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

class HeartRatePredictionWidget extends StatefulWidget {
  const HeartRatePredictionWidget({super.key});

  @override
  _HeartRatePredictionWidgetState createState() =>
      _HeartRatePredictionWidgetState();
}

class _HeartRatePredictionWidgetState extends State<HeartRatePredictionWidget> {
  late WebSocketChannel _channel;
  String _heartRate = "--";
  String _prediction = "--";

  @override
  void initState() {
    super.initState();
    _initializeWebSocket();
  }

  void _initializeWebSocket() {
    const serverUrl =
        'ws://34.143.164.189:8080'; // Replace with your server's WebSocket URL
    _channel = WebSocketChannel.connect(Uri.parse(serverUrl));

    _channel.stream.listen((message) {
      print("Message received: $message");
      final data = jsonDecode(message);
      setState(() {
        _heartRate = "${data['heart_rate'] ?? '--'}";
        _prediction = "${data['prediction']?.toStringAsFixed(2) ?? '--'}";
        print("Updated Heart Rate: $_heartRate, Prediction: $_prediction");
      });
    }, onError: (error) {
      print("WebSocket error: $error");
      _reconnectWebSocket(); // Attempt to reconnect
    }, onDone: () {
      print("WebSocket connection closed.");
      _reconnectWebSocket(); // Attempt to reconnect
    });
  }

  void _reconnectWebSocket() {
    Future.delayed(const Duration(seconds: 5), () {
      print("Reconnecting to WebSocket...");
      _initializeWebSocket();
    });
  }

  @override
  void dispose() {
    _channel.sink.close(); // Close WebSocket connection
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Heart Rate & Prediction"),
      ),
      body: Center(
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.7),
            borderRadius: BorderRadius.circular(15),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "Heart Rate: $_heartRate BPM",
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                "Predicted: $_prediction BPM",
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

void main() {
  runApp(const MaterialApp(home: HeartRatePredictionWidget()));
}

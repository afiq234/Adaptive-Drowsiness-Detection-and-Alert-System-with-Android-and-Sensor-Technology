import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:yolodetection/src/key/enum.dart';

class CameraLayout extends StatefulWidget {
  final CameraController controller;
  final bool isDetecting;
  final VoidCallback onStartDetection;
  final VoidCallback onStopDetection;
  final List<Widget> detectionBoxes;
  final List<Widget> Function(Size screen) displayBoxesAroundRecognizedObjects;

  const CameraLayout({
    super.key,
    required this.controller,
    required this.isDetecting,
    required this.onStartDetection,
    required this.onStopDetection,
    required this.detectionBoxes,
    required this.displayBoxesAroundRecognizedObjects,
  });

  @override
  State<CameraLayout> createState() => _CameraLayoutState();
}

class _CameraLayoutState extends State<CameraLayout> {
  late WebSocketChannel _channel;
  String _heartRate = "--";
  String _prediction = "--";
  String _alert = "--";

  @override
  void initState() {
    super.initState();
    _initializeWebSocket();
  }

  void _initializeWebSocket() {
    final serverUrl =
        LinkUrl.latestServerUrl; // Replace with your server's WebSocket URL
    _channel = WebSocketChannel.connect(Uri.parse(serverUrl));

    // Listen to messages from the server
    _channel.stream.listen((message) {
      print("Message received: $message");
      final data = jsonDecode(message);
      setState(
        () {
          _heartRate = "${data['heart_rate'] ?? '--'}";
          _prediction = "${data['prediction']?.toStringAsFixed(2) ?? '--'}";
          _alert = "${data['alert'] ?? '--'}";
          print(
              "Updated Heart Rate: $_heartRate, Prediction: $_prediction, Alert: $_alert");
        },
      );
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
    final screenSize = MediaQuery.of(context).size;

    return WillPopScope(
      onWillPop: () async {
        return true;
      },
      child: Scaffold(
        body: Center(
          child: Container(
            decoration: BoxDecoration(
              color: Colors.black,
              border: Border.all(color: Colors.white, width: 2),
            ),
            child: Stack(
              fit: StackFit.expand,
              children: [
                // Camera preview
                AspectRatio(
                  aspectRatio: widget.controller.value.aspectRatio,
                  child: CameraPreview(widget.controller),
                ),
                // Detection boxes (from displayBoxesAroundRecognizedObjects)
                ...widget.displayBoxesAroundRecognizedObjects(screenSize),
                // Control buttons
                Positioned(
                  bottom: 150,
                  width: MediaQuery.of(context).size.width,
                  child: Center(
                    child: Container(
                      height: 80,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(width: 5, color: Colors.white),
                      ),
                      child: IconButton(
                        onPressed: widget.isDetecting
                            ? widget.onStopDetection
                            : widget.onStartDetection,
                        icon: Icon(
                          widget.isDetecting ? Icons.stop : Icons.play_arrow,
                          color: widget.isDetecting ? Colors.red : Colors.white,
                        ),
                        iconSize: 50,
                      ),
                    ),
                  ),
                ),
                // Heart rate and prediction display at the bottom
                Positioned(
                  bottom: 20,
                  left: 20,
                  right: 20,
                  child: Container(
                    padding: const EdgeInsets.all(10),
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
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          "Predicted: $_prediction BPM",
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          "Alert: $_alert ",
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

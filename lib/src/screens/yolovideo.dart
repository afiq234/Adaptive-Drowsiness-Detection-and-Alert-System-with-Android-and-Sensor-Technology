import 'package:alarm/alarm.dart';
import 'package:flutter_vision/flutter_vision.dart';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:logging/logging.dart' as logging;
import 'package:yolodetection/src/components/camera_layout.dart';
import 'package:audioplayers/audioplayers.dart';
import 'dart:typed_data';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import '../key/api.dart';

late List<CameraDescription> cameras;

class YoloVideo extends StatefulWidget {
  const YoloVideo({super.key});

  @override
  State<YoloVideo> createState() => _YoloVideoState();
}

class _YoloVideoState extends State<YoloVideo> {
  late CameraController _controller;
  late FlutterVision _vision;
  late List<Map<String, dynamic>> _yoloResults;

  CameraImage? _cameraImage;
  bool _isLoaded = false;
  bool _isDetecting = false;
  int _frameCounter = 0;

  bool _isAlarmActive = false;
  CloudApi? _cloudApi;

  @override
  void initState() {
    super.initState();
    initializeCamera();
    Alarm.init(); // Initialize the alarm package
    // _initializeCloudApi();
  }

  // Future<void> _initializeCloudApi() async {
  //   try {
  //     final credentials =
  //         await rootBundle.loadString('assets/credentials/credentials.json');
  //     _cloudApi = CloudApi(credentials);
  //     logging.Logger('YoloVideo').info('Cloud API initialized');
  //     print('Cloud API initialized');
  //   } catch (e) {
  //     logging.Logger('YoloVideo').severe('Failed to initialize Cloud API: $e');
  //     print('Cloud API Failed');
  //   }
  // }

  Future<void> initializeCamera() async {
    cameras = await availableCameras();
    _vision = FlutterVision();
    _controller = CameraController(
      cameras[1], // Using the second camera
      ResolutionPreset.high,
    );

    try {
      await _controller.initialize();
      await loadYoloModel();
      setState(() {
        _isLoaded = true;
        _isDetecting = false;
        _yoloResults = [];
      });
    } catch (e) {
      logging.Logger('YoloVideo').severe("Camera initialization error: $e");
    }
  }

  @override
  void dispose() {
    // Properly dispose of resources
    _controller.dispose();
    _vision.closeYoloModel();
    super.dispose();
  }

  Future<void> loadYoloModel() async {
    await _vision.loadYoloModel(
      labels: 'assets/labels.txt',
      modelPath: 'assets/best_float32.tflite',
      modelVersion: "yolov8",
      quantization: false,
      numThreads: 4,
      useGpu: true,
    );
    setState(() {
      _isLoaded = true;
    });
  }

  Future<void> yoloOnFrame(CameraImage cameraImage) async {
    try {
      final result = await _vision.yoloOnFrame(
        bytesList: cameraImage.planes.map((plane) => plane.bytes).toList(),
        imageHeight: cameraImage.height,
        imageWidth: cameraImage.width,
        iouThreshold: 0.5,
        confThreshold: 0.3,
        classThreshold: 0.2,
      );
      setState(() {
        _yoloResults = result;
      });

      // Check for drowsiness and trigger alarm immediately
      if (_yoloResults.any((r) => r['tag'] == 'drowsy')) {
        triggerAlarm();
        // await saveImageToCloud(cameraImage, "drowsy");
        print('Drowsiness detected!');
      } else {
        stopAlarm();
        // await saveImageToCloud(cameraImage, "awake");
        print('No drowsiness detected.');
      }
    } catch (e) {
      logging.Logger('YoloVideo').severe("Detection error: $e");
    }
  }

  // Future<void> saveImageToCloud(CameraImage image, String status) async {
  //   try {
  //     final directory = await getTemporaryDirectory();
  //     final path =
  //         '${directory.path}/$status-${DateTime.now().millisecondsSinceEpoch}.jpg';
  //     final file = File(path);

  //     // Convert CameraImage to JPEG
  //     final bytes = await convertCameraImageToJpeg(image);
  //     await file.writeAsBytes(bytes);

  //     final name = file.path.split('/').last;

  //     if (_cloudApi != null) {
  //       await _cloudApi!.save(name, bytes);
  //       logging.Logger('YoloVideo').info('Image uploaded: $name');
  //       print('Image uploaded: $name');
  //     }
  //   } catch (e) {
  //     logging.Logger('YoloVideo').severe("Failed to save image to cloud: $e");
  //     print('Failed to save image to cloud: $e');
  //   }
  // }

  // Future<Uint8List> convertCameraImageToJpeg(CameraImage image) async {
  //   // This method would include the necessary processing to convert a raw CameraImage to JPEG.
  //   // Depending on the platform and libraries, this can involve using image processing packages.
  //   throw UnimplementedError(); // Replace with actual implementation
  // }

  void triggerAlarm() {
    if (!_isAlarmActive) {
      Alarm.set(
        alarmSettings: AlarmSettings(
          id: 42,
          dateTime: DateTime.now().add(Duration(seconds: 1)),
          assetAudioPath: 'assets/alarm.wav',
          loopAudio: true,
          vibrate: true,
          fadeDuration: 3.0,
          notificationTitle: 'Drowsiness Detected',
          notificationBody: 'Please take a break!',
          enableNotificationOnKill: true,
        ),
      );
      setState(() {
        _isAlarmActive = true;
      });
    }
  }

  void stopAlarm() {
    if (_isAlarmActive) {
      Alarm.stop(42); // Provide the alarm ID
      setState(() {
        _isAlarmActive = false;
      });
    }
  }

  Future<void> startDetection() async {
    if (_controller.value.isStreamingImages || _isDetecting) return;

    setState(() {
      _isDetecting = true;
    });

    await _controller.startImageStream((image) async {
      if (_frameCounter % 2 == 0) {
        // Process every 2nd frame
        _cameraImage = image;
        await yoloOnFrame(image);
      }
      _frameCounter++;
    });
  }

  Future<void> stopDetection() async {
    setState(() {
      _isDetecting = false;
      _yoloResults.clear();
    });
    if (_controller.value.isStreamingImages) {
      await _controller.stopImageStream();
    }
    stopAlarm();
  }

  List<Widget> displayBoxesAroundRecognizedObjects(Size screen) {
    if (_yoloResults.isEmpty) return [];
    double factorX = screen.width / (_cameraImage?.height ?? 1);
    double factorY = screen.height / (_cameraImage?.width ?? 1);

    return _yoloResults.map(
      (result) {
        double objectX = result["box"][0] * factorX;
        double objectY = result["box"][1] * factorY;
        double objectWidth = (result["box"][2] - result["box"][0]) * factorX;
        double objectHeight = (result["box"][3] - result["box"][1]) * factorY;

        return Positioned(
          left: objectX,
          top: objectY,
          width: objectWidth,
          height: objectHeight,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.all(Radius.circular(10.0)),
              border: Border.all(color: Colors.pink, width: 2.0),
            ),
            child: Text(
              "${result['tag']} ${(result['box'][4] * 100).toStringAsFixed(1)}%",
              style: const TextStyle(
                backgroundColor: Colors.green,
                color: Colors.white,
                fontSize: 14.0,
              ),
            ),
          ),
        );
      },
    ).toList();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isLoaded) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }
    return Scaffold(
      appBar: AppBar(
        title: const Text("YOLO Video"),
      ),
      body: CameraLayout(
        controller: _controller,
        isDetecting: _isDetecting,
        displayBoxesAroundRecognizedObjects:
            displayBoxesAroundRecognizedObjects,
        onStopDetection: stopDetection,
        onStartDetection: startDetection,
        detectionBoxes: displayBoxesAroundRecognizedObjects(
          MediaQuery.of(context).size,
        ),
      ),
    );
  }
}

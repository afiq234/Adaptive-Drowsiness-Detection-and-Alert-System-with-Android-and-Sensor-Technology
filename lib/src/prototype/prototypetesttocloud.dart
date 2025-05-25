import 'package:alarm/alarm.dart';
import 'package:flutter_vision/flutter_vision.dart';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:logging/logging.dart' as logging;
import 'package:yolodetection/src/components/camera_layout.dart';
import 'dart:typed_data';
import 'dart:math';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:image/image.dart' as img;
import '../key/api.dart';

late List<CameraDescription> cameras;

class Prototypetesttocloud extends StatefulWidget {
  const Prototypetesttocloud({super.key});

  @override
  State<Prototypetesttocloud> createState() => _PrototypetesttocloudState();
}

class _PrototypetesttocloudState extends State<Prototypetesttocloud> {
  late CameraController _controller;
  late FlutterVision _vision;
  late List<Map<String, dynamic>> _yoloResults;
  CameraImage? _cameraImage;
  bool _isLoaded = false;
  bool _isDetecting = false;
  int _frameCounter = 0;
  bool _isAlarmActive = false;
  CloudApi? _cloudApi;
  final Set<String> _uploadedFrames =
      {}; // To avoid re-uploading the same frame
  int awakeCount = 0;
  int drowsyCount = 0;
  final debounceDuration = Duration(seconds: 5);
  DateTime? lastUploadTime;

  void handleDetection(Map<String, dynamic> detection) {
    if (detection['tag'] == 'drowsy') {
      drowsyCount++;
      awakeCount = 0; // Reset awake count
      if (drowsyCount >= 3) {
        // Require 3 consecutive frames
        print("Consistent drowsy state detected, triggering alarm...");
        triggerAlarm();
      }
    } else if (detection['tag'] == 'awake') {
      awakeCount++;
      drowsyCount = 0; // Reset drowsy count
      if (awakeCount >= 3) {
        // Require 3 consecutive frames
        print("Consistent awake state detected, stopping alarm...");
        stopAlarm();
      }
    }
  }

  @override
  void initState() {
    super.initState();
    initializeCamera();
    Alarm.init();
    _initializeCloudApi();
  }

  Future<void> _initializeCloudApi() async {
    try {
      final credentials =
          await rootBundle.loadString('assets/credentials/credentials.json');
      _cloudApi = CloudApi(credentials);
      logging.Logger('YoloVideo').info('Cloud API initialized');
      print('Cloud API initialized');
    } catch (e) {
      logging.Logger('YoloVideo').severe('Failed to initialize Cloud API: $e');
      print('Cloud API Failed');
    }
  }

  Future<void> initializeCamera() async {
    cameras = await availableCameras();
    _vision = FlutterVision();
    _controller = CameraController(
      cameras[1],
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
        iouThreshold: 0.4, // Increase for stricter bounding box overlap
        confThreshold: 0.4, // Higher confidence required for detection
        classThreshold: 0.2, // Adjust for class-specific sensitivity
      );
      setState(() {
        _yoloResults = result;
      });

      // Handle detection and upload logic
      for (var detection in _yoloResults) {
        if (detection['tag'] == 'drowsy') {
          final frameKey =
              '${detection['tag']}-${DateTime.now().millisecondsSinceEpoch}';
          if (!_uploadedFrames.contains(frameKey)) {
            _uploadedFrames.add(frameKey);
            triggerAlarm();
            await saveImageToCloud(cameraImage, detection['tag']);
          }
        } else if (detection['tag'] == 'awake') {
          final frameKey =
              '${detection['tag']}-${DateTime.now().millisecondsSinceEpoch}';
          if (!_uploadedFrames.contains(frameKey)) {
            _uploadedFrames.add(frameKey);
            await saveImageToCloud(cameraImage, detection['tag']);
          }
        }
      }
    } catch (e) {
      logging.Logger('YoloVideo').severe("Detection error: $e");
    }
  }

  Future<void> saveImageToCloud(CameraImage image, String status) async {
    try {
      final directory = await getTemporaryDirectory();
      final path =
          '${directory.path}/$status-${DateTime.now().millisecondsSinceEpoch}.jpg';
      final file = File(path);

      // Convert CameraImage to JPEG
      final bytes = await convertCameraImageToJpeg(image);
      await file.writeAsBytes(bytes);

      final name = file.path.split('/').last;

      if (_cloudApi != null) {
        await _cloudApi!.save(name, bytes);
        logging.Logger('YoloVideo').info('Image uploaded: $name');
        print('Image uploaded: $name');
      }
    } catch (e) {
      logging.Logger('YoloVideo').severe("Failed to save image to cloud: $e");
      print('Failed to save image to cloud: $e');
    }
  }

  Future<Uint8List> convertCameraImageToJpeg(CameraImage image) async {
    try {
      const int cropWidth = 640;
      const int cropHeight = 640;

      // Use Plane data to construct RGB image
      final img.Image imgData = img.Image.fromBytes(
        width: image.width,
        height: image.height,
        bytes: _convertYUV420ToRGB(image).buffer,
      );

      // Crop the image to 640x640 from the center
      final img.Image croppedImg = img.copyCrop(
        imgData,
        x: (image.width - cropWidth) ~/ 2,
        y: (image.height - cropHeight) ~/ 2,
        width: cropWidth,
        height: cropHeight,
      );

      // Encode as JPEG
      return Uint8List.fromList(img.encodeJpg(croppedImg));
    } catch (e) {
      logging.Logger('YoloVideo')
          .severe("Error converting CameraImage to JPEG: $e");
      rethrow;
    }
  }

  Uint8List _convertYUV420ToRGB(CameraImage image) {
    final int width = image.width;
    final int height = image.height;
    final int size = width * height;

    final Uint8List yBuffer = image.planes[0].bytes;
    final Uint8List uBuffer = image.planes[1].bytes;
    final Uint8List vBuffer = image.planes[2].bytes;

    final Uint8List rgbBuffer = Uint8List(size * 3);

    for (int i = 0; i < height; i++) {
      for (int j = 0; j < width; j++) {
        final int yIndex = i * width + j;
        final int uvIndex = (i ~/ 2) * (width ~/ 2) + (j ~/ 2);

        final int y = yBuffer[yIndex];
        final int u = uBuffer[uvIndex] - 128;
        final int v = vBuffer[uvIndex] - 128;

        final int r = (y + 1.402 * v).clamp(0, 255).toInt();
        final int g = (y - 0.344 * u - 0.714 * v).clamp(0, 255).toInt();
        final int b = (y + 1.772 * u).clamp(0, 255).toInt();

        final int rgbIndex = yIndex * 3;
        rgbBuffer[rgbIndex] = r;
        rgbBuffer[rgbIndex + 1] = g;
        rgbBuffer[rgbIndex + 2] = b;
      }
    }

    return rgbBuffer;
  }

  void triggerAlarm() {
    try {
      Alarm.set(
        alarmSettings: AlarmSettings(
          id: 42,
          dateTime: DateTime.now()
              .add(const Duration(milliseconds: 500)), // Immediate trigger
          assetAudioPath: 'assets/alarm.wav', // Audio file path
          loopAudio: true,
          vibrate: true,
          fadeDuration: 1.0,
          notificationTitle: 'Drowsiness Detected',
          notificationBody: 'Please take a break!',
          enableNotificationOnKill: true,
        ),
      );
      logging.Logger('Alarm').info('Alarm triggered successfully.');
      print('Alarm triggered successfully.');
      setState(() {
        _isAlarmActive = true;
      });
    } catch (e) {
      logging.Logger('Alarm').severe('Failed to trigger alarm: $e');
      print('Failed to trigger alarm: $e');
    }
  }

  void stopAlarm() {
    try {
      Alarm.stop(42);
      logging.Logger('Alarm').info('Alarm stopped.');
      setState(() {
        _isAlarmActive = false;
      });
    } catch (e) {
      logging.Logger('Alarm').severe('Failed to stop alarm: $e');
    }
  }

  Future<void> startDetection() async {
    if (_controller.value.isStreamingImages || _isDetecting) return;

    setState(() {
      _isDetecting = true;
    });

    await _controller.startImageStream((image) async {
      if (_frameCounter % 2 == 0) {
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

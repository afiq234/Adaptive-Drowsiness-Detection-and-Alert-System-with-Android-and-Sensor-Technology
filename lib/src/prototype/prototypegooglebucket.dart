import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:yolodetection/src/key/api.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      debugShowCheckedModeBanner: false,
      home: Prototypegooglebucket(
        title: 'Prototype Google Bucket',
        key: GlobalKey(),
      ),
    );
  }
}

class Prototypegooglebucket extends StatefulWidget {
  Prototypegooglebucket({required Key key, required this.title})
      : super(key: key);
  final String title;

  @override
  State<Prototypegooglebucket> createState() => _PrototypegooglebucketState();
}

class _PrototypegooglebucketState extends State<Prototypegooglebucket> {
  final picker = ImagePicker();
  late File _image;
  late String _imageName;
  Uint8List? _imageBytes; // Make _imageBytes nullable
  late CloudApi api;

  @override
  void initState() {
    super.initState();
    rootBundle.loadString('assets/credentials/credentials.json').then((json) {
      api = CloudApi(json);
    });
  }

  void _getImage() async {
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    setState(() {
      if (pickedFile != null) {
        _image = File(pickedFile.path);
        _imageBytes = _image.readAsBytesSync(); // Assign to _imageBytes
        _imageName = _image.path.split('/').last;
      } else {
        print('No image selected.');
      }
    });
  }

  void _saveImage() async {
    if (_imageBytes == null) {
      print('No image to save');
      return;
    }
    final response = await api.save(_imageName, _imageBytes!); // Use null check
    print(response.downloadLink);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Center(
        child: _imageBytes == null
            ? Text("No image selected")
            : Stack(
                children: [
                  Image.memory(_imageBytes!),
                  Align(
                    alignment: Alignment.bottomCenter,
                    child: ElevatedButton(
                      onPressed: _saveImage,
                      child: Text("Save to the cloud"),
                    ),
                  )
                ],
              ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _getImage,
        tooltip: 'Select image',
        child: const Icon(Icons.add_a_photo),
      ),
    );
  }
}

import 'dart:io';
import 'dart:math';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:google_ml_kit/google_ml_kit.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Face Detection App',
      theme: ThemeData(
        primaryColor: Colors.blue,
        scaffoldBackgroundColor: Colors.white,
      ),
      home: FaceDetectionPage(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class FaceDetectionPage extends StatefulWidget {
  @override
  _FaceDetectionPageState createState() => _FaceDetectionPageState();
}

class _FaceDetectionPageState extends State<FaceDetectionPage> {
  CameraController? _cameraController;
  FaceDetector? _faceDetector;
  bool _isDetecting = false;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
    _initializeFaceDetector();
  }

  Future<void> _initializeCamera() async {
    final cameras = await availableCameras();
    final firstCamera = cameras.first;
    _cameraController = CameraController(firstCamera, ResolutionPreset.medium);
    await _cameraController!.initialize();
    if (!mounted) return;
    setState(() {});
  }

  Future<void> _initializeFaceDetector() async {
    final options = FaceDetectorOptions(
      performanceMode: FaceDetectorMode.accurate,
      enableLandmarks: true,
      enableContours: true,
      enableClassification: true,
      minFaceSize: 0.1,
      enableTracking: true,
    );

    _faceDetector = GoogleMlKit.vision.faceDetector(options);
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    _faceDetector?.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      return Center(child: CircularProgressIndicator());
    }
    return Scaffold(
      appBar: AppBar(
        title: Text('Face Detection'),
      ),
      body: Stack(
        children: [
          CameraPreview(_cameraController!),
          Positioned(
            bottom: 20,
            left: 0,
            right: 0,
            child: _buildCaptureButton(),
          ),
        ],
      ),
    );
  }

  Widget _buildCaptureButton() {
    return FloatingActionButton(
      onPressed: _detectFace,
      child: Icon(Icons.camera_alt),
      backgroundColor: Colors.blue,
    );
  }

  Future<void> _detectFace() async {
    if (_isDetecting) return;

    _isDetecting = true;
    final image = await _cameraController!.takePicture();

    final inputImage = InputImage.fromFilePath(image.path);
    final List<Face> faces = await _faceDetector!.processImage(inputImage);

    String result = '';
    for (int i = 0; i < faces.length; i++) {
      final Face face = faces[i];
      final Rect boundingBox = face.boundingBox;
      final double? rotX = face.headEulerAngleX;
      final double? rotY = face.headEulerAngleY;
      final double? rotZ = face.headEulerAngleZ;

      result += 'Face ${i + 1}:\n';
      result += 'Bounding Box: $boundingBox\n';
      result += 'Head Elevation: $rotX, $rotY, $rotZ\n';

      // If landmark detection was enabled:
      final FaceLandmark? leftEar = face.landmarks[FaceLandmarkType.leftEar];
      if (leftEar != null) {
        final Point<int> leftEarPos = leftEar.position;
        result += 'Left Ear Position: $leftEarPos\n';
      }

      // If classification was enabled:
      if (face.smilingProbability != null) {
        final double? smileProb = face.smilingProbability;
        result += 'Smiling Probability: $smileProb\n';
      }

      // If face tracking was enabled:
      if (face.trackingId != null) {
        final int? id = face.trackingId;
        result += 'Tracking ID: $id\n';
      }

      result += '\n';
    }

    _showAlertDialog(result);

    _isDetecting = false;
  }

  Future<void> _showAlertDialog(String message) async {
    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Face Detection Result'),
          content: Text(message),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('OK'),
            ),
          ],
        );
      },
    );
  }
}

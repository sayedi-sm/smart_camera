import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_mlkit_object_detection/google_mlkit_object_detection.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:ui' as ui;

import '../main.dart';


class ObjectDetectionPage extends StatefulWidget {
  const ObjectDetectionPage({Key? key}) : super(key: key);

  @override
  State<ObjectDetectionPage> createState() => _ObjectDetectionPageState();
}

class _ObjectDetectionPageState extends State<ObjectDetectionPage> {
  late CameraController cameraController;
  CameraImage? cameraImage;
  Rect? detection;
  Timer? timer;

  Future<void> initCamera() async {
    cameraController = CameraController(cameras[0], ResolutionPreset.low);
    await cameraController.initialize();
    setState(() {});
    timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      runModelOnStreamImages();
    });
    if (mounted) {
      cameraController.startImageStream((image) {
        cameraImage = image;
        print('image width: ${cameraImage?.width}');
        print('image height: ${cameraImage?.height}');
      });
    }
  }

  Future<void> runModelOnStreamImages() async {
    if (cameraImage != null) {
      int time1 = DateTime.now().millisecondsSinceEpoch;

      final List<DetectedObject> objects =
          await objectDetector.processImage(_processCameraImage());
      int time2 = DateTime.now().millisecondsSinceEpoch;
      print('Time inside run model: ${time2 - time1} milli secs!');

      for (DetectedObject detectedObject in objects) {
        detection = detectedObject.boundingBox;
        print('Detection: $detection');
        setState(() {});
        Label label = detectedObject.labels.first;
        print(
            'Label: ${label.text}\nConfidence: ${label.confidence}\nBounding box: $detection');
      }
    }
  }

  InputImage _processCameraImage() {
    int time1 = DateTime.now().millisecondsSinceEpoch;
    final WriteBuffer allBytes = WriteBuffer();
    for (final Plane plane in cameraImage!.planes) {
      allBytes.putUint8List(plane.bytes);
    }
    final bytes = allBytes.done().buffer.asUint8List();

    final Size imageSize =
        Size(cameraImage!.width.toDouble(), cameraImage!.height.toDouble());

    final camera = cameras[0];
    final imageRotation =
        InputImageRotationValue.fromRawValue(camera.sensorOrientation);

    final inputImageFormat =
        InputImageFormatValue.fromRawValue(cameraImage!.format.raw);

    final planeData = cameraImage!.planes.map(
      (Plane plane) {
        return InputImagePlaneMetadata(
          bytesPerRow: plane.bytesPerRow,
          height: plane.height,
          width: plane.width,
        );
      },
    ).toList();

    final inputImageData = InputImageData(
      size: imageSize,
      imageRotation: imageRotation!,
      inputImageFormat: inputImageFormat!,
      planeData: planeData,
    );

    final inputImage =
        InputImage.fromBytes(bytes: bytes, inputImageData: inputImageData);
    int time2 = DateTime.now().millisecondsSinceEpoch;
    print('Time inside processImage: ${time2 - time1} milli secs!');
    return inputImage;
  }

  Future<String> _getModel(String assetPath) async {
    if (Platform.isAndroid) {
      return 'flutter_assets/$assetPath';
    }
    final path = '${(await getApplicationSupportDirectory()).path}/$assetPath';
    await Directory(dirname(path)).create(recursive: true);
    final file = File(path);
    if (!await file.exists()) {
      final byteData = await rootBundle.load(assetPath);
      await file.writeAsBytes(byteData.buffer
          .asUint8List(byteData.offsetInBytes, byteData.lengthInBytes));
    }
    return file.path;
  }

  XFile? photo;
  ui.Image? image;
  late String modelPath;
  late ObjectDetector objectDetector;
  List<Rect> detections = <Rect>[];

  Future<void> initializeModel() async {
    modelPath = await _getModel('assets/ml/efficientnet_lite0_int8_2.tflite');
    final options = LocalObjectDetectorOptions(
      mode: DetectionMode.single,
      modelPath: modelPath,
      classifyObjects: true,
      multipleObjects: false,
      maximumLabelsPerObject: 1,
      confidenceThreshold: 0.1,
    );
    objectDetector = ObjectDetector(options: options);
  }

  Future<ui.Image> loadImage(File file) async {
    final data = await file.readAsBytes();
    return await decodeImageFromList(data);
  }

  @override
  void initState() {
    super.initState();
    initializeModel();
    initCamera();
  }

  @override
  void dispose() {
    cameraController.dispose();
    objectDetector.close();
    timer?.cancel();
    super.dispose();
  }

  double? pixelRatio;

  @override
  Widget build(BuildContext context) {
    pixelRatio ??= MediaQuery.of(context).devicePixelRatio;
    print('Device width: ${MediaQuery.of(context).size.width * pixelRatio!}');
    print('Device height: ${MediaQuery.of(context).size.height * pixelRatio!}');
    return Scaffold(
      body: Stack(
        children: [
          cameraController.value.isInitialized
              ? CameraPreview(
                  cameraController,
                  child: detection != null
                      ? Container(
                          color: Colors.red.withOpacity(0.5),
                          child: CustomPaint(
                            painter: DetectPainter(
                              detection: detection! * pixelRatio!,
                            ),
                          ),
                        )
                      : null,
                )
              : Container(color: Colors.black),
        ],
      ),
    );
  }
}

extension on ui.Rect {
  ui.Rect operator *(double num) {
    return ui.Rect.fromLTRB(left * num, top * num, right * num, bottom * num);
  }
}

class DetectPainter extends CustomPainter {
  DetectPainter({required this.detection});

  Rect detection;

  @override
  void paint(Canvas canvas, Size size) {
    print('Rect width: ${detection.width}');
    canvas.drawRect(
      detection,
      Paint()
        ..color = Colors.red
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

import 'dart:async';
import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:google_mlkit_object_detection/google_mlkit_object_detection.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';

class CameraProvider extends ChangeNotifier {
  late List<CameraDescription> _cameras;
  late CameraController cameraController;
  late Future<void> cameraInitializationFuture;

  CameraImage? _cameraImage;
  Rect? detection;
  ObjectDetector? _objectDetector;
  Timer? _timer;

  bool isPrepared = false;
  double _zoomLevel = 1;
  double? _maxZoomLevel;

  Future<void> init() async {
    _initializeModel();
    _cameras = await availableCameras();
    cameraController = CameraController(
      _cameras[0],
      ResolutionPreset.max,
      enableAudio: false,
    );
    cameraInitializationFuture = cameraController.initialize().then((value) {
      _getMaxZoomLevel();
      _startImageStream();
    });

    isPrepared = true;
    notifyListeners();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _runModelOnStreamImages();
    });
  }

  Future<void> _startImageStream() {
    return cameraController.startImageStream((image) {
      print('inside startImageStream');
      _cameraImage = image;
      print('image width: ${_cameraImage!.height}');
      print('image height: ${_cameraImage!.width}');
    });
  }

  Future<void> _runModelOnStreamImages() async {
    if (_cameraImage != null) {
      int time1 = DateTime.now().millisecondsSinceEpoch;
      InputImage inputImage = _processCameraImage();
      final List<DetectedObject> objects =
          await _objectDetector!.processImage(inputImage);
      int time2 = DateTime.now().millisecondsSinceEpoch;
      print('Time inside run model: ${time2 - time1} milli secs!');

      if (objects.isNotEmpty) {
        DetectedObject detectedObject = objects.first;
        detection = detectedObject.boundingBox;
        print('Detection: $detection');
        if (detectedObject.labels.isNotEmpty) {
          Label label = detectedObject.labels.first;
          print(
              'Label: ${label.text}\nConfidence: ${label.confidence}\nBounding box: $detection');
        }
      } else {
        detection = null;
      }
      notifyListeners();
    }
  }

  InputImage _processCameraImage() {
    int time1 = DateTime.now().millisecondsSinceEpoch;
    final WriteBuffer allBytes = WriteBuffer();
    for (final Plane plane in _cameraImage!.planes) {
      allBytes.putUint8List(plane.bytes);
    }
    final bytes = allBytes.done().buffer.asUint8List();

    final Size imageSize =
        Size(_cameraImage!.width.toDouble(), _cameraImage!.height.toDouble());

    final camera = _cameras[0];
    final imageRotation =
        InputImageRotationValue.fromRawValue(camera.sensorOrientation);

    final inputImageFormat =
        InputImageFormatValue.fromRawValue(_cameraImage!.format.raw);

    final planeData = _cameraImage!.planes.map(
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

  Future<void> _initializeModel() async {
    final String modelPath =
        await _getModel('assets/ml/efficientnet_lite0_int8_2.tflite');
    final options = LocalObjectDetectorOptions(
      mode: DetectionMode.single,
      modelPath: modelPath,
      classifyObjects: true,
      multipleObjects: false,
      maximumLabelsPerObject: 1,
      confidenceThreshold: 0.1,
    );
    _objectDetector = ObjectDetector(options: options);
  }

  Future<void> _getMaxZoomLevel() async {
    _maxZoomLevel ??= await cameraController.getMaxZoomLevel();
  }

  void zoomIn() {
    if (++_zoomLevel <= _maxZoomLevel!) {
      cameraController.setZoomLevel(_zoomLevel);
    } else {
      cameraController.setZoomLevel(_zoomLevel = _maxZoomLevel!);
    }
  }

  void zoomOut() {
    if (--_zoomLevel >= 1) {
      cameraController.setZoomLevel(_zoomLevel);
    } else {
      cameraController.setZoomLevel(_zoomLevel = 1);
    }
  }

  double get zoomLevel => _zoomLevel;

  void freeResources() {
    cameraController.dispose();
    _objectDetector?.close();
    _timer?.cancel();
    detection = null;
    _cameraImage = null;
    _zoomLevel = 1;
  }
}

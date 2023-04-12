import 'dart:async';
import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:gallery_saver/gallery_saver.dart';
import 'package:google_mlkit_object_detection/google_mlkit_object_detection.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';

class CameraProvider extends ChangeNotifier {
  late List<CameraDescription> _cameras;
  late CameraController cameraController;
  late Future<void> cameraInitializationFuture;

  ObjectDetector? _objectDetector;
  CameraImage? _cameraImage;
  XFile? _pictureFile;

  Rect? detection;
  Size? deviceSize;
  double? _maxZoomLevel;
  bool isCameraPrepared = false;

  Timer? _runModelTimer;
  Timer? _zoomTimer;

  XFile? get pictureFile => _pictureFile;

  Future<void> init() async {
    _initializeModel();
    _cameras = await availableCameras();
    cameraController = CameraController(
      _cameras[0],
      ResolutionPreset.max,
      enableAudio: false,
    );
    cameraInitializationFuture = cameraController.initialize().then((value) {
      _calculateMaxZoomLevel();
    });

    isCameraPrepared = true;
    notifyListeners();
  }

  Future<void> _startImageStream() {
    return cameraController.startImageStream((image) => _cameraImage = image);
  }

  Future<void> _runModelOnStreamImages() async {
    if (_cameraImage != null) {
      InputImage inputImage = _processCameraImage();
      final List<DetectedObject> objects =
          await _objectDetector!.processImage(inputImage);
      if (objects.isNotEmpty) {
        detection = objects.first.boundingBox;
        if (deviceSize!.width - detection!.width <= 50 ||
            deviceSize!.height - detection!.height <= 50) {
          _runModelTimer?.cancel();
          _zoomTimer?.cancel();
          if (cameraController.value.isStreamingImages) {
            await cameraController.stopImageStream();
          }
          _pictureFile = await cameraController.takePicture();
          notifyListeners();
          return;
        }
      } else {
        detection = null;
      }
      notifyListeners();
    }
  }

  InputImage _processCameraImage() {
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

  Future<void> _calculateMaxZoomLevel() async {
    _maxZoomLevel ??= await cameraController.getMaxZoomLevel();
  }

  void _startTimer() {
    _runModelTimer = Timer.periodic(const Duration(milliseconds: 450), (timer) {
      _runModelOnStreamImages();
    });
  }

  void autozoom() async {
    _startImageStream();
    _startTimer();
    await Future.delayed(
      const Duration(seconds: 1),
      () {
        int i = 4;
        _zoomTimer = Timer.periodic(
          const Duration(milliseconds: 450),
          (timer) {
            if (i <= _maxZoomLevel!.toInt() * 4 && pictureFile == null) {
              cameraController.setZoomLevel(i / 4);
              i++;
            } else {
              timer.cancel();
            }
          },
        );
      },
    );
  }

  void _resetZoom() {
    cameraController.setZoomLevel(1);
  }

  void saveToGallery({required VoidCallback onSaveComplete}) async {
    await GallerySaver.saveImage(
      (_pictureFile?.path)!,
      albumName: 'Smart Camera',
    );
    discardPhoto();
    onSaveComplete();
  }

  void discardPhoto() {
    _pictureFile = null;
    detection = null;
    _cameraImage = null;
    notifyListeners();
    _resetZoom();
  }

  void freeResources() {
    cameraController.dispose();
    _objectDetector?.close();
    _runModelTimer?.cancel();
    _zoomTimer?.cancel();
    detection = null;
    _cameraImage = null;
    _pictureFile = null;
  }
}

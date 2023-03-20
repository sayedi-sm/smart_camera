import 'package:camera/camera.dart';
import 'package:flutter/cupertino.dart';

class CameraProvider extends ChangeNotifier {
  late List<CameraDescription> cameras;
  late CameraController cameraController;
  late Future<void> cameraInitializationFuture;

  bool isPrepared = false;
  double _zoomLevel = 1;
  double? maxZoomLevel;
  XFile? photoFile;

  Future<void> init() async {
    cameras = await availableCameras();
    cameraController = CameraController(cameras[0], ResolutionPreset.medium,
        enableAudio: false);
    cameraInitializationFuture = cameraController.initialize();
    isPrepared = true;
    notifyListeners();
  }

  Future<void> takePhoto() async {
    cameraController.value.flashMode;
    try {
      photoFile = await cameraController.takePicture();
    } catch (e) {
      print('Photo taking error: $e');
    }
  }

  Future<void> getZoomLevels() async {
    if (maxZoomLevel == null) {
      maxZoomLevel = await cameraController.getMaxZoomLevel();
      notifyListeners();
    }
  }

  set zoomLevel(double value) {
    _zoomLevel = value;
    cameraController.setZoomLevel(_zoomLevel);
    notifyListeners();
  }

  double get zoomLevel => _zoomLevel;

  void freeResources() {
    cameraController.dispose();
  }
}

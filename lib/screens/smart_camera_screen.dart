import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smart_camera/utils/detection_rect.dart';
import 'package:smart_camera/widgets/photo_preview.dart';

import '../providers/camera_provider.dart';
import '../widgets/detect_painter.dart';

class SmartCameraScreen extends StatefulWidget {
  const SmartCameraScreen({Key? key}) : super(key: key);
  static const String routeName = 'SmartCameraScreen';

  @override
  State<SmartCameraScreen> createState() => _SmartCameraScreenState();
}

class _SmartCameraScreenState extends State<SmartCameraScreen> {
  @override
  void initState() {
    super.initState();
    cameraProvider = Provider.of<CameraProvider>(context, listen: false);
    cameraProvider.init();
  }

  @override
  void dispose() {
    cameraProvider.freeResources();
    super.dispose();
  }

  late CameraProvider cameraProvider;

  double? pixelRatio;

  @override
  Widget build(BuildContext context) {
    pixelRatio ??= MediaQuery.of(context).devicePixelRatio;
    cameraProvider.deviceSize ??= MediaQuery.of(context).size * pixelRatio!;
    return Scaffold(
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 8.0),
        child: FloatingActionButton(
          onPressed: cameraProvider.autozoom,
          child: const Icon(Icons.camera),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      body: Consumer<CameraProvider>(
        builder: (_, CameraProvider cameraProvider, __) {
          return cameraProvider.isCameraPrepared
              ? FutureBuilder(
                  future: cameraProvider.cameraInitializationFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.done) {
                      return Stack(
                        children: [
                          const SizedBox.expand(),
                          CameraPreview(
                            cameraProvider.cameraController,
                            child: cameraProvider.detection != null
                                ? CustomPaint(
                                    painter: DetectPainter(
                                      detection: cameraProvider.detection! /
                                          pixelRatio!,
                                    ),
                                  )
                                : null,
                          ),
                          if (cameraProvider.pictureFile != null)
                            Positioned(
                              top: MediaQuery.of(context).viewPadding.top + 24,
                              right: 24,
                              child: const PhotoPreview(),
                            ),
                        ],
                      );
                    }
                    return Container(color: Colors.black);
                  },
                )
              : Container(color: Colors.black);
        },
      ),
    );
  }
}

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smart_camera/utils/detection_rect.dart';

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
    print('Device width: ${MediaQuery.of(context).size.width * pixelRatio!}');
    print('Device height: ${MediaQuery.of(context).size.height * pixelRatio!}');
    return Scaffold(
      body: Consumer<CameraProvider>(
        builder: (_, CameraProvider cameraProvider, __) {
          return cameraProvider.isPrepared
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
                          Positioned(
                            bottom: 32,
                            left: 0,
                            right: 0,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: [
                                ElevatedButton(
                                  onPressed: cameraProvider.zoomOut,
                                  child: const Text('Zoom out'),
                                ),
                                ElevatedButton(
                                  onPressed: cameraProvider.zoomIn,
                                  child: const Text('Zoom in'),
                                ),
                                ElevatedButton(
                                  onPressed: cameraProvider.zoomOut,
                                  child: const Text('Take photo'),
                                ),
                                ElevatedButton(
                                  onPressed: cameraProvider.zoomIn,
                                  child: const Text('Auto zoom'),
                                ),
                              ],
                            ),
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

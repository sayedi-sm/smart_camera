import 'dart:io';

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
    cameraProvider.deviceSize ??= MediaQuery.of(context).size * pixelRatio!;
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
                          if (cameraProvider.pictureFile != null)
                            Positioned(
                              top: MediaQuery.of(context).viewPadding.top + 24,
                              right: 24,
                              child: Stack(
                                children: [
                                  Column(
                                    children: [
                                      SizedBox(
                                        width: 100,
                                        child: AspectRatio(
                                          aspectRatio: 1 /
                                              cameraProvider.cameraController
                                                  .value.aspectRatio,
                                          child: Container(
                                            decoration: BoxDecoration(
                                              image: DecorationImage(
                                                image: FileImage(
                                                  File(
                                                    (cameraProvider
                                                            .pictureFile)!
                                                        .path,
                                                  ),
                                                ),
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                              border: Border.all(
                                                  color: Colors.white),
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      SizedBox(
                                        width: 100,
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceAround,
                                          children: [
                                            GestureDetector(
                                              onTap:
                                                  cameraProvider.discardPhoto,
                                              child: CircleAvatar(
                                                radius: 14,
                                                backgroundColor: Colors.black
                                                    .withOpacity(0.5),
                                                child: const Icon(
                                                  Icons.close,
                                                  color: Colors.white,
                                                  size: 18,
                                                ),
                                              ),
                                            ),
                                            GestureDetector(
                                              onTap: () {
                                                cameraProvider.saveToGallery(
                                                  onSaveComplete: () =>
                                                      ScaffoldMessenger.of(
                                                              context)
                                                          .showSnackBar(
                                                    const SnackBar(
                                                      content: Text(
                                                          'Image saved to gallery!'),
                                                    ),
                                                  ),
                                                );
                                              },
                                              child: CircleAvatar(
                                                radius: 14,
                                                backgroundColor: Colors.black
                                                    .withOpacity(0.5),
                                                child: const Icon(
                                                  Icons.save_alt,
                                                  color: Colors.white,
                                                  size: 18,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          Positioned(
                            bottom: 32,
                            left: 0,
                            right: 0,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: [
                                ElevatedButton(
                                  onPressed: cameraProvider.autozoomOut,
                                  child: const Text('Zoom out'),
                                ),
                                ElevatedButton(
                                  onPressed: cameraProvider.autozoomIn,
                                  child: const Text('Zoom in'),
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

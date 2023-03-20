import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smart_camera/camera_provider.dart';
import 'package:smart_camera/screens/photo_display_screen.dart';

class CameraScreen extends StatefulWidget {
  const CameraScreen({Key? key}) : super(key: key);

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  late CameraProvider cameraProvider;

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          cameraProvider.takePhoto().then(
                (value) => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const PhotoDisplayScreen(),
                  ),
                ),
              );
        },
        child: const Icon(Icons.camera),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      body: Consumer<CameraProvider>(
        builder: (_, CameraProvider cameraProvider, __) {
          return cameraProvider.isPrepared
              ? FutureBuilder(
                  future: cameraProvider.cameraInitializationFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.done) {
                      cameraProvider.getZoomLevels();
                      return SizedBox(
                        width: double.infinity,
                        height: double.infinity,
                        child: CameraPreview(
                          cameraProvider.cameraController,
                          child: Stack(
                            children: const [
                              /*if (cameraProvider.maxZoomLevel != null)
                                Positioned(
                                  bottom: 100,
                                  left: 0,
                                  right: 0,
                                  child: Slider(
                                    value: cameraProvider.zoomLevel,
                                    min: 1,
                                    max: cameraProvider.maxZoomLevel!,
                                    onChanged: (double value) {
                                      cameraProvider.zoomLevel = value;
                                    },
                                  ),
                                ),*/
                            ],
                          ),
                        ),
                      );
                    }
                    return const CircularProgressIndicator();
                  },
                )
              : const Text('Not prepared yet!');
        },
      ),
    );
  }
}

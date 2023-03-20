import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smart_camera/camera_provider.dart';

class PhotoDisplayScreen extends StatelessWidget {
  const PhotoDisplayScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Consumer<CameraProvider>(
        builder: (_, CameraProvider cameraProvider, __) {
          return Image.file(
            File(cameraProvider.photoFile!.path),
            height: double.infinity,
            width: double.infinity,
            fit: BoxFit.cover,
          );
        },
      ),
    );
  }
}

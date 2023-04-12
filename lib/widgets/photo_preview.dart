import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smart_camera/providers/camera_provider.dart';

import 'preview_button.dart';

class PhotoPreview extends StatefulWidget {
  const PhotoPreview({super.key});

  @override
  State<PhotoPreview> createState() => _PhotoPreviewState();
}

class _PhotoPreviewState extends State<PhotoPreview> {
  late final CameraProvider cameraProvider;
  final double previewWidth = 100;

  @override
  void initState() {
    super.initState();
    cameraProvider = Provider.of<CameraProvider>(context, listen: false);
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Column(
          children: [
            SizedBox(
              width: previewWidth,
              child: AspectRatio(
                aspectRatio:
                    1 / cameraProvider.cameraController.value.aspectRatio,
                child: Container(
                  decoration: BoxDecoration(
                    image: DecorationImage(
                      image: FileImage(
                        File(
                          (cameraProvider.pictureFile)!.path,
                        ),
                      ),
                    ),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 4),
            SizedBox(
              width: previewWidth,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  PreviewButton(
                    icon: Icons.close,
                    onTap: cameraProvider.discardPhoto,
                  ),
                  PreviewButton(
                    icon: Icons.save_alt,
                    onTap: () {
                      cameraProvider.saveToGallery(
                        onSaveComplete: () =>
                            ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Image saved to gallery!'),
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}

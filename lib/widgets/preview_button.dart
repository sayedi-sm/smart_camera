import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/camera_provider.dart';

class PreviewButton extends StatefulWidget {
  const PreviewButton({
    super.key,
    required this.icon,
    required this.onTap,
  });

  final IconData icon;
  final VoidCallback onTap;

  @override
  State<PreviewButton> createState() => _PreviewButtonState();
}

class _PreviewButtonState extends State<PreviewButton> {
  late final CameraProvider cameraProvider;

  @override
  void initState() {
    super.initState();
    cameraProvider = Provider.of<CameraProvider>(context, listen: false);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: CircleAvatar(
        radius: 14,
        backgroundColor: Colors.black.withOpacity(0.5),
        child: Icon(
          widget.icon,
          color: Colors.white,
          size: 18,
        ),
      ),
    );
  }
}

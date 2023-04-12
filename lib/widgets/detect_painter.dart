import 'package:flutter/material.dart';

class DetectPainter extends CustomPainter {
  DetectPainter({required this.detection});

  Rect detection;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(
      detection,
      Paint()
        ..color = Colors.red
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

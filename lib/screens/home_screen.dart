import 'package:flutter/material.dart';
import 'package:smart_camera/screens/camera_screen.dart';
import 'package:smart_camera/screens/object_detection_page.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Home page'),
      ),
      body: Center(
        child: ElevatedButton(
          onPressed: () {
            Navigator.of(context).push(MaterialPageRoute(
                builder: (ctx) => const ObjectDetectionPage()));
          },
          child: const Text('Smart Camera'),
        ),
      ),
    );
  }
}

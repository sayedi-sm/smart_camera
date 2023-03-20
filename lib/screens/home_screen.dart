import 'package:flutter/material.dart';
import 'package:smart_camera/screens/smart_camera_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ElevatedButton(
            onPressed: () =>
                Navigator.pushNamed(context, SmartCameraScreen.routeName),
            child: const Text('Smart Camera'),
          ),
        ),
      ),
    );
  }
}

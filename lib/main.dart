import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:smart_camera/providers/camera_provider.dart';
import 'package:smart_camera/screens/home_screen.dart';
import 'package:smart_camera/screens/smart_camera_screen.dart';

void main() async {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: CameraProvider(),
      child: MaterialApp(
        title: 'Smart Camera',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          primarySwatch: Colors.blue,
        ),
        routes: {
          SmartCameraScreen.routeName: (_) => const SmartCameraScreen(),
        },
        home: const HomeScreen(),
      ),
    );
  }
}

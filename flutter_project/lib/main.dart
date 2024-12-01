import 'package:flutter/material.dart';
import 'package:flutter_project/screens/add_animal_screen.dart';
import 'package:flutter_project/screens/login_screen.dart';
import 'package:flutter_project/screens/test_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_project/screens/notification_screen.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_project/screens/test_screen.dart';  // Make sure to import this screen if needed
import 'package:flutter_project/screens/animal_history_screen.dart';  // Make sure to import this screen if needed

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Login Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: AnimalHistoryPage(),  // Show the SplashScreen first
    );
  }
}


import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'screens/map_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase (Assuming placeholder or default setup for now)
  try {
    await Firebase.initializeApp();
    await FirebaseAuth.instance.signInAnonymously();
  } catch (e) {
    debugPrint("Firebase init error (if running without config): $e");
  }
  
  runApp(const TrackSafeApp());
}

class TrackSafeApp extends StatelessWidget {
  const TrackSafeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TrackSafe',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.red),
        useMaterial3: true,
      ),
      home: const MapScreen(),
    );
  }
}

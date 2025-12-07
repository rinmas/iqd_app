import 'package:flutter/material.dart';
// import 'package:firebase_core/firebase_core.dart'; // 🔹 Commented out
import 'launcher.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized(); // Ensures bindings are ready before any async ops

  // await Firebase.initializeApp(); // 🔹 Commented out Firebase init

  //testing git
  runApp(const Launcher());
}

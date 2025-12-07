import 'package:flutter/material.dart';
import 'home_page.dart';
import 'login_page.dart';
// import 'package:firebase_auth/firebase_auth.dart'; // ❌ Commented out for desktop

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    // 🔹 Dummy login check for desktop
    final bool isLoggedIn = false; // Change to true to skip login

    if (isLoggedIn) {
      return const HomePage();
    } else {
      return const LoginPage();
    }
  }
}

// import 'package:flutter/material.dart';
// // import 'package:firebase_auth/firebase_auth.dart'; // ❌ Removed for desktop
// import 'package:iqdapp/inventory_page.dart';
// import 'package:iqdapp/register_page.dart';
// import 'login_page.dart';
// import 'home_page.dart';
// import 'invoice_page.dart';
// import 'quotation_page.dart';
// import 'delivery_page.dart';
// import 'invoice_page.dart';
//
// class Launcher extends StatelessWidget {
//   const Launcher({super.key});
//
//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//       title: 'IQD APP',
//       theme: ThemeData(
//         primarySwatch: Colors.blue,
//         scaffoldBackgroundColor: Colors.grey[100],
//         brightness: Brightness.light,
//       ),
//       debugShowCheckedModeBanner: false,
//       home: const AuthGate(), // ✅ check user state
//       routes: {
//         '/login': (context) => const LoginPage(),
//         '/register': (context) => const RegisterPage(),
//         '/home': (context) => const HomePage(),
//         '/invoice': (context) => const InvoicePage(),
//         '/quotation': (context) => const QuotationPage(),
//         '/delivery': (context) => const DeliveryPage(),
//         '/inventory': (context) => const InventoryPage(),
//       },
//     );
//   }
// }
//
// class AuthGate extends StatelessWidget {
//   const AuthGate({super.key});
//
//   @override
//   Widget build(BuildContext context) {
//     // 🔹 Dummy user login check for desktop
//     final bool isLoggedIn = false; // Change to `true` to skip login
//
//     if (isLoggedIn) {
//       return const HomePage();
//     } else {
//       return const LoginPage();
//     }
//   }
// }
import 'package:flutter/material.dart';
import 'package:iqdapp/inventory_page.dart';
import 'package:iqdapp/register_page.dart';
import 'package:iqdapp/login_page.dart';
import 'package:iqdapp/home_page.dart';
import 'package:iqdapp/invoice_page.dart';
import 'package:iqdapp/quotation_page.dart';
import 'package:iqdapp/delivery_page.dart';
import 'splash_screen.dart'; // ✅ Import splash

class Launcher extends StatelessWidget {
  const Launcher({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'IQD APP',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        scaffoldBackgroundColor: Colors.grey[100],
        brightness: Brightness.light,
      ),
      debugShowCheckedModeBanner: false,

      // ✅ Start with SplashScreen, not AuthGate/Login
      home: const SplashScreen(),

      routes: {
        '/login': (context) => const LoginPage(),
        '/register': (context) => const RegisterPage(),
        '/home': (context) => const HomePage(),
        '/invoice': (context) => const InvoicePage(),
        '/quotation': (context) => const QuotationPage(),
        '/delivery': (context) => const DeliveryPage(),
        '/inventory': (context) => const InventoryPage(),
      },
    );
  }
}

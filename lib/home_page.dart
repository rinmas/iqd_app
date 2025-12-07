import 'package:flutter/material.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  Widget buildTile(BuildContext context, String label, IconData icon, String route, {bool enabled = true}) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () {
        if (enabled) {
          Navigator.pushNamed(context, route);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Feature will be out soon!'),
              duration: Duration(seconds: 2),
            ),
          );
        }
      },
      child: Opacity(
        opacity: enabled ? 1.0 : 0.6,
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.25),
                blurRadius: 6,
                offset: const Offset(2, 3),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 40, color: const Color(0xFF00BCD4)),
              const SizedBox(height: 12),
              Text(
                label,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE0F7FA),
      appBar: AppBar(
        title: const Text('IQD APP'),
        automaticallyImplyLeading: false, // ✅ Hides hamburger icon
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: GridView.count(
          crossAxisCount: MediaQuery.of(context).size.width > 800 ? 2 : 1,
          crossAxisSpacing: 20,
          mainAxisSpacing: 20,
          childAspectRatio: 3.0,
          children: [
            buildTile(context, 'Invoice', Icons.receipt_long, '/invoice', enabled: true),
            buildTile(context, 'Quotation', Icons.request_quote, '/quotation', enabled: false),
            buildTile(context, 'Delivery Note', Icons.local_shipping, '/delivery', enabled: false),
            buildTile(context, 'Store', Icons.store, '/inventory', enabled: false),
          ],
        ),
      ),
    );
  }
}

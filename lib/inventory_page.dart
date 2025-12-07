import 'package:flutter/material.dart';
// import 'package:firebase_database/firebase_database.dart'; // ❌ Commented out for desktop

class InventoryPage extends StatelessWidget {
  const InventoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    // ✅ Dummy local inventory (instead of Firebase)
    final List<Map<String, dynamic>> items = [
      {
        "item": "Laptop",
        "description": "Dell XPS 13",
        "quantity": 5,
        "Unit of Measure": "pcs",
      },
      {
        "item": "Monitor",
        "description": "Samsung 27-inch",
        "quantity": 8,
        "Unit of Measure": "pcs",
      },
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('Inventory')),
      body: ListView.builder(
        itemCount: items.length,
        itemBuilder: (context, index) {
          final item = items[index];
          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            child: ListTile(
              title: Text(item['item'] ?? 'No Name'),
              subtitle: Text(item['description'] ?? 'No Description'),
              trailing: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text("Qty: ${item['quantity'] ?? '0'}"),
                  Text(item['Unit of Measure'] ?? ''),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

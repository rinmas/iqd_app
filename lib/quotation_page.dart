import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
// import 'package:firebase_database/firebase_database.dart'; // ❌ Removed for desktop
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'dart:io';

class QuotationPage extends StatefulWidget {
  const QuotationPage({super.key});

  @override
  _QuotationPageState createState() => _QuotationPageState();
}

class _QuotationPageState extends State<QuotationPage>
    with SingleTickerProviderStateMixin {
  List<QuotationItem> items = [];

  // Instead of Firebase, store locally
  List<Map<String, dynamic>> localQuotations = [];

  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  void addItem() {
    setState(() {
      items.add(QuotationItem(description: '', quantity: 1, unitPrice: 0));
    });
  }

  void removeItem(int index) {
    setState(() {
      items.removeAt(index);
    });
  }

  double get total {
    return items.fold(0, (sum, item) => sum + item.total);
  }

  void saveQuotationLocally() {
    final now = DateTime.now();
    final dateString = DateFormat('yyyy-MM-dd').format(now);

    final newQuotation = {
      'date': dateString,
      'timestamp': now.millisecondsSinceEpoch,
      'items': items
          .map((item) => {
        'description': item.description,
        'quantity': item.quantity,
        'unitPrice': item.unitPrice,
      })
          .toList(),
    };

    setState(() {
      localQuotations.add(newQuotation);
      items.clear();
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Quotation saved locally')),
    );
  }

  Widget buildCreateQuotationTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          const Text('Quotation Items',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: items.length,
            itemBuilder: (context, index) {
              return Card(
                margin: const EdgeInsets.symmetric(vertical: 8),
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Row(
                    children: [
                      Container(
                        width: 30,
                        alignment: Alignment.center,
                        child: Text(
                          '${index + 1}',
                          style: const TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        flex: 3,
                        child: TextField(
                          decoration:
                          const InputDecoration(labelText: 'Description'),
                          onChanged: (value) {
                            items[index].description = value;
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        flex: 1,
                        child: TextField(
                          keyboardType: TextInputType.number,
                          decoration:
                          const InputDecoration(labelText: 'Qty'),
                          onChanged: (value) {
                            items[index].quantity = int.tryParse(value) ?? 1;
                            setState(() {});
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        flex: 2,
                        child: TextField(
                          keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                          decoration:
                          const InputDecoration(labelText: 'Unit Price'),
                          onChanged: (value) {
                            items[index].unitPrice =
                                double.tryParse(value) ?? 0;
                            setState(() {});
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        flex: 2,
                        child: Text(
                          '\KD${items[index].total.toStringAsFixed(2)}',
                          style: const TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => removeItem(index),
                      )
                    ],
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            icon: const Icon(Icons.add),
            label: const Text('Add Item'),
            onPressed: addItem,
          ),
          const SizedBox(height: 24),
          Text(
            'Grand Total: \KD${total.toStringAsFixed(2)}',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: saveQuotationLocally,
            child: const Text('Save Quotation'),
          ),
        ],
      ),
    );
  }

  Widget buildViewQuotationTab() {
    if (localQuotations.isEmpty) {
      return const Center(child: Text("No quotations found."));
    }

    final quotations = List<Map<String, dynamic>>.from(localQuotations);
    quotations.sort((a, b) => b['timestamp'].compareTo(a['timestamp']));

    return ListView.builder(
      itemCount: quotations.length,
      itemBuilder: (context, index) {
        final q = quotations[index];
        final date = DateTime.fromMillisecondsSinceEpoch(q['timestamp']);
        final remainingDays = 5 - DateTime.now().difference(date).inDays;

        return ListTile(
          title: Text("Quotation #${index + 1}"),
          subtitle: Text("Date: ${q['date']}"),
          trailing: Text(
            remainingDays > 0 ? "$remainingDays days left" : "Expired",
            style: TextStyle(
                color: remainingDays > 0 ? Colors.green : Colors.red),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Quotation'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Create'),
            Tab(text: 'View'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          buildCreateQuotationTab(),
          buildViewQuotationTab(),
        ],
      ),
    );
  }
}

class QuotationItem {
  String description;
  int quantity;
  double unitPrice;

  QuotationItem({
    required this.description,
    required this.quantity,
    required this.unitPrice,
  });

  double get total => quantity * unitPrice;
}

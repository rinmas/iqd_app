import 'package:flutter/material.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'dart:io';

class DeliveryPage extends StatefulWidget {
  const DeliveryPage({super.key});

  @override
  _DeliveryPageState createState() => _DeliveryPageState();
}

class _DeliveryPageState extends State<DeliveryPage> {
  List<DeliveryItem> items = [];

  void addItem() {
    setState(() {
      items.add(DeliveryItem(
        description: '',
        quantity: 1,
        //unitPrice: 0,
      ));
    });
  }

  void removeItem(int index) {
    setState(() {
      items.removeAt(index);
      // No need to renumber, index determines item no.
    });
  }

  /*double get total {
    return items.fold(0, (sum, item) => sum + item.total);
  }*/

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Create Delivery')),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            Text(
              'Delivery Items',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            ListView.builder(
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              itemCount: items.length,
              itemBuilder: (context, index) {
                return Card(
                  margin: EdgeInsets.symmetric(vertical: 8),
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Row(
                      children: [
                        // Item Number (index + 1)
                        Container(
                          width: 30,
                          alignment: Alignment.center,
                          child: Text(
                            '${index + 1}',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        SizedBox(width: 8),
                        Expanded(
                          flex: 3,
                          child: TextField(
                            decoration: InputDecoration(
                              labelText: 'Description',
                            ),
                            onChanged: (value) {
                              items[index].description = value;
                            },
                          ),
                        ),
                        SizedBox(width: 8),
                        Expanded(
                          flex: 1,
                          child: TextField(
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(labelText: 'Qty'),
                            onChanged: (value) {
                              items[index].quantity =
                                  int.tryParse(value) ?? 1;
                              setState(() {});
                            },
                          ),
                        ),
                        SizedBox(width: 8),
                        /* Expanded(
                          flex: 2,
                          child: TextField(
                            keyboardType:
                            TextInputType.numberWithOptions(decimal: true),
                            decoration:
                            InputDecoration(labelText: 'Unit Price'),
                            onChanged: (value) {
                              items[index].unitPrice =
                                  double.tryParse(value) ?? 0;
                              setState(() {});
                            },
                          ),
                        ),*/
                        SizedBox(width: 8),
                        /*Expanded(
                          flex: 2,
                          child: Text(
                            '\KD${items[index].total.toStringAsFixed(2)}',
                            style: TextStyle(
                                fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                        ),*/
                        IconButton(
                          icon: Icon(Icons.delete, color: Colors.red),
                          onPressed: () => removeItem(index),
                        )
                      ],
                    ),
                  ),
                );
              },
            ),
            SizedBox(height: 16),
            ElevatedButton.icon(
              icon: Icon(Icons.add),
              label: Text('Add Item'),
              onPressed: addItem,
            ),
            SizedBox(height: 24),
            /*Text(
              'Grand Total: \KD${total.toStringAsFixed(2)}',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),*/
            SizedBox(height: 16),
            ElevatedButton(
              child: Text('Generate Delivery PDF'),
              onPressed: () {
                Future<void> generatePdf() async {
                  final pdf = pw.Document();

                  pdf.addPage(
                    pw.Page(
                      build: (pw.Context context) {
                        return pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Text('Delivery', style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
                            pw.SizedBox(height: 20),
                            pw.Table.fromTextArray(
                              border: pw.TableBorder.all(),
                              headers: [
                                'Item No',
                                'Description',
                                'Qty',
                                'Unit Price (KD)',
                                'Total (KD)'
                              ],
                              data: items
                                  .asMap()
                                  .entries
                                  .map((entry) {
                                final index = entry.key;
                                final item = entry.value;
                                return [
                                  '${index + 1}',
                                  item.description,
                                  '${item.quantity}',
                                  //item.unitPrice.toStringAsFixed(2),
                                  //item.total.toStringAsFixed(2),
                                ];
                              })
                                  .toList(),
                            ),
                            pw.SizedBox(height: 20),
                            /*pw.Text(
                              'Grand Total: KD ${total.toStringAsFixed(2)}',
                              style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
                            )*/
                          ],
                        );
                      },
                    ),
                  );

                  // Save PDF to file
                  final output = await getTemporaryDirectory();
                  final file = File('${output.path}/Quotation.pdf');
                  await file.writeAsBytes(await pdf.save());

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('PDF saved at: ${file.path}')),
                  );

                  // Optional: open or share the PDF here
                }

              },
            )
          ],
        ),
      ),
    );
  }
}

class DeliveryItem {
  String description;
  int quantity;
  //double unitPrice;

  DeliveryItem({
    required this.description,
    required this.quantity,
    //required this.unitPrice,
  });

//double get total => quantity * unitPrice;
}

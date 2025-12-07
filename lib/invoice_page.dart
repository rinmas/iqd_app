import 'package:flutter/material.dart';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:printing/printing.dart';
import 'package:file_picker/file_picker.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_animate/flutter_animate.dart';

// ================== INVOICE PAGE ==================
class InvoicePage extends StatefulWidget {
  const InvoicePage({super.key});

  @override
  _InvoicePageState createState() => _InvoicePageState();
}

class _InvoicePageState extends State<InvoicePage> {
  final _formKey = GlobalKey<FormState>();
  List<InvoiceItem> items = [];

  // kept companyName variable (not displayed anymore)
  String companyName = "Al Watan";
  String customerName = "";
  String date = "";
  String contractNo = "";
  String contractDate = "";
  String refNo = "";
  String refDate = "";
  String notes = ""; // Added notes

  // Invoice type: "cash" or "credit" (default cash)
  String _invType = "cash";

  bool _isGenerating = false; // <-- prevent double submits & disable button

  // Quantity pattern: whole number optionally followed by a single word unit (e.g. "5" or "5 kg")
  final RegExp _qtyPattern = RegExp(r'^[0-9]+(?: [a-zA-Z]+)?$');

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    date =
    "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";
  }

  void addItem() {
    for (var item in items) {
      if (item.description.isEmpty ||
          item.quantity < 1 ||
          item.unitPrice <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Please fill all existing item details correctly')),
        );
        return;
      }
    }
    setState(() {
      items.add(InvoiceItem(
          description: '', quantity: 1, unitPrice: 0, quantityString: '1'));
    });
  }

  void removeItem(int index) {
    setState(() {
      items.removeAt(index);
    });
  }

  double get total => items.fold(0, (sum, item) => sum + item.total);

  Future<void> pickDate(BuildContext context, Function(String) onPicked) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      onPicked(
          "${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}");
    }
  }

  /// Sends invoice payload and expects response:
  /// { "file": "invoice.pdf", "pdf_base64": "<base64 string>" }
  Future<Map<String, String>> sendInvoiceToApiAndReturnDetails() async {
    final url =
    //Uri.parse('https://cd9a4f27769d.ngrok-free.app/api/generate-invoice');
    Uri.parse('http://127.0.0.1:8000/api/generate-invoice');

    final apiItems = items.map((item) {
      final kd = item.unitPrice.floor();
      final fils = ((item.unitPrice - kd) * 1000).round();
      return {
        "description": item.description,
        "qty": item.quantity, // numeric part extracted from quantityString
        "unit_kd": kd,
        "unit_fils": fils,
      };
    }).toList();

    // Updated payload to include inv_type and preserve newlines in notes
    final invoiceData = {
      "bill_to_name": customerName,
      "inv_type": _invType.toLowerCase(),
      "inv_date": date,
      "contract_no": contractNo,
      "contract_date": contractDate,
      "our_ref": refNo,
      "ref_date": refDate,
      "notes": notes, // keep newline characters as entered
      "items": apiItems,
    };

    //"inv_number": DateTime.now().millisecondsSinceEpoch.toString(),

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(invoiceData),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        // Expect pdf_base64 in response
        final pdfFileName = data['file'] ?? 'invoice.pdf';
        final pdfBase64 = data['pdf_base64'] as String?;

        if (pdfBase64 == null || pdfBase64.isEmpty) {
          throw Exception('API did not return pdf_base64');
        }

        return {"file": pdfFileName, "pdf_base64": pdfBase64};
      } else {
        throw Exception("API Failed (${response.statusCode}): ${response.body}");
      }
    } catch (e) {
      throw Exception("Error sending to API: $e");
    }
  }

  // NEW: performs validation, shows loading dialog, calls API, navigates on success
  Future<void> generatePdf() async {
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all required fields')),
      );
      return;
    }

    for (var item in items) {
      if (item.description.isEmpty ||
          item.quantity < 1 ||
          item.unitPrice <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text(
                  'Please complete all invoice items correctly before proceeding')),
        );
        return;
      }
    }

    if (notes.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Notes cannot be empty')),
      );
      return;
    }

    // show non-dismissible loading dialog and call API
    setState(() {
      _isGenerating = true;
    });

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

    try {
      final fileDetails = await sendInvoiceToApiAndReturnDetails();

      // close loading dialog
      if (mounted) Navigator.of(context).pop();

      setState(() {
        _isGenerating = false;
      });

      // navigate to PDF viewer using base64
      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => PdfViewerPage(
            pdfBase64: fileDetails['pdf_base64']!,
            pdfFileName: fileDetails['file']!,
          ),
        ),
      );
    } catch (e) {
      // close loading dialog if open
      if (mounted) {
        Navigator.of(context).pop();
      }

      setState(() {
        _isGenerating = false;
      });

      // show error but stay on invoice screen with data intact
      final msg = e.toString();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to generate PDF: $msg'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  String? dateValidator(String? v) {
    if (v == null || v.isEmpty) return 'Required';
    final regex = RegExp(r'^\d{4}-\d{2}-\d{2}$');
    if (!regex.hasMatch(v)) return 'Invalid date format';
    return null;
  }

  // Option B qty validator: whole number required, optional single word unit after a space
  String? qtyValidator(String? v) {
    if (v == null || v.isEmpty) return 'Required';
    if (!_qtyPattern.hasMatch(v.trim())) {
      return 'Please enter proper quantity (e.g. 5 or 5 pcs)';
    }
    // numeric part should be >= 1
    final match = RegExp(r'^([0-9]+)').firstMatch(v.trim());
    if (match == null) return 'Please enter proper quantity';
    final n = int.tryParse(match.group(1)!);
    if (n == null || n < 1) return 'Quantity must be ≥ 1';
    return null;
  }

  String? priceValidator(String? v) {
    if (v == null || v.isEmpty) return 'Required';
    final n = double.tryParse(v);
    if (n == null || n <= 0) return 'Price must be > 0';
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create Invoice')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Replaced company name with Invoice Type radio buttons (side-by-side)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Invoice Type",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Row(
                        children: [
                          Radio<String>(
                            value: "cash",
                            groupValue: _invType,
                            onChanged: (value) {
                              setState(() {
                                _invType = value!;
                              });
                            },
                          ),
                          const SizedBox(width: 4),
                          const Text("Cash",
                              style: TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.w500)),
                        ],
                      ),
                      const SizedBox(width: 24),
                      Row(
                        children: [
                          Radio<String>(
                            value: "credit",
                            groupValue: _invType,
                            onChanged: (value) {
                              setState(() {
                                _invType = value!;
                              });
                            },
                          ),
                          const SizedBox(width: 4),
                          const Text("Credit",
                              style: TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.w500)),
                        ],
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: TextFormField(
                      decoration:
                      const InputDecoration(labelText: 'Customer Name'),
                      onChanged: (v) => customerName = v,
                      validator: (v) =>
                      v == null || v.isEmpty ? 'Required' : null,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 1,
                    child: GestureDetector(
                      onTap: () =>
                          pickDate(context, (val) => setState(() => date = val)),
                      child: AbsorbPointer(
                        child: TextFormField(
                          decoration: const InputDecoration(labelText: 'Date'),
                          controller: TextEditingController(text: date),
                          validator: dateValidator,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Contract No + Dated
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: TextFormField(
                      decoration:
                      const InputDecoration(labelText: 'Contract No'),
                      onChanged: (v) => contractNo = v,
                      validator: (v) =>
                      v == null || v.isEmpty ? 'Required' : null,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 1,
                    child: GestureDetector(
                      onTap: () => pickDate(
                          context, (val) => setState(() => contractDate = val)),
                      child: AbsorbPointer(
                        child: TextFormField(
                          decoration:
                          const InputDecoration(labelText: 'Contract Dated'),
                          controller: TextEditingController(text: contractDate),
                          validator: dateValidator,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Ref No + Dated
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: TextFormField(
                      decoration:
                      const InputDecoration(labelText: 'Our Ref. No'),
                      onChanged: (v) => refNo = v,
                      validator: (v) =>
                      v == null || v.isEmpty ? 'Required' : null,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 1,
                    child: GestureDetector(
                      onTap: () =>
                          pickDate(context, (val) => setState(() => refDate = val)),
                      child: AbsorbPointer(
                        child: TextFormField(
                          decoration:
                          const InputDecoration(labelText: 'Ref. Dated'),
                          controller: TextEditingController(text: refDate),
                          validator: dateValidator,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              const Text('Invoice Items',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: items.length,
                itemBuilder: (context, index) => Card(
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Row(
                      children: [
                        Container(
                            width: 30,
                            alignment: Alignment.center,
                            child: Text('${index + 1}',
                                style: const TextStyle(
                                    fontSize: 16, fontWeight: FontWeight.bold))),
                        const SizedBox(width: 8),
                        Expanded(
                          flex: 3,
                          child: TextFormField(
                            decoration:
                            const InputDecoration(labelText: 'Description'),
                            onChanged: (v) => items[index].description = v,
                            validator: (v) =>
                            v == null || v.isEmpty ? 'Required' : null,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          flex: 1,
                          child: TextFormField(
                            decoration: const InputDecoration(labelText: 'Qty'),
                            onChanged: (v) {
                              items[index].quantityString = v;
                              final trimmed = v.trim();
                              if (_qtyPattern.hasMatch(trimmed)) {
                                // extract numeric part only when input fully matches pattern
                                final match = RegExp(r'^([0-9]+)').firstMatch(trimmed);
                                items[index].quantity =
                                match != null ? int.parse(match.group(1)!) : 0;
                              } else {
                                // invalid input -> set numeric part to 0 so validations catch it
                                items[index].quantity = 0;
                              }
                              setState(() {});
                            },
                            validator: qtyValidator,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          flex: 2,
                          child: TextFormField(
                            keyboardType: const TextInputType.numberWithOptions(
                                decimal: true),
                            decoration:
                            const InputDecoration(labelText: 'Unit Price (KD)'),
                            onChanged: (v) {
                              items[index].unitPrice = double.tryParse(v) ?? 0;
                              setState(() {});
                            },
                            validator: priceValidator,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          flex: 2,
                          child: Text(
                              'KD ${items[index].total.toStringAsFixed(3)}',
                              style: const TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.bold)),
                        ),
                        IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () => removeItem(index)),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                  icon: const Icon(Icons.add),
                  label: const Text('Add Item'),
                  onPressed: addItem),
              const SizedBox(height: 16),
              TextFormField(
                maxLines: 5,
                minLines: 1,
                decoration: const InputDecoration(
                  labelText: 'Notes',
                  hintText: 'Enter any notes...',
                  border: OutlineInputBorder(),
                ),
                onChanged: (v) => notes = v,
                validator: (v) =>
                v == null || v.trim().isEmpty ? 'Notes cannot be empty' : null,
              ),
              const SizedBox(height: 16),
              Text('Grand Total: KD ${total.toStringAsFixed(3)}',
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              ElevatedButton(
                child: const Text('Generate Invoice PDF'),
                onPressed: _isGenerating ? null : generatePdf,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ================== INVOICE ITEM ==================
class InvoiceItem {
  String description;
  int quantity; // numeric part for calculation
  String quantityString; // full string like "1 kg"
  double unitPrice;

  InvoiceItem({
    required this.description,
    required this.quantity,
    required this.unitPrice,
    this.quantityString = '',
  });

  double get total => quantity * unitPrice;
}

// ================== PDF VIEWER PAGE ==================
class PdfViewerPage extends StatefulWidget {
  final String pdfBase64;
  final String pdfFileName;

  const PdfViewerPage({
    super.key,
    required this.pdfBase64,
    required this.pdfFileName,
  });

  @override
  State<PdfViewerPage> createState() => _PdfViewerPageState();
}

class _PdfViewerPageState extends State<PdfViewerPage> {
  File? _file;
  Uint8List? _bytes;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _prepareFile();
  }

  Future<void> _prepareFile() async {
    try {
      final bytes = base64Decode(widget.pdfBase64);
      _bytes = bytes;
      final tempDir = await getTemporaryDirectory();
      final filePath = '${tempDir.path}/${widget.pdfFileName}';
      final f = File(filePath);
      await f.writeAsBytes(bytes, flush: true);
      if (mounted) {
        setState(() {
          _file = f;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to prepare PDF: $e')),
        );
      }
    }
  }

  Future<void> _downloadToFolder() async {
    if (_bytes == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('PDF not ready yet')),
      );
      return;
    }

    setState(() => _saving = true);
    try {
      // ask user for directory
      String? directoryPath = await FilePicker.platform.getDirectoryPath();
      if (directoryPath == null) {
        // user cancelled
        setState(() => _saving = false);
        return;
      }

      final savePath = "$directoryPath/${widget.pdfFileName}";
      final file = File(savePath);
      await file.writeAsBytes(_bytes!, flush: true);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("✅ PDF saved to:\n$savePath")),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("❌ Failed to save PDF: $e")),
      );
    } finally {
      setState(() => _saving = false);
    }
  }

  Future<void> _printPDF() async {
    if (_bytes == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('PDF not ready yet')),
      );
      return;
    }
    try {
      await Printing.layoutPdf(onLayout: (format) async => _bytes!);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("❌ Failed to print PDF: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.pdfFileName),
        actions: [
          IconButton(
            icon: const Icon(Icons.download),
            tooltip: "Save PDF",
            onPressed: _saving ? null : _downloadToFolder,
          ),
          IconButton(
            icon: const Icon(Icons.print),
            tooltip: "Print PDF",
            onPressed: _printPDF,
          ),
        ],
      ),
      body: Center(
        child: _file == null
            ? const CircularProgressIndicator()
            : SfPdfViewer.file(
          _file!,
          canShowScrollHead: true,
          canShowScrollStatus: true,
        ),
      ),
    );
  }
}

// ================== PROCESSING SCREEN ==================
class ProcessingScreen extends StatefulWidget {
  final Future<Map<String, String>> Function() getFileDetails;
  const ProcessingScreen({super.key, required this.getFileDetails});

  @override
  _ProcessingScreenState createState() => _ProcessingScreenState();
}

class _ProcessingScreenState extends State<ProcessingScreen> {
  bool _isError = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _startApiCall();
  }

  Future<void> _startApiCall() async {
    try {
      final fileDetails = await widget.getFileDetails();
      if (!mounted) return;

      // If the API returns pdf_base64, open the PdfViewerPage accordingly
      if (fileDetails.containsKey('pdf_base64')) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => PdfViewerPage(
              pdfBase64: fileDetails['pdf_base64']!,
              pdfFileName: fileDetails['file']!,
            ),
          ),
        );
        return;
      }

      // Fallback: if it returns a URL (older behavior), open network viewer
      if (fileDetails.containsKey('url')) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => PdfViewerNetworkPage(
              pdfUrl: fileDetails['url']!,
              pdfFileName: fileDetails['file']!,
            ),
          ),
        );
        return;
      }

      throw Exception('API returned neither pdf_base64 nor url');
    } catch (e) {
      setState(() {
        _isError = true;
        _errorMessage = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black45,
      body: Center(
        child: _isError
            ? Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error, color: Colors.red, size: 60),
            const SizedBox(height: 12),
            Text(
              _errorMessage ?? 'Something went wrong',
              style: const TextStyle(color: Colors.white, fontSize: 16),
              textAlign: TextAlign.center,
            ),
          ],
        )
            : Image.asset(
          'assets/iqd_logo.jpg',
          width: 120,
          height: 120,
        )
            .animate(onPlay: (c) => c.repeat(reverse: true))
            .scale(begin: const Offset(1, 1), end: const Offset(1.2, 1.2))
            .move(begin: const Offset(0, 0), end: const Offset(0, -15)),
      ),
    );
  }
}

/// A small helper network-viewer in-case some responses still return a URL.
/// (You may remove this if you never use network URLs.)
class PdfViewerNetworkPage extends StatelessWidget {
  final String pdfUrl;
  final String pdfFileName;
  const PdfViewerNetworkPage(
      {super.key, required this.pdfUrl, required this.pdfFileName});

  Future<void> _downloadPDF(BuildContext context) async {
    try {
      if (Platform.isAndroid) {
        await Permission.storage.request();
      }

      final response = await Dio().get(pdfUrl,
          options: Options(responseType: ResponseType.bytes));

      String? directoryPath = await FilePicker.platform.getDirectoryPath();
      if (directoryPath == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("❌ No folder selected")),
        );
        return;
      }

      final filePath = "$directoryPath/$pdfFileName";
      final file = File(filePath);
      await file.writeAsBytes(response.data);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("✅ PDF saved to:\n$filePath")),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("❌ Failed to save PDF: $e")),
      );
    }
  }

  Future<void> _printPDF(BuildContext context) async {
    try {
      await Printing.layoutPdf(
        onLayout: (format) async {
          final response = await Dio().get(
            pdfUrl,
            options: Options(responseType: ResponseType.bytes),
          );
          return response.data;
        },
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("❌ Failed to print PDF: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(pdfFileName),
        actions: [
          IconButton(
              icon: const Icon(Icons.download),
              tooltip: "Download PDF",
              onPressed: () => _downloadPDF(context)),
          IconButton(
              icon: const Icon(Icons.print),
              tooltip: "Print PDF",
              onPressed: () => _printPDF(context)),
        ],
      ),
      body: SfPdfViewer.network(
        pdfUrl,
        canShowScrollHead: true,
        canShowScrollStatus: true,
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../services/receipt_service.dart';
import '../models/bill_item.dart';
import 'receipt_details_screen.dart';

class UploadReceiptScreen extends StatefulWidget {
  const UploadReceiptScreen({super.key});

  @override
  State<UploadReceiptScreen> createState() => _UploadReceiptScreenState();
}

class _UploadReceiptScreenState extends State<UploadReceiptScreen> {
  String? _fileName;
  dynamic _file;
  bool _isProcessing = false;
  final _receiptService = ReceiptService();

  Future<void> _pickFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: false,
        withData: kIsWeb,
      );

      if (result != null) {
        setState(() {
          _fileName = result.files.first.name;
          if (kIsWeb) {
            _file = result.files.first.bytes;
          } else {
            _file = File(result.files.first.path!);
          }
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Recibo seleccionado exitosamente')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al seleccionar el archivo: $e')),
        );
      }
    }
  }

  Future<void> _processReceipt() async {
    if (_file == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor selecciona un recibo primero')),
      );
      return;
    }

    setState(() {
      _isProcessing = true;
    });

    try {
      final response = await _receiptService.processReceipt(
        _file, 
        filename: _fileName,
        currency: 'COP',
      );

      if (mounted) {
        setState(() {
          _isProcessing = false;
        });

        // Generar IDs únicos para cada item si no vienen del backend
        final items = (response['ocr_contents']['items'] as List)
            .asMap()
            .entries
            .map((entry) {
              final index = entry.key;
              final itemData = entry.value as Map<String, dynamic>;
              // Si no tiene ID, generar uno único basado en el índice y timestamp
              if (!itemData.containsKey('id')) {
                itemData['id'] = 'item_${DateTime.now().millisecondsSinceEpoch}_$index';
              }
              return BillItem.fromJson(itemData);
            })
            .toList();

        // Navegar a la pantalla de detalles con los datos del recibo
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => ReceiptDetailsScreen(
              items: items,
              totalBill: response['ocr_contents']['total_order_bill_details']
                  ['total_bill'],
              taxes: response['ocr_contents']['total_order_bill_details']
                  ['taxes'],
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al procesar el recibo: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F7FF),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Upload Receipt',
          style: TextStyle(
            color: Colors.black,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Scan or Upload',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1E2B45),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Upload your receipt to automatically split the bill among friends.',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[600],
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Upload Zone
                  DragTarget<String>(
                    onAccept: (data) async {
                      await _pickFile();
                    },
                    builder: (context, candidateData, rejectedData) {
                      return GestureDetector(
                        onTap: _pickFile,
                        child: Container(
                          width: double.infinity,
                          height: 240,
                          decoration: BoxDecoration(
                            color: _fileName == null
                                ? Colors.white
                                : Colors.blue[50],
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(
                              color: _fileName == null
                                  ? Colors.grey[300]!
                                  : Colors.blue[200]!,
                              width: 2,
                              style: BorderStyle.solid, 
                              // Note: Dashed border requires a package or custom painter, 
                              // keeping solid for simplicity but styling it nicely.
                            ),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: _fileName == null
                                      ? Colors.grey[100]
                                      : Colors.blue[100],
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  _fileName == null
                                      ? Icons.cloud_upload_outlined
                                      : Icons.check_circle_outline,
                                  size: 40,
                                  color: _fileName == null
                                      ? Colors.grey[600]
                                      : Colors.blue[700],
                                ),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                _fileName == null
                                    ? 'Tap to select receipt'
                                    : 'Receipt Selected',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                  color: _fileName == null
                                      ? Colors.grey[800]
                                      : Colors.blue[900],
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                _fileName == null
                                    ? 'or drag and drop here'
                                    : 'Tap to change file',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: _fileName == null
                                      ? Colors.grey[500]
                                      : Colors.blue[700],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),

                  if (_fileName != null) ...[
                    const SizedBox(height: 24),
                    const Text(
                      'Selected File',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1E2B45),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.blue[50],
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              Icons.description_outlined,
                              color: Colors.blue[700],
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _fileName!,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 15,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Ready to process',
                                  style: TextStyle(
                                    color: Colors.green[600],
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close, color: Colors.grey),
                            onPressed: () {
                              setState(() {
                                _fileName = null;
                                _file = null;
                              });
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          
          // Fixed Bottom Action Button
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 20,
                  offset: const Offset(0, -10),
                ),
              ],
            ),
            child: Column(
              children: [
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _fileName == null || _isProcessing
                        ? null
                        : _processReceipt,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1E2B45),
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: Colors.grey[200],
                      disabledForegroundColor: Colors.grey[400],
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 0,
                    ),
                    child: _isProcessing
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Text(
                            'Process Receipt',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: TextButton(
                    onPressed: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const ReceiptDetailsScreen(
                            items: [],
                            totalBill: 0,
                            taxes: [],
                          ),
                        ),
                      );
                    },
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: const Text(
                      'O crea un split manual',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1E2B45),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

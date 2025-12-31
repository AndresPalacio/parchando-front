import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../styles.dart';
import '../models/bill_item.dart';
import '../models/saved_bill.dart';
import '../models/item_participant.dart';
import '../services/bill_storage_service.dart';

class BillEditScreen extends StatefulWidget {
  final List<BillItem> items;
  final double totalBill;
  final List<dynamic> taxes;
  final String receiptName;
  final String? billId; // ID del bill si se está editando uno existente
  final String? patchId; // PatchId para verificar permisos

  const BillEditScreen({
    Key? key,
    required this.items,
    required this.totalBill,
    required this.taxes,
    required this.receiptName,
    this.billId,
    this.patchId,
  }) : super(key: key);

  @override
  State<BillEditScreen> createState() => _BillEditScreenState();
}

class _BillEditScreenState extends State<BillEditScreen> {
  late List<BillItem> _items;
  late List<dynamic> _taxes;
  late double _totalBill;
  late BillStorageService _billStorage;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _items = List.from(widget.items);
    _taxes = List.from(widget.taxes);
    _billStorage = BillStorageService();
    _calculateTotal();
  }


  void _calculateTotal() {
    double subtotal =
        _items.fold(0, (sum, item) => sum + (item.price * item.quantity));
    double totalTaxes = _taxes.fold(0, (sum, tax) => sum + tax['amount']);
    setState(() {
      _totalBill = subtotal + totalTaxes;
    });
  }

  void _addNewItem() {
    setState(() {
      _items.add(BillItem(
        id: 'item_${DateTime.now().millisecondsSinceEpoch}_${_items.length}',
        name: 'Nuevo Item',
        price: 0.0,
        quantity: 1,
      ));
    });
    _calculateTotal();
  }

  void _removeItem(int index) {
    setState(() {
      _items.removeAt(index);
    });
    _calculateTotal();
  }

  void _addNewTax() {
    setState(() {
      _taxes.add({
        'name': 'Nuevo Impuesto',
        'amount': 0.0,
      });
    });
    _calculateTotal();
  }

  void _removeTax(int index) {
    setState(() {
      _taxes.removeAt(index);
    });
    _calculateTotal();
  }

  Future<void> _saveChanges() async {
    setState(() {
      _isSaving = true;
    });

    try {
      if (widget.billId != null) {
        // Si hay billId, actualizar bill existente
        final updatedBill = SavedBill(
          id: widget.billId!,
          patchId: widget.patchId,
          name: widget.receiptName,
          date: DateTime.now(),
          total: _totalBill,
          items: _items,
          taxes: _taxes,
        );

        await _billStorage.updateBill(updatedBill);
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Bill actualizado exitosamente')),
          );
          Navigator.pop(context, {
            'items': _items,
            'totalBill': _totalBill,
            'taxes': _taxes,
            'billId': widget.billId,
          });
        }
      } else if (widget.patchId != null) {
        // Si no hay billId pero hay patchId, crear nuevo bill
        final newBill = SavedBill(
          id: '', // El backend generará el ID
          patchId: widget.patchId!,
          name: widget.receiptName,
          date: DateTime.now(),
          total: _totalBill,
          items: _items,
          taxes: _taxes,
        );

        print('📝 Creando bill con parcheId: ${widget.patchId}...');
        final billId = await _billStorage.saveBill(newBill, isNewBill: true);
        print('✅ Bill creado con ID: $billId');
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Bill guardado exitosamente')),
          );
          Navigator.pop(context, {
            'items': _items,
            'totalBill': _totalBill,
            'taxes': _taxes,
            'billId': billId, // Devolver el billId creado
          });
        }
      } else {
        // Sin billId ni patchId, solo retornar los cambios
        if (mounted) {
          Navigator.pop(context, {
            'items': _items,
            'totalBill': _totalBill,
            'taxes': _taxes,
          });
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al guardar: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Editar Recibo'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(widget.receiptName, style: AppTextStyles.headerTitle),
                    Text(' • ',
                        style: TextStyle(color: AppColors.textSecondary)),
                    Text('08:36 AM', style: AppTextStyles.headerDate),
                  ],
                ),
                const SizedBox(height: 4),
                Text('Sept 4, 2024', style: AppTextStyles.headerDate),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                // Sección de Items
                const Text('Items',
                    style:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                ...List.generate(_items.length, (index) {
                  final item = _items[index];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.delete_outline),
                          onPressed: () => _removeItem(index),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                        const SizedBox(width: 8),
                        SizedBox(
                          width: 24,
                          child: Text('1×', style: AppTextStyles.itemQuantity),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextFormField(
                            initialValue: item.name,
                            decoration: const InputDecoration(
                              hintText: 'Nombre del Item',
                              hintStyle: TextStyle(color: AppColors.textHint),
                            ),
                            style: AppTextStyles.itemName,
                            onChanged: (value) {
                              setState(() {
                                _items[index] = BillItem(
                                  id: item.id,
                                  name: value,
                                  price: item.price,
                                  quantity: item.quantity,
                                  participants: item.participants,
                                );
                              });
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          width: 110,
                          child: Row(
                            children: [
                              Text('\$', style: AppTextStyles.itemPrice),
                              const SizedBox(width: 4),
                              Expanded(
                                child: TextFormField(
                                  initialValue: NumberFormat.currency(
                                    locale: 'es_CO',
                                    symbol: '',
                                    decimalDigits: 0,
                                  ).format(item.price).trim(),
                                  keyboardType:
                                      const TextInputType.numberWithOptions(
                                          decimal: false),
                                  textAlign: TextAlign.right,
                                  style: AppTextStyles.itemPrice,
                                  inputFormatters: [
                                    FilteringTextInputFormatter.digitsOnly,
                                    CurrencyInputFormatter(),
                                  ],
                                  decoration: const InputDecoration(
                                    hintText: '0',
                                    hintStyle:
                                        TextStyle(color: AppColors.textHint),
                                  ),
                                  onChanged: (value) {
                                    final cleanValue =
                                        value.replaceAll(RegExp(r'[^\d]'), '');
                                    final newPrice = double.tryParse(cleanValue) ?? 0;
                                    
                                    // Recalcular shares si hay participantes
                                    List<ItemParticipant> updatedParticipants = item.participants;
                                    if (item.participants.isNotEmpty) {
                                      final share = newPrice / item.participants.length;
                                      updatedParticipants = item.participants.map((p) => ItemParticipant(
                                        userId: p.userId,
                                        share: share,
                                        shareType: p.shareType,
                                        paid: p.paid,
                                        paidAmount: p.paidAmount,
                                      )).toList();
                                    }
                                    
                                    setState(() {
                                      _items[index] = BillItem(
                                        id: item.id,
                                        name: item.name,
                                        price: newPrice,
                                        quantity: item.quantity,
                                        participants: updatedParticipants,
                                      );
                                    });
                                    _calculateTotal();
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                }),
                Center(
                  child: TextButton.icon(
                    onPressed: _addNewItem,
                    icon: const Icon(Icons.add_circle_outline),
                    label: const Text('Agregar Item'),
                  ),
                ),
                const SizedBox(height: 16),
                const Divider(),
                const SizedBox(height: 16),

                // Sección de Impuestos
                const Text('Impuestos',
                    style:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                ...List.generate(_taxes.length, (index) {
                  final tax = _taxes[index] as Map;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.delete_outline),
                          onPressed: () => _removeTax(index),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextFormField(
                            initialValue: tax['name']?.toString() ?? '',
                            decoration: const InputDecoration(
                              hintText: 'Nombre del Impuesto',
                              hintStyle: TextStyle(color: AppColors.textHint),
                            ),
                            style: AppTextStyles.itemName,
                            onChanged: (value) {
                              setState(() {
                                tax['name'] = value;
                              });
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          width: 110,
                          child: Row(
                            children: [
                              Text('\$', style: AppTextStyles.itemPrice),
                              const SizedBox(width: 4),
                              Expanded(
                                child: TextFormField(
                                  initialValue: NumberFormat.currency(
                                    locale: 'es_CO',
                                    symbol: '',
                                    decimalDigits: 0,
                                  ).format(tax['amount'] ?? 0.0).trim(),
                                  keyboardType:
                                      const TextInputType.numberWithOptions(
                                          decimal: false),
                                  textAlign: TextAlign.right,
                                  style: AppTextStyles.itemPrice,
                                  inputFormatters: [
                                    FilteringTextInputFormatter.digitsOnly,
                                    CurrencyInputFormatter(),
                                  ],
                                  decoration: const InputDecoration(
                                    hintText: '0',
                                    hintStyle:
                                        TextStyle(color: AppColors.textHint),
                                  ),
                                  onChanged: (value) {
                                    final cleanValue =
                                        value.replaceAll(RegExp(r'[^\d]'), '');
                                    setState(() {
                                      tax['amount'] =
                                          double.tryParse(cleanValue) ?? 0.0;
                                    });
                                    _calculateTotal();
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                }),
                Center(
                  child: TextButton.icon(
                    onPressed: _addNewTax,
                    icon: const Icon(Icons.add_circle_outline),
                    label: const Text('Agregar Impuesto'),
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(
                  color: theme.dividerTheme.color ?? theme.dividerColor ?? Colors.grey.shade300,
                ),
              ),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Total', style: AppTextStyles.labelBold),
                    Text(
                        '\$${NumberFormat.currency(locale: 'es_CO', symbol: '', decimalDigits: 0).format(_totalBill).trim()}',
                        style: AppTextStyles.labelBold),
                  ],
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isSaving ? null : _saveChanges,
                    child: _isSaving
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Guardar Cambios'),
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

class CurrencyInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    if (newValue.text.isEmpty) {
      return newValue.copyWith(text: '');
    }

    // Remover todo lo que no sea dígito
    String newText = newValue.text.replaceAll(RegExp(r'[^\d]'), '');
    
    // Si no hay texto después de limpiar, retornar vacío
    if (newText.isEmpty) {
      return newValue.copyWith(text: '');
    }

    // Convertir a número y formatear
    double value = double.parse(newText);
    final formatter = NumberFormat.currency(
      locale: 'es_CO',
      symbol: '',
      decimalDigits: 0,
    );
    String formatted = formatter.format(value).trim();

    return newValue.copyWith(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../styles.dart';
import '../models/bill_item.dart';
import '../models/saved_bill.dart';
import '../services/bill_storage_service.dart';
import '../utils/currency_input_formatter.dart';

class CreateBillScreen extends StatefulWidget {
  final List<BillItem> items;
  final double totalBill;
  final List<dynamic> taxes;
  final String receiptName;
  final String patchId; // Requerido para crear un bill

  const CreateBillScreen({
    Key? key,
    required this.items,
    required this.totalBill,
    required this.taxes,
    required this.receiptName,
    required this.patchId,
  }) : super(key: key);

  @override
  State<CreateBillScreen> createState() => _CreateBillScreenState();
}

class _CreateBillScreenState extends State<CreateBillScreen> {
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
      final newItem = BillItem(
        id: 'item-${DateTime.now().millisecondsSinceEpoch}',
        name: 'Nuevo Item',
        price: 0.0,
        quantity: 1,
        participants: [], // Sin participantes en creación
      );
      _items.add(newItem);
    });
    _calculateTotal();
  }

  void _updateItem(int index, BillItem updatedItem) {
    setState(() {
      _items[index] = updatedItem;
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
      // Crear nuevo bill
      final newBill = SavedBill(
        id: '', // El backend generará el ID
        patchId: widget.patchId,
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
        title: const Text('Crear Recibo'),
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
                Text(
                  DateFormat('MMM d, yyyy').format(DateTime.now()),
                  style: AppTextStyles.headerDate,
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                // Sección de Items
                const Text('Items',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                ...List.generate(_items.length, (index) {
                  final item = _items[index];
                  final totalItemPrice = item.price * item.quantity;
                  
                  // Card simple sin expansión (sin participantes)
                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.delete_outline, color: Colors.red),
                            onPressed: () => _removeItem(index),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                          // Cantidad
                          SizedBox(
                            width: 50,
                            child: TextFormField(
                              initialValue: item.quantity.toString(),
                              keyboardType: TextInputType.number,
                              textAlign: TextAlign.center,
                              style: const TextStyle(fontSize: 14),
                              decoration: const InputDecoration(
                                hintText: '1',
                                isDense: true,
                                contentPadding: EdgeInsets.symmetric(vertical: 8),
                              ),
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                              ],
                              onChanged: (value) {
                                final newQuantity = int.tryParse(value) ?? 1;
                                final updatedItem = BillItem(
                                  id: item.id,
                                  name: item.name,
                                  price: item.price,
                                  quantity: newQuantity,
                                  participants: [],
                                );
                                _updateItem(index, updatedItem);
                              },
                            ),
                          ),
                          const Text('×', style: TextStyle(fontSize: 16)),
                          const SizedBox(width: 8),
                          // Nombre
                          Expanded(
                            child: TextFormField(
                              initialValue: item.name,
                              decoration: const InputDecoration(
                                hintText: 'Nombre del Item',
                                hintStyle: TextStyle(color: AppColors.textHint),
                                border: InputBorder.none,
                                isDense: true,
                              ),
                              style: AppTextStyles.itemName,
                              onChanged: (value) {
                                final updatedItem = BillItem(
                                  id: item.id,
                                  name: value,
                                  price: item.price,
                                  quantity: item.quantity,
                                  participants: [],
                                );
                                _updateItem(index, updatedItem);
                              },
                            ),
                          ),
                          // Precio
                          Container(
                            width: 100,
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
                                    keyboardType: const TextInputType.numberWithOptions(
                                        decimal: false),
                                    textAlign: TextAlign.right,
                                    style: AppTextStyles.itemPrice,
                                    inputFormatters: [
                                      FilteringTextInputFormatter.digitsOnly,
                                      CurrencyInputFormatter(),
                                    ],
                                    decoration: const InputDecoration(
                                      hintText: '0',
                                      hintStyle: TextStyle(color: AppColors.textHint),
                                      border: InputBorder.none,
                                      isDense: true,
                                    ),
                                    onChanged: (value) {
                                      final cleanValue =
                                          value.replaceAll(RegExp(r'[^\d]'), '');
                                      final newPrice = double.tryParse(cleanValue) ?? 0;
                                      final updatedItem = BillItem(
                                        id: item.id,
                                        name: item.name,
                                        price: newPrice,
                                        quantity: item.quantity,
                                        participants: [],
                                      );
                                      _updateItem(index, updatedItem);
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
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
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
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
                                  keyboardType: const TextInputType.numberWithOptions(
                                      decimal: false),
                                  textAlign: TextAlign.right,
                                  style: AppTextStyles.itemPrice,
                                  inputFormatters: [
                                    FilteringTextInputFormatter.digitsOnly,
                                    CurrencyInputFormatter(),
                                  ],
                                  decoration: const InputDecoration(
                                    hintText: '0',
                                    hintStyle: TextStyle(color: AppColors.textHint),
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
                        : const Text('Guardar Recibo'),
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


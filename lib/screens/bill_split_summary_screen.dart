import 'package:flutter/material.dart';

import 'package:uuid/uuid.dart';
import 'bill_edit_screen.dart';
import '../models/bill_item.dart';
import '../models/user.dart';
import '../models/saved_bill.dart';
import '../models/item_participant.dart';
import '../services/bill_storage_service.dart';

class BillSplitSummaryScreen extends StatefulWidget {
  final List<BillItem> items;
  final double total;
  final List<dynamic> taxes;
  // itemParticipants usa itemId como clave y List<User> para la UI
  // Se convertirá a Map<itemId, List<userId>> al guardar
  final Map<String, List<User>> itemParticipants;
  final String receiptName;
  final String? billId; // ID del bill si ya existe (para actualizar en lugar de crear)
  final String? patchId; // PatchId para asociar

  const BillSplitSummaryScreen({
    super.key,
    required this.items,
    required this.total,
    required this.taxes,
    required this.itemParticipants,
    required this.receiptName,
    this.billId,
    this.patchId,
  });

  @override
  State<BillSplitSummaryScreen> createState() => _BillSplitSummaryScreenState();
}

class _BillSplitSummaryScreenState extends State<BillSplitSummaryScreen> {
  late List<BillItem> _items;
  late double _total;
  late List<dynamic> _taxes;
  late Map<String, List<User>> _itemParticipants;
  late String _receiptName;
  final Map<String, bool> _expandedStates = {};
  late BillStorageService _billStorage;

  @override
  void initState() {
    super.initState();
    _items = List.from(widget.items);
    _total = widget.total;
    _taxes = List.from(widget.taxes);
    _itemParticipants = Map.from(widget.itemParticipants);
    _receiptName = widget.receiptName;
    // Inicializar estados expandidos
    for (var user in _itemParticipants.values.expand((users) => users)) {
      _expandedStates[user.name] = false;
    }
    _initializeStorage();
  }

  Future<void> _initializeStorage() async {
// final prefs = await SharedPreferences.getInstance(); // No longer needed
    _billStorage = BillStorageService();
  }

  Future<void> _saveBill() async {
    // Convertir itemParticipants a items con participantes incluidos
    // Calcular share equitativo para cada participante
    final List<BillItem> itemsWithParticipants = _items.map((item) {
      final participants = _itemParticipants[item.id] ?? [];
      
      // Calcular share equitativo
      final share = participants.isEmpty ? item.price : item.price / participants.length;
      
      // Crear ItemParticipant para cada usuario
      final itemParticipants = participants.map((user) => ItemParticipant(
        userId: user.id,
        share: share,
        shareType: 'equal',
        paid: false,
        paidAmount: 0.0,
      )).toList();
      
      return BillItem(
        id: item.id,
        name: item.name,
        price: item.price,
        quantity: item.quantity,
        participants: itemParticipants,
      );
    }).toList();
    
    // Si ya existe un billId, actualizar en lugar de crear
    if (widget.billId != null) {
      // Actualizar directamente sin hacer GET primero
      final updatedBill = SavedBill(
        id: widget.billId!,
        patchId: widget.patchId,
        name: _receiptName,
        date: DateTime.now(), // El backend puede preservar la fecha original si es necesario
        total: _total,
        items: itemsWithParticipants,
        taxes: _taxes,
      );
      await _billStorage.updateBill(updatedBill);
    } else {
      // Crear nuevo bill - no generar ID, dejar que el backend lo genere
      final bill = SavedBill(
        id: '', // ID temporal, el backend generará uno nuevo
        patchId: widget.patchId,
        name: _receiptName,
        date: DateTime.now(),
        total: _total,
        items: itemsWithParticipants,
        taxes: _taxes,
      );
      await _billStorage.saveBill(bill, isNewBill: true); // El backend generará el ID
    }
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Factura guardada exitosamente')),
      );
      // Navegar a la pantalla de inicio
      Navigator.of(context).popUntil((route) => route.isFirst);
    }
  }

  @override
  void didUpdateWidget(BillSplitSummaryScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.items != oldWidget.items) {
      _items = List.from(widget.items);
    }
    if (widget.total != oldWidget.total) {
      _total = widget.total;
    }
    if (widget.taxes != oldWidget.taxes) {
      _taxes = List.from(widget.taxes);
    }
    if (widget.itemParticipants != oldWidget.itemParticipants) {
      _itemParticipants = Map.from(widget.itemParticipants);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Bill Split Summary',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.share_outlined, color: Colors.black),
            onPressed: () {},
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Headder Card
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey[200]!),
                    ),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Sept 4, 2024 - 08:36 AM',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _receiptName,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.green[50],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'Resumen por persona',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.green[700],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Lista de totales por persona
                  ..._getUserItems().entries.map((entry) {
                    final userName = entry.key;
                    final userItems = entry.value;

                    // Calcular el total para este usuario
                    final totalForUser = userItems.fold<double>(
                      0,
                      (sum, item) {
                        final itemParticipants =
                            _itemParticipants[item.id]?.length ?? 1;
                        return sum + (item.price / itemParticipants);
                      },
                    );

                    return _buildPersonCard(
                      context,
                      userName,
                      totalForUser,
                      _getAvatarColor(userName),
                      userItems,
                    );
                  }).toList(),
                  const SizedBox(height: 100), // Espacio extra para el scroll
                ],
              ),
            ),
          ),
          
          // Fixed Bottom Buttons
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -4),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _saveBill,
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      side: BorderSide(color: Colors.grey[300]!),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Save Bill',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {},
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1E2B45),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Copy Link',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
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

  Map<String, List<BillItem>> _getUserItems() {
    final userItems = <String, List<BillItem>>{};

    // Agrupar items por usuario usando itemId
    for (var entry in _itemParticipants.entries) {
      final itemId = entry.key;
      final users = entry.value;
      final item = _items.firstWhere(
        (item) => item.id == itemId,
        orElse: () => BillItem(id: itemId, name: 'Item desconocido', price: 0.0),
      );

      for (var user in users) {
        if (!userItems.containsKey(user.name)) {
          userItems[user.name] = [];
        }
        userItems[user.name]!.add(item);
      }
    }

    return userItems;
  }

  Widget _buildPersonCard(
    BuildContext context,
    String name,
    double amount,
    Color avatarColor,
    List<BillItem> items,
  ) {
    final isExpanded = _expandedStates[name] ?? false;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[200]!),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: avatarColor,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      name[0].toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1E2B45),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Total: \$${amount.toStringAsFixed(2)}',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.blue[700],
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: isExpanded ? Colors.blue[50] : Colors.grey[50],
                      shape: BoxShape.circle,
                    ),
                    child: AnimatedRotation(
                      duration: const Duration(milliseconds: 300),
                      turns: isExpanded ? 0.25 : 0, 
                      // 0.25 turns = 90 degrees (down), 0 = 0 (right/default)
                      // Icon is ios_arrow_forward, so 0 is right. 
                      // We want it to point down when expanded.
                      child: Icon(
                        Icons.arrow_forward_ios_rounded,
                        size: 16,
                        color: isExpanded ? Colors.blue[700] : Colors.grey[600],
                      ),
                    ),
                  ),
                  onPressed: () {
                    setState(() {
                      _expandedStates[name] = !isExpanded;
                    });
                  },
                ),
              ],
            ),
          ),
          if (isExpanded) ...[
            Divider(height: 1, color: Colors.grey[100]),
            Container(
              color: Colors.grey[50],
              padding: const EdgeInsets.all(16),
              child: Column(
                children: items.map((item) {
                  final itemParticipants =
                      _itemParticipants[item.name]?.length ?? 1;
                  final individualShare = item.price / itemParticipants;

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.name,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.black87,
                                ),
                              ),
                              RichText(
                                text: TextSpan(
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[600],
                                  ),
                                  children: [
                                    const TextSpan(text: 'Split with '),
                                    TextSpan(
                                      text: '$itemParticipants others',
                                      style: const TextStyle(
                                          fontWeight: FontWeight.w600),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          '\$${individualShare.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Color _getAvatarColor(String name) {
    final colors = {
      'Jelly': Colors.blue,
      'Amanda': Colors.red,
      'Bill': Colors.blue,
      'Charlie': Colors.yellow,
    };
    return colors[name] ?? Colors.blue;
  }
}

import 'package:flutter/material.dart';
import '../models/bill_item.dart';
import '../models/user.dart';
import '../models/saved_bill.dart';
import '../models/item_participant.dart';
import '../services/user_service.dart';
import '../services/bill_storage_service.dart';
import 'bill_split_summary_screen.dart';
import 'add_friends_screen.dart';
import 'bill_edit_screen.dart';

class BillSplitScreen extends StatefulWidget {
  final List<BillItem> items;
  final double totalBill;
  final List<dynamic> taxes;
  final String receiptName;
  final String? billId; // ID del bill si ya existe
  final String? patchId; // PatchId para asociar

  const BillSplitScreen({
    Key? key,
    required this.items,
    required this.totalBill,
    required this.taxes,
    required this.receiptName,
    this.billId,
    this.patchId,
  }) : super(key: key);

  @override
  State<BillSplitScreen> createState() => _BillSplitScreenState();
}

class _BillSplitScreenState extends State<BillSplitScreen> {
  final _userService = UserService();
  final _billStorage = BillStorageService();
  // Usar itemId como clave en lugar de itemName para mayor robustez
  final Map<String, List<User>> _itemParticipants = {};

  @override
  void initState() {
    super.initState();
    for (var item in widget.items) {
      // Si el item ya tiene participantes, cargarlos
      if (item.participants.isNotEmpty) {
        // Convertir ItemParticipant a User (necesitamos obtener los usuarios)
        // Por ahora inicializamos vacío, se cargarán desde el servicio
        _itemParticipants[item.id] = [];
      } else {
        _itemParticipants[item.id] = [];
      }
    }
    // Cargar participantes existentes si el bill ya tiene items con participantes
    _loadExistingParticipants();
  }

  /// Carga los participantes existentes desde los items
  void _loadExistingParticipants() {
    // Por ahora los items vienen sin participantes desde ReceiptDetailsScreen
    // En el futuro, si se carga un bill existente, aquí se cargarían los participantes
  }

  /// Guarda/actualiza el bill cuando se asignan participantes
  Future<void> _saveParticipantsUpdate() async {
    if (widget.billId == null) return;

    try {
      // Convertir participantes a formato de items
      final itemsWithParticipants = widget.items.map((item) {
        final participants = _itemParticipants[item.id] ?? [];
        final share = participants.isEmpty ? item.price : item.price / participants.length;
        
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

      // Actualizar directamente sin hacer GET primero
      final updatedBill = SavedBill(
        id: widget.billId!,
        patchId: widget.patchId,
        name: widget.receiptName,
        date: DateTime.now(), // El backend puede preservar la fecha original si es necesario
        total: widget.totalBill,
        items: itemsWithParticipants,
        taxes: widget.taxes,
      );

      await _billStorage.updateBill(updatedBill);
      print('Bill actualizado con participantes: ${widget.billId}');
    } catch (e) {
      print('Error al actualizar participantes: $e');
      // No mostrar error, es guardado en background
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
          'Dividir Items',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // STANDARD HEADER CARD
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
                        Text(
                          'Sept 4, 2024 - 08:36 AM',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          widget.receiptName,
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
                            color: Colors.blue[50],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'Asigna usuarios a cada item',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.blue[700],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),
                  const Text(
                    'Items del Recibo',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Lista de items con participantes
                  ...widget.items.map((item) => _buildItemWithParticipants(
                        context,
                        item.id,
                        item.name,
                        item.price,
                        _itemParticipants[item.id] ?? [],
                      )),

                  const SizedBox(height: 24),
                  const Divider(),
                  const SizedBox(height: 16),

                  // Totales
                  _buildTotalRow(
                      'Subtotal',
                      widget.totalBill -
                          widget.taxes
                              .fold(0.0, (sum, tax) => sum + tax['amount'])),
                  ...widget.taxes
                      .map((tax) => _buildTotalRow(tax['name'], tax['amount'])),
                  const SizedBox(height: 12),
                  _buildTotalRow('Total Waiting', widget.totalBill,
                      isTotal: true),
                      
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),

          // FIXED BOTTOM BUTTON
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
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () async {
                  // Validar que cada item tenga al menos un usuario
                  bool allItemsHaveUsers = widget.items.every((item) =>
                      _itemParticipants[item.id]?.isNotEmpty ?? false);

                  if (!allItemsHaveUsers) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                            'Por favor, asigna al menos un usuario a cada item'),
                        backgroundColor: Colors.red,
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                    return;
                  }

                  // Guardar participantes antes de ir al resumen
                  await _saveParticipantsUpdate();

                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => BillSplitSummaryScreen(
                        items: widget.items,
                        total: widget.totalBill,
                        taxes: widget.taxes,
                        itemParticipants: _itemParticipants,
                        receiptName: widget.receiptName,
                        billId: widget.billId, // Pasar billId para actualizar en lugar de crear
                        patchId: widget.patchId,
                      ),
                    ),
                  );
                },
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
                  'Confirm Result',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItemWithParticipants(
    BuildContext context,
    String itemId,
    String name,
    double price,
    List<User> participants,
  ) {
    bool hasParticipants = participants.isNotEmpty;
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              '1×',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[700],
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        name,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                    Text(
                      '\$${price.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    ...participants
                        .map((user) => _buildParticipantAvatar(user)),
                    if (hasParticipants) const SizedBox(width: 8),
                    InkWell(
                      onTap: () async {
                        final selectedUsers =
                            await Navigator.push<List<User>>(
                          context,
                          MaterialPageRoute(
                            builder: (context) => AddFriendsScreen(
                              selectedUsers: participants,
                              allowCreateNew: false,
                            ),
                          ),
                        );
                        if (selectedUsers != null) {
                          setState(() {
                            _itemParticipants[itemId] = selectedUsers;
                          });
                          // Guardar actualización en background
                          _saveParticipantsUpdate();
                        }
                      },
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: participants.isEmpty 
                              ? Colors.blue[300]! 
                              : Colors.grey[300]!,
                            width: 1,
                          ),
                          color: participants.isEmpty 
                            ? Colors.blue[50] 
                            : Colors.transparent, 
                        ),
                        child: Icon(
                          Icons.add,
                          size: 20,
                          color: participants.isEmpty 
                            ? Colors.blue[700] 
                            : Colors.grey[600],
                        ),
                      ),
                    ),
                    if (!hasParticipants)
                      Padding(
                        padding: const EdgeInsets.only(left: 8),
                        child: Text(
                          'Asignar',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.blue[700],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildParticipantAvatar(User user) {
    return Container(
      width: 36,
      height: 36,
      margin: const EdgeInsets.only(right: 4),
      decoration: BoxDecoration(
        color: user.color,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 2,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Center(
        child: Text(
          user.initials,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildTotalRow(String label, double amount, {bool isTotal = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 16,
            fontWeight: isTotal ? FontWeight.bold : FontWeight.w500,
            color: isTotal ? Colors.black : Colors.grey[600],
          ),
        ),
        Text(
          '\$${amount.toStringAsFixed(2)}',
          style: TextStyle(
            fontSize: 16,
            fontWeight: isTotal ? FontWeight.bold : FontWeight.w500,
            color: isTotal ? Colors.black : Colors.grey[800],
          ),
        ),
      ],
    );
  }
}

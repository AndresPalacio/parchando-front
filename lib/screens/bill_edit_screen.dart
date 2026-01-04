import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../styles.dart';
import '../models/bill_item.dart';
import '../models/saved_bill.dart';
import '../models/item_participant.dart';
import '../models/user.dart';
import '../services/bill_storage_service.dart';
import '../services/user_service.dart';
import 'add_friends_screen.dart';
import '../utils/currency_input_formatter.dart';

class BillEditScreen extends StatefulWidget {
  final List<BillItem> items;
  final double totalBill;
  final List<dynamic> taxes;
  final String receiptName;
  final String billId; // ID del bill (requerido para edición)
  final String? patchId; // PatchId para verificar permisos

  const BillEditScreen({
    Key? key,
    required this.items,
    required this.totalBill,
    required this.taxes,
    required this.receiptName,
    required this.billId, // Ahora es requerido
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
  final UserService _userService = UserService();
  bool _isSaving = false;
  bool _isLoading = false;
  final Map<String, bool> _expandedItems = {}; // Para controlar qué items están expandidos

  @override
  void initState() {
    super.initState();
    _items = List.from(widget.items);
    _taxes = List.from(widget.taxes);
    _billStorage = BillStorageService();
    _calculateTotal();
    _loadBillIfNeeded();
    _loadUsers(); // Siempre cargar usuarios para asociar participantes
  }

  /// Carga el bill completo para poder añadir nuevos items
  Future<void> _loadBillIfNeeded() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      final bill = await _billStorage.getBillById(widget.billId);
      if (bill != null) {
        setState(() {
          _items = List.from(bill.items);
          _taxes = List.from(bill.taxes);
          _calculateTotal();
        });
      }
    } catch (e) {
      print('Error cargando bill: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  /// Carga los usuarios para asignar como participantes
  Future<void> _loadUsers() async {
    try {
      await _userService.loadFriends();
      // Asegurarse de que el currentUser esté disponible
      _userService.currentUser;
      setState(() {});
    } catch (e) {
      print('Error cargando usuarios: $e');
    }
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
        participants: [],
      );
      _items.add(newItem);
      // Expandir el nuevo item automáticamente para poder agregar participantes
      _expandedItems[newItem.id] = true;
    });
    _calculateTotal();
  }

  /// Actualiza un item en la lista
  void _updateItem(int index, BillItem updatedItem) {
    setState(() {
      _items[index] = updatedItem;
    });
    _calculateTotal();
  }

  /// Agrega o actualiza participantes de un item
  Future<void> _manageItemParticipants(int itemIndex) async {
    final item = _items[itemIndex];
    
    // Convertir ItemParticipant a User para la pantalla de selección
    final currentParticipantUsers = item.participants.map((p) {
      final user = _userService.getUserById(p.userId);
      if (user != null) return user;
      
      // Si el userId es "current", usar el currentUser
      if (p.userId == 'current') {
        return _userService.currentUser;
      }
      
      // Crear un usuario temporal con nombre válido
      return User(
        id: p.userId,
        name: 'Usuario ${p.userId.substring(0, p.userId.length > 8 ? 8 : p.userId.length)}',
        color: Colors.grey,
      );
    }).toList();

    final selectedUsers = await Navigator.push<List<User>>(
      context,
      MaterialPageRoute(
        builder: (context) => AddFriendsScreen(
          selectedUsers: currentParticipantUsers,
          allowCreateNew: true,
        ),
      ),
    );

    if (selectedUsers != null && selectedUsers.isNotEmpty) {
      // Calcular share igual para todos (puedes mejorar esto para custom shares)
      final totalPrice = item.price * item.quantity;
      final sharePerPerson = totalPrice / selectedUsers.length;

      final updatedParticipants = selectedUsers.map((user) {
        // Buscar si ya existe un participante para este usuario
        final existing = item.participants.firstWhere(
          (p) => p.userId == user.id,
          orElse: () => ItemParticipant(
            userId: user.id,
            share: sharePerPerson,
            shareType: 'equal',
            paid: false,
            paidAmount: 0.0,
          ),
        );
        
        // Si existe, mantener su estado pero actualizar el share
        return ItemParticipant(
          userId: user.id,
          share: sharePerPerson,
          shareType: existing.shareType,
          paid: existing.paid,
          paidAmount: existing.paidAmount,
        );
      }).toList();

      final updatedItem = BillItem(
        id: item.id,
        name: item.name,
        price: item.price,
        quantity: item.quantity,
        participants: updatedParticipants,
      );

      _updateItem(itemIndex, updatedItem);
    } else if (selectedUsers != null && selectedUsers.isEmpty) {
      // Si se deseleccionaron todos, limpiar participantes
      final updatedItem = BillItem(
        id: item.id,
        name: item.name,
        price: item.price,
        quantity: item.quantity,
        participants: [],
      );
      _updateItem(itemIndex, updatedItem);
    }
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
      // Obtener el bill completo primero para mantener la fecha original
      SavedBill? existingBill;
      try {
        existingBill = await _billStorage.getBillById(widget.billId);
      } catch (e) {
        print('No se pudo cargar el bill existente, usando datos actuales: $e');
      }

      // Actualizar bill existente con TODOS los items (existentes + nuevos)
      final updatedBill = SavedBill(
        id: widget.billId,
        patchId: widget.patchId ?? existingBill?.patchId,
        name: widget.receiptName,
        date: existingBill?.date ?? DateTime.now(), // Mantener fecha original
        total: _totalBill,
        items: _items, // TODOS los items (existentes + nuevos)
        taxes: _taxes,
      );

      print('💾 Actualizando bill con ${_items.length} items:');
      for (var item in _items) {
        print('  - ${item.name}: \$${item.price} × ${item.quantity} = \$${item.price * item.quantity} (${item.participants.length} participantes)');
      }

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
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : ListView(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    children: [
                // Sección de Items
                const Text('Items',
                    style:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                ...List.generate(_items.length, (index) {
                  final item = _items[index];
                  final isExpanded = _expandedItems[item.id] ?? false;
                  final totalItemPrice = item.price * item.quantity;
                  
                  // ExpansionTile con participantes (solo modo edición)
                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: ExpansionTile(
                      initiallyExpanded: isExpanded,
                      onExpansionChanged: (expanded) {
                        setState(() {
                          _expandedItems[item.id] = expanded;
                        });
                      },
                      leading: IconButton(
                        icon: const Icon(Icons.delete_outline, color: Colors.red),
                        onPressed: () => _removeItem(index),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                      title: Row(
                        children: [
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
                                  participants: item.participants,
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
                                  participants: item.participants,
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
                                      border: InputBorder.none,
                                      isDense: true,
                                    ),
                                    onChanged: (value) {
                                      final cleanValue =
                                          value.replaceAll(RegExp(r'[^\d]'), '');
                                      final newPrice = double.tryParse(cleanValue) ?? 0;
                                      
                                      // Recalcular shares si hay participantes
                                      List<ItemParticipant> updatedParticipants = item.participants;
                                      if (item.participants.isNotEmpty) {
                                        final totalPrice = newPrice * item.quantity;
                                        final share = totalPrice / item.participants.length;
                                        updatedParticipants = item.participants.map((p) => ItemParticipant(
                                          userId: p.userId,
                                          share: share,
                                          shareType: p.shareType,
                                          paid: p.paid,
                                          paidAmount: p.paidAmount,
                                        )).toList();
                                      }
                                      
                                      final updatedItem = BillItem(
                                        id: item.id,
                                        name: item.name,
                                        price: newPrice,
                                        quantity: item.quantity,
                                        participants: updatedParticipants,
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
                      subtitle: Text(
                        'Total: \$${NumberFormat.currency(locale: 'es_CO', symbol: '', decimalDigits: 0).format(totalItemPrice).trim()} • ${item.participants.length} participante${item.participants.length != 1 ? 's' : ''}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Participantes - SOLO en modo edición
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text(
                                    'Participantes:',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  TextButton.icon(
                                    onPressed: () => _manageItemParticipants(index),
                                    icon: const Icon(Icons.person_add, size: 18),
                                    label: Text(
                                      item.participants.isEmpty
                                          ? 'Agregar'
                                          : 'Editar',
                                    ),
                                  ),
                                ],
                              ),
                              if (item.participants.isEmpty)
                                Padding(
                                  padding: const EdgeInsets.only(top: 8),
                                  child: Text(
                                    'No hay participantes asignados',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[600],
                                      fontStyle: FontStyle.italic,
                                    ),
                                  ),
                                )
                              else
                                ...item.participants.map((participant) {
                                  // Obtener el usuario, con fallback para "current"
                                  User? user = _userService.getUserById(participant.userId);
                                  if (user == null && participant.userId == 'current') {
                                    user = _userService.currentUser;
                                  }
                                  if (user == null) {
                                    // Crear usuario temporal si no existe
                                    user = User(
                                      id: participant.userId,
                                      name: participant.userId == 'current' 
                                          ? 'Usuario Actual' 
                                          : 'Usuario ${participant.userId.substring(0, participant.userId.length > 8 ? 8 : participant.userId.length)}',
                                      color: Colors.grey,
                                    );
                                  }
                                  
                                  return Padding(
                                    padding: const EdgeInsets.only(bottom: 8),
                                    child: Row(
                                      children: [
                                        Container(
                                          width: 32,
                                          height: 32,
                                          decoration: BoxDecoration(
                                            color: user.color,
                                            shape: BoxShape.circle,
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
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                user.name,
                                                style: const TextStyle(
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                              Text(
                                                'Share: \$${NumberFormat.currency(locale: 'es_CO', symbol: '', decimalDigits: 0).format(participant.share).trim()} (${participant.shareType})',
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: Colors.grey[600],
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        if (participant.paid)
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 4,
                                            ),
                                            decoration: BoxDecoration(
                                              color: Colors.green[100],
                                              borderRadius: BorderRadius.circular(12),
                                            ),
                                            child: const Text(
                                              'Pagado',
                                              style: TextStyle(
                                                fontSize: 10,
                                                color: Colors.green,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                  );
                                }).toList(),
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


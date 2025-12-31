import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/bill_item.dart';
import '../models/user.dart';
import '../models/saved_bill.dart';
import '../models/item_participant.dart';
import '../services/user_service.dart';
import '../services/bill_storage_service.dart';
import '../services/patch_storage_service.dart';
import '../models/patch.dart';
import 'bill_split_screen.dart';
import 'add_friends_screen.dart';
import 'bill_edit_screen.dart' as edit;

class ReceiptDetailsScreen extends StatefulWidget {
  final List<BillItem> items;
  final double totalBill;
  final List<dynamic> taxes;

  const ReceiptDetailsScreen({
    super.key,
    required this.items,
    required this.totalBill,
    required this.taxes,
  });

  @override
  State<ReceiptDetailsScreen> createState() => _ReceiptDetailsScreenState();
}

class _ReceiptDetailsScreenState extends State<ReceiptDetailsScreen> {
  final _userService = UserService();
  final _billStorage = BillStorageService();
  final _patchStorage = PatchStorageService();
  final List<User> _selectedUsers = [];
  String _selectedCategory = 'Café';
  String _receiptName = '';
  String? _parcheId; // ID del parche creado
  late TextEditingController _nameController;
  final List<String> _categories = [
    'Café',
    'Restaurante',
    'Supermercado',
    'Transporte',
    'Entretenimiento',
    'Otros'
  ];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: _receiptName);
    // Inicializar con el usuario actual
    _selectedUsers.add(_userService.currentUser);
  }

  /// Crea un parche con los miembros seleccionados
  /// El bill se creará después en la pantalla "Editar Recibo"
  Future<String?> _createParche() async {
    try {
      // Crear el parche con los miembros seleccionados
      final memberIds = _selectedUsers.map((user) => user.id).toList();
      final parche = Patch(
        id: '', // El backend generará el ID
        name: _receiptName.isEmpty ? 'Parche sin nombre' : _receiptName,
        icon: '🎉', // Puedes cambiar esto según la categoría
        memberIds: memberIds,
        createdAt: DateTime.now(),
      );

      print('📝 Creando parche con ${memberIds.length} miembros...');
      final parcheId = await _patchStorage.savePatch(parche);
      print('✅ Parche creado con ID: $parcheId');

      setState(() {
        _parcheId = parcheId;
      });

      return parcheId;
    } catch (e) {
      print('❌ Error al crear parche: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al crear parche: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return null;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _showCategoryPicker() {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Selecciona una categoría',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              ..._categories.map((category) => ListTile(
                    title: Text(category),
                    onTap: () {
                      setState(() {
                        _selectedCategory = category;
                      });
                      Navigator.pop(context);
                    },
                    trailing: _selectedCategory == category
                        ? const Icon(Icons.check, color: Colors.green)
                        : null,
                  )),
            ],
          ),
        );
      },
    );
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
          'Detalles del Recibo',
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
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 16),
                  // SECCIÓN 1: Encabezado (Nombre, Categoría, Fecha)
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey[200]!),
                    ),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Fecha
                        Text(
                          'Sept 4, 2024 - 08:36 AM',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 12),
                        // Input Nombre del Recibo
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey[200]!),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.02),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          child: Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: _nameController,
                                  textCapitalization:
                                      TextCapitalization.sentences,
                                  onChanged: (value) {
                                    setState(() {
                                      _receiptName = value;
                                    });
                                  },
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.black87,
                                  ),
                                  decoration: const InputDecoration(
                                    hintText: 'Ej: Cena en Andrés',
                                    hintStyle: TextStyle(
                                        color: Colors.grey,
                                        fontWeight: FontWeight.normal),
                                    border: InputBorder.none,
                                    isDense: true,
                                    contentPadding:
                                        EdgeInsets.symmetric(vertical: 8),
                                    labelText: 'Nombre del Recibo',
                                    floatingLabelBehavior:
                                        FloatingLabelBehavior.always,
                                    labelStyle: TextStyle(
                                      color: Colors.grey,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ),
                              if (_receiptName.isNotEmpty)
                                GestureDetector(
                                  onTap: () {
                                    _nameController.clear();
                                    setState(() {
                                      _receiptName = '';
                                    });
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: BoxDecoration(
                                      color: Colors.grey[200],
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      Icons.close,
                                      size: 16,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        // Fila de Categoría y Participantes
                        Row(
                          children: [
                            // Categoría
                            GestureDetector(
                              onTap: _showCategoryPicker,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 8),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(color: Colors.grey[300]!),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.category_outlined,
                                        size: 16, color: Colors.grey[700]),
                                    const SizedBox(width: 8),
                                    Text(
                                      _selectedCategory,
                                      style: TextStyle(
                                        color: Colors.grey[800],
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    Icon(Icons.keyboard_arrow_down,
                                        size: 16, color: Colors.grey[700]),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        // Participantes
                        const SizedBox(height: 24),
                        // Participantes
                        const Text(
                          "Participantes",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 12),
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              ..._selectedUsers
                                  .map((user) => _buildAvatarCircle(user)),
                              
                              // Botón de Agregar (Más grande y visible)
                              GestureDetector(
                                onTap: () async {
                                  final selectedUsers =
                                      await Navigator.push<List<User>>(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => AddFriendsScreen(
                                        selectedUsers: _selectedUsers,
                                        allowCreateNew: true,
                                      ),
                                    ),
                                  );
                                  if (selectedUsers != null) {
                                    setState(() {
                                      _selectedUsers.clear();
                                      _selectedUsers.addAll(selectedUsers);
                                    });
                                  }
                                },
                                child: Container(
                                  width: 50,
                                  height: 50,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF1E2B45),
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: const Color(0xFF1E2B45).withOpacity(0.3),
                                        blurRadius: 8,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: const Icon(
                                    Icons.person_add_rounded,
                                    color: Colors.white,
                                    size: 24,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  if (widget.items.isEmpty)
                    // VISTA MANUAL: Simplificada
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                          vertical: 40, horizontal: 24),
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: Colors.grey[200]!),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.blue[50],
                              shape: BoxShape.circle,
                            ),
                            child: Icon(Icons.post_add_rounded,
                                size: 40, color: Colors.blue[700]),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Configuración Inicial',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue[900],
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Una vez definas el nombre y los participantes, pulsa "Continuar" para empezar a agregar tus ítems manualmente.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                              height: 1.5,
                            ),
                          ),
                        ],
                      ),
                    )
                  else ...[
                    // VISTA OCR: Completa con items y totales
                    const Text(
                      'Ítems de la Cuenta',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ...widget.items.map((item) => _buildReceiptItem(
                          item.name,
                          item.quantity,
                          item.price,
                        )),
                    const SizedBox(height: 8),
                    const Divider(),
                    const SizedBox(height: 20),
                    // Totales
                    _buildTotalRow(
                        'Subtotal',
                        widget.totalBill -
                            widget.taxes
                                .fold(0.0, (sum, tax) => sum + tax['amount'])),
                    ...widget.taxes.map(
                        (tax) => _buildTotalRow(tax['name'], tax['amount'])),
                    const SizedBox(height: 12),
                    _buildTotalRow('Total', widget.totalBill, isTotal: true),
                  ],
                  
                  // Espacio extra para scroll
                  const SizedBox(height: 100), 
                ],
              ),
            ),
          ),
          
          // SECCIÓN 4: Botones de Acción (Fijos abajo)
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
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      side: BorderSide(color: Colors.grey[300]!),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      'Cancelar',
                      style: TextStyle(color: Colors.grey[800]),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () async {
                      // Crear solo el parche (el bill se creará en BillEditScreen)
                      final parcheId = await _createParche();
                      if (parcheId == null) {
                        // Hubo un error al crear el parche, no continuar
                        return;
                      }

                      // Navegar a BillEditScreen con el parcheId creado
                      final editResult = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => edit.BillEditScreen(
                            items: widget.items,
                            totalBill: widget.totalBill,
                            taxes: widget.taxes,
                            receiptName: _receiptName,
                            billId: null, // No hay billId todavía
                            patchId: parcheId,
                          ),
                        ),
                      );

                      if (editResult != null) {
                        // editResult ahora incluye el billId creado en BillEditScreen
                        final billId = editResult['billId'] as String?;
                        
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (context) => BillSplitScreen(
                              items: editResult['items'] as List<BillItem>,
                              totalBill: editResult['totalBill'] as double,
                              taxes: editResult['taxes'] as List<dynamic>,
                              receiptName: _receiptName,
                              billId: billId,
                              patchId: parcheId,
                            ),
                          ),
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue[700],
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Continuar',
                      style: TextStyle(
                          color: Colors.white, fontWeight: FontWeight.bold),
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

  Widget _buildReceiptItem(String name, int quantity, double price) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Text(
            '$quantity',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              name,
              style: const TextStyle(
                fontSize: 16,
              ),
            ),
          ),
          Text(
            '\$${price.toStringAsFixed(2)}',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
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
            fontWeight: isTotal ? FontWeight.w600 : FontWeight.normal,
            color: isTotal ? Colors.black : Colors.grey[600],
          ),
        ),
        Text(
          '\$${amount.toStringAsFixed(2)}',
          style: TextStyle(
            fontSize: 16,
            fontWeight: isTotal ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ],
    );
  }

  Widget _buildAvatarCircle(User user) {
    return Container(
      width: 50,
      height: 50,
      margin: const EdgeInsets.only(right: 12),
      decoration: BoxDecoration(
        color: user.color,
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
          user.initials,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/user.dart';
import '../models/patch.dart';
import '../models/saved_bill.dart';
import '../services/user_service.dart';
import '../services/patch_storage_service.dart';
import '../services/bill_storage_service.dart';
import 'add_friends_screen.dart';
import 'bill_edit_screen.dart';

class EditPatchScreen extends StatefulWidget {
  final String patchId;

  const EditPatchScreen({
    super.key,
    required this.patchId,
  });

  @override
  State<EditPatchScreen> createState() => _EditPatchScreenState();
}

class _EditPatchScreenState extends State<EditPatchScreen> {
  final _userService = UserService();
  final _patchStorage = PatchStorageService();
  final _billStorage = BillStorageService();
  final List<User> _selectedUsers = [];
  String _patchName = '';
  String? _patchIcon;
  DateTime? _originalCreatedAt;
  bool _isLoading = true;
  bool _isSaving = false;
  bool _isLoadingBills = false;
  late TextEditingController _nameController;
  List<SavedBill> _bills = [];
  final List<String> _categories = [
    'Café',
    'Restaurante',
    'Supermercado',
    'Transporte',
    'Entretenimiento',
    'Otros'
  ];
  String _selectedCategory = 'Otros';

  // Mapeo de categorías a iconos
  final Map<String, String> _categoryIcons = {
    'Café': '☕',
    'Restaurante': '🍽️',
    'Supermercado': '🛒',
    'Transporte': '🚗',
    'Entretenimiento': '🎬',
    'Otros': '🎉',
  };

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _loadPatch();
  }

  Future<void> _loadPatch() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Cargar amigos primero
      await _userService.loadFriends();

      // Obtener el parche
      final patch = await _patchStorage.getPatchById(widget.patchId);
      
      if (patch == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No se pudo cargar el parche'),
              backgroundColor: Colors.red,
            ),
          );
          Navigator.pop(context);
        }
        return;
      }

      // Cargar los usuarios del parche
      final List<User> patchUsers = [];
      for (var userId in patch.memberIds) {
        final user = _userService.getUserById(userId);
        if (user != null) {
          patchUsers.add(user);
        } else if (userId == 'current') {
          patchUsers.add(_userService.currentUser);
        } else {
          // Si no se encuentra el usuario, crear uno temporal
          patchUsers.add(User(
            id: userId,
            name: 'Usuario ${userId.substring(0, userId.length > 8 ? 8 : userId.length)}',
            color: Colors.grey,
          ));
        }
      }

      // Determinar la categoría basada en el icono
      String category = 'Otros';
      for (var entry in _categoryIcons.entries) {
        if (entry.value == (patch.icon ?? '🎉')) {
          category = entry.key;
          break;
        }
      }

      setState(() {
        _patchName = patch.name;
        _patchIcon = patch.icon ?? '🎉';
        _selectedCategory = category;
        _originalCreatedAt = patch.createdAt;
        _selectedUsers.clear();
        _selectedUsers.addAll(patchUsers);
        _nameController.text = _patchName;
        _isLoading = false;
      });

      // Cargar los bills del parche después de un pequeño delay para asegurar que el estado esté actualizado
      await Future.delayed(const Duration(milliseconds: 100));
      await _loadBills();
    } catch (e) {
      print('❌ Error al cargar parche: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al cargar el parche: $e'),
            backgroundColor: Colors.red,
          ),
        );
        Navigator.pop(context);
      }
    }
  }

  Future<void> _loadBills() async {
    if (!mounted) return;
    
    setState(() {
      _isLoadingBills = true;
    });

    try {
      print('🔍 Cargando bills del parche:');
      print('  - Patch ID: ${widget.patchId}');
      print('  - Tipo: ${widget.patchId.runtimeType}');
      
      final bills = await _billStorage.getBillsByPatchId(widget.patchId);
      print('✅ Bills cargados: ${bills.length}');
      
      if (bills.isNotEmpty) {
        print('📋 Bills encontrados:');
        for (var bill in bills) {
          print('  - ${bill.name} (ID: ${bill.id}, patchId: ${bill.patchId})');
        }
      } else {
        print('⚠️ No se encontraron bills para el parche ${widget.patchId}');
      }
      
      if (mounted) {
        setState(() {
          _bills = bills;
          _isLoadingBills = false;
        });
      }
    } catch (e, stackTrace) {
      print('❌ Error cargando bills: $e');
      print('Stack trace: $stackTrace');
      if (mounted) {
        setState(() {
          _bills = [];
          _isLoadingBills = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al cargar las facturas: $e'),
            backgroundColor: Colors.orange,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  Future<void> _savePatch() async {
    if (_patchName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor ingresa un nombre para el parche'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (_selectedUsers.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor selecciona al menos un participante'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final memberIds = _selectedUsers.map((user) => user.id).toList();
      final updatedPatch = Patch(
        id: widget.patchId,
        name: _patchName,
        icon: _patchIcon ?? '🎉',
        memberIds: memberIds,
        createdAt: _originalCreatedAt ?? DateTime.now(),
      );

      await _patchStorage.updatePatch(updatedPatch);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Parche actualizado exitosamente'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      print('❌ Error al actualizar parche: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al actualizar el parche: $e'),
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
                    leading: Text(
                      _categoryIcons[category] ?? '🎉',
                      style: const TextStyle(fontSize: 24),
                    ),
                    title: Text(category),
                    onTap: () {
                      setState(() {
                        _selectedCategory = category;
                        _patchIcon = _categoryIcons[category] ?? '🎉';
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

  Future<void> _editBill(SavedBill bill) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BillEditScreen(
          items: bill.items,
          totalBill: bill.total,
          taxes: bill.taxes,
          receiptName: bill.name,
          billId: bill.id,
          patchId: bill.patchId,
        ),
      ),
    );

    // Si se guardaron cambios, recargar la lista de bills
    if (result != null) {
      await _loadBills();
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    if (_isLoading) {
      return Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.pop(context),
          ),
          title: const Text(
            'Editar Parche',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Editar Parche',
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
                  // SECCIÓN 1: Información del Parche
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
                        // Input Nombre del Parche
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
                                      _patchName = value;
                                    });
                                  },
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.black87,
                                  ),
                                  decoration: const InputDecoration(
                                    hintText: 'Ej: Viaje a la Costa',
                                    hintStyle: TextStyle(
                                        color: Colors.grey,
                                        fontWeight: FontWeight.normal),
                                    border: InputBorder.none,
                                    isDense: true,
                                    contentPadding:
                                        EdgeInsets.symmetric(vertical: 8),
                                    labelText: 'Nombre del Parche',
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
                              if (_patchName.isNotEmpty)
                                GestureDetector(
                                  onTap: () {
                                    _nameController.clear();
                                    setState(() {
                                      _patchName = '';
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
                        // Fila de Categoría
                        Row(
                          children: [
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
                                    Text(
                                      _patchIcon ?? '🎉',
                                      style: const TextStyle(fontSize: 16),
                                    ),
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
                              
                              // Botón de Agregar
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

                  // SECCIÓN 2: Bills del Parche
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Facturas del Parche',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (_isLoadingBills)
                        const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      else
                        Text(
                          '${_bills.length} factura${_bills.length != 1 ? 's' : ''}',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (!_isLoadingBills && _bills.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(32),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.grey[200]!),
                      ),
                      child: Column(
                        children: [
                          Icon(Icons.receipt_long_outlined,
                              size: 48, color: Colors.grey[300]),
                          const SizedBox(height: 16),
                          Text(
                            'No hay facturas en este parche',
                            style: TextStyle(
                              color: Colors.grey[400],
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Las facturas que crees asociadas a este parche aparecerán aquí',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.grey[400],
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    )
                  else if (!_isLoadingBills && _bills.isNotEmpty)
                    ..._bills.map((bill) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () => _editBill(bill),
                            borderRadius: BorderRadius.circular(16),
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: Colors.grey[200]!),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 40,
                                    height: 40,
                                    decoration: BoxDecoration(
                                      color: Colors.blue[100],
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Icon(
                                      Icons.receipt,
                                      color: Colors.blue[700],
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          bill.name,
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          '${bill.items.length} item${bill.items.length != 1 ? 's' : ''} • \$${NumberFormat.currency(locale: 'es_CO', symbol: '', decimalDigits: 0).format(bill.total).trim()} • ${DateFormat('dd/MM/yyyy').format(bill.date)}',
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: Colors.grey[600],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Icon(
                                    Icons.chevron_right,
                                    color: Colors.grey[400],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  
                  // Espacio extra para scroll
                  const SizedBox(height: 100), 
                ],
              ),
            ),
          ),
          
          // SECCIÓN 3: Botones de Acción (Fijos abajo)
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
                    onPressed: _isSaving ? null : () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      side: BorderSide(color: Colors.grey[300]!),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Cancelar',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isSaving ? null : _savePatch,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue[700],
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _isSaving
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Text(
                            'Guardar Cambios',
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

  Widget _buildAvatarCircle(User user) {
    return GestureDetector(
      onLongPress: () {
        // Permitir eliminar participantes con long press
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Eliminar participante'),
            content: Text('¿Deseas eliminar a ${user.name} del parche?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancelar'),
              ),
              TextButton(
                onPressed: () {
                  setState(() {
                    _selectedUsers.removeWhere((u) => u.id == user.id);
                  });
                  Navigator.pop(context);
                },
                style: TextButton.styleFrom(
                  foregroundColor: Colors.red,
                ),
                child: const Text('Eliminar'),
              ),
            ],
          ),
        );
      },
      child: Container(
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
      ),
    );
  }
}


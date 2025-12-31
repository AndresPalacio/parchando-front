import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/user.dart';
import 'api_headers_helper.dart';

class UserService {
  static final UserService _instance = UserService._internal();
  factory UserService() => _instance;
  UserService._internal();

  static const String baseUrl = 'https://sbz5mzdtp6.execute-api.us-east-1.amazonaws.com/prod';
  static const String testUserId = 'usuario-123'; // Valor fijo para X-Test-User-Id

  final List<User> _users = [];
  bool _isLoaded = false;

  List<User> get users => List.from(_users);

  User get currentUser {
    try {
      return _users.firstWhere((user) => user.isCurrentUser);
    } catch (e) {
      // Si no hay usuario actual, crear uno por defecto
      final defaultUser = User(
        id: 'current',
        name: 'Usuario Actual',
        color: Colors.blue,
        isCurrentUser: true,
      );
      _users.insert(0, defaultUser);
      return defaultUser;
    }
  }

  Future<void> loadFriends({String? userId}) async {
    try {
      final headers = await ApiHeadersHelper.getAuthHeaders();

      print('🔍 Cargando friends:');
      print('  - URL: $baseUrl/friends');
      print('  - Header X-Test-User-Id: $testUserId');
      
      final response = await http.get(
        Uri.parse('$baseUrl/friends'),
        headers: headers
      );

      print('📥 Respuesta del backend:');
      print('  - Status: ${response.statusCode}');
      print('  - Body: ${response.body}');

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        print('  - Decoded type: ${decoded.runtimeType}');
        print('  - Decoded keys: ${decoded is Map ? (decoded as Map).keys.toList() : 'N/A'}');
        
        // Manejar si el backend devuelve un objeto con wrapper o array directo
        // El backend devuelve: {"items": [...], "count": X, ...}
        List<dynamic> friendsJson = [];
        if (decoded is List) {
          friendsJson = decoded;
          print('  - Es un array directo');
        } else if (decoded is Map) {
          print('  - Buscando en items: ${decoded['items']}');
          print('  - Buscando en data: ${decoded['data']}');
          print('  - Buscando en friends: ${decoded['friends']}');
          friendsJson = decoded['items'] ?? decoded['data'] ?? decoded['friends'] ?? [];
        }
        
        print('  - Friends encontrados: ${friendsJson.length}');
        if (friendsJson.isNotEmpty) {
          print('  - Primer friend: ${friendsJson[0]}');
        }
        
        final List<User> friends = friendsJson
            .map((json) {
              try {
                return User.fromJson(json as Map<String, dynamic>);
              } catch (e) {
                print('  - ❌ Error parseando friend: $json - $e');
                return null;
              }
            })
            .where((user) => user != null)
            .cast<User>()
            .toList();
        
        print('  - Friends parseados exitosamente: ${friends.length}');
        
        // Mantener el usuario actual si existe
        final currentUsers = _users.where((u) => u.isCurrentUser).toList();
        _users.clear();
        _users.addAll(currentUsers);
        _users.addAll(friends);
        _isLoaded = true;
        
        print('✅ Friends cargados: ${_users.length} usuarios totales (${friends.length} friends + ${currentUsers.length} current)');
      } else {
        print('❌ Failed to load friends: ${response.statusCode}');
        if (!_isLoaded) {
          // Solo usar datos por defecto si nunca se cargaron
          _initializeDefaultUsers();
        }
      }
    } catch (e, stackTrace) {
      print('❌ Error loading friends: $e');
      print('Stack trace: $stackTrace');
      if (!_isLoaded) {
        // Solo usar datos por defecto si nunca se cargaron
        _initializeDefaultUsers();
      }
    }
  }

  void _initializeDefaultUsers() {
    if (_users.isEmpty) {
      _users.addAll([
        User(
          id: 'current',
          name: 'Usuario Actual',
          color: Colors.blue,
          isCurrentUser: true,
        ),
      ]);
    }
  }

  Future<User> addUser(User user) async {
    try {
      final headers = await ApiHeadersHelper.getAuthHeaders();


      // Preparar los datos para el endpoint
      final requestBody = {
        'name': user.name,
        'email': user.email ?? '',
        'color': user.color.value,
      };

      print('💾 Guardando friend:');
      print('  - Name: ${user.name}');
      print('  - Header X-Test-User-Id: $testUserId');
      print('  - Body: ${jsonEncode(requestBody)}');

      final response = await http.post(
        Uri.parse('$baseUrl/friends'),
        headers: headers,
        body: jsonEncode(requestBody),
      );

      print('📥 Respuesta del backend:');
      print('  - Status: ${response.statusCode}');
      print('  - Body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        // Si el servidor devuelve el usuario creado, usar esos datos
        final decoded = jsonDecode(response.body);
        // Manejar si viene como objeto directo o dentro de un wrapper
        final responseData = decoded is Map ? decoded : (decoded['data'] ?? decoded['friend'] ?? decoded);
        final savedUser = User.fromJson(responseData as Map<String, dynamic>);
        
        // Agregar a la lista local
        _users.add(savedUser);
        
        // Recargar la lista completa desde el servidor para mantener sincronización
        await loadFriends();
        
        print('✅ Friend guardado exitosamente');
        return savedUser;
      } else {
        throw Exception('Failed to save friend: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('❌ Error saving friend: $e');
      rethrow;
    }
  }

  void removeUser(String userId) {
    _users.removeWhere((user) => user.id == userId);
  }

  User? getUserById(String userId) {
    try {
      return _users.firstWhere((user) => user.id == userId);
    } catch (e) {
      return null;
    }
  }

  List<User> searchUsers(String query) {
    if (query.isEmpty) return _users;
    return _users
        .where((user) => user.name.toLowerCase().contains(query.toLowerCase()))
        .toList();
  }
}

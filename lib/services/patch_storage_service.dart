import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/patch.dart';
import 'api_headers_helper.dart';
import 'user_service.dart';

class PatchStorageService {
  static const String baseUrl = 'https://sbz5mzdtp6.execute-api.us-east-1.amazonaws.com/prod';
  static const String testUserId = 'usuario-123'; // Valor fijo para X-Test-User-Id
  final UserService _userService = UserService();

  PatchStorageService();

  Future<List<Patch>> getPatches({String? userId}) async {
    try {
      final headers = await ApiHeadersHelper.getAuthHeaders();

      final response = await http.get(
        Uri.parse('$baseUrl/parches'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        
        // Manejar si el backend devuelve un objeto con wrapper o array directo
        // El backend devuelve: {"items": [...], "count": X, ...}
        final List<dynamic> patchesJson = decoded is List 
            ? decoded 
            : (decoded['items'] ?? decoded['data'] ?? decoded['patches'] ?? decoded['parches'] ?? []);
        
        final List<Patch> patches = [];
        for (var json in patchesJson) {
          try {
            final patch = Patch.fromJson(json as Map<String, dynamic>);
            patches.add(patch);
          } catch (e) {
            // Error parseando parche, continuar con el siguiente
          }
        }
        
        return patches;
      } else {
        return [];
      }
    } catch (e) {
      return [];
    }
  }

  Future<String> savePatch(Patch patch, {String? userId}) async {
    try {
      final headers = await ApiHeadersHelper.getAuthHeaders();

      print('💾 Guardando parche:');
      print('  - Nombre: ${patch.name}');
      print('  - Miembros: ${patch.memberIds}');
      print('  - Header X-Test-User-Id: $testUserId');
      
      final response = await http.post(
        Uri.parse('$baseUrl/parches'),
        headers: headers,
        body: jsonEncode(patch.toJson(includeId: false)),
      );

      print('📥 Respuesta del backend:');
      print('  - Status: ${response.statusCode}');
      print('  - Body: ${response.body}');

      if (response.statusCode != 200 && response.statusCode != 201) {
        throw Exception('Failed to save patch: ${response.statusCode} - ${response.body}');
      }
      
      // Extraer el ID del parche creado
      final decoded = jsonDecode(response.body);
      final parcheId = decoded is Map 
          ? (decoded['id'] as String? ?? '') 
          : '';
      
      if (parcheId.isEmpty) {
        throw Exception('El backend no devolvió un ID válido para el parche');
      }
      
      print('✅ Parche guardado exitosamente con ID: $parcheId');
      return parcheId;
    } catch (e) {
      print('❌ Error saving patch: $e');
      rethrow;
    }
  }

  Future<void> deletePatch(String id, {String? userId}) async {
    try {
      final headers = await ApiHeadersHelper.getAuthHeaders();

      final response = await http.delete(
        Uri.parse('$baseUrl/parches/$id'),
        headers: headers,
      );

      if (response.statusCode != 200 && response.statusCode != 204) {
        throw Exception('Failed to delete patch: ${response.statusCode}');
      }
    } catch (e) {
      print('Error deleting patch: $e');
      rethrow;
    }
  }

  /// Obtiene un parche específico por ID
  /// Si el endpoint GET /parches/{id} no está disponible, busca en la lista de parches
  Future<Patch?> getPatchById(String id, {String? userId}) async {
    try {
      final headers = await ApiHeadersHelper.getAuthHeaders();

      print('🔍 Obteniendo parche por ID:');
      print('  - Parche ID: $id');
      
      final response = await http.get(
        Uri.parse('$baseUrl/parches/$id'),
        headers: headers,
      );

      print('📥 Respuesta del backend:');
      print('  - Status: ${response.statusCode}');
      print('  - Body: ${response.body}');

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        final patchJson = decoded is Map ? decoded : (decoded['data'] ?? decoded['patch'] ?? decoded);
        return Patch.fromJson(patchJson as Map<String, dynamic>);
      } else if (response.statusCode == 405) {
        // El endpoint no está implementado, usar fallback: buscar en la lista
        print('⚠️ Endpoint GET /parches/{id} no disponible (405). Buscando en lista de parches...');
        return await _getPatchByIdFromList(id);
      } else {
        print('❌ Failed to get patch: ${response.statusCode}');
        // Intentar fallback antes de retornar null
        return await _getPatchByIdFromList(id);
      }
    } catch (e) {
      print('❌ Error getting patch: $e');
      // Intentar fallback antes de retornar null
      return await _getPatchByIdFromList(id);
    }
  }

  /// Fallback: Obtiene el parche desde la lista de parches
  Future<Patch?> _getPatchByIdFromList(String id) async {
    try {
      print('🔄 Buscando parche en lista completa...');
      final patches = await getPatches();
      final patch = patches.firstWhere(
        (p) => p.id == id,
        orElse: () => throw Exception('Parche no encontrado'),
      );
      print('✅ Parche encontrado en lista: ${patch.name}');
      return patch;
    } catch (e) {
      print('❌ Parche no encontrado en lista: $e');
      return null;
    }
  }

  /// Actualiza un parche existente
  Future<void> updatePatch(Patch patch, {String? userId}) async {
    try {
      final headers = await ApiHeadersHelper.getAuthHeaders();

      print('💾 Actualizando parche:');
      print('  - ID: ${patch.id}');
      print('  - Nombre: ${patch.name}');
      print('  - Miembros: ${patch.memberIds}');
      
      final response = await http.put(
        Uri.parse('$baseUrl/parches/${patch.id}'),
        headers: headers,
        body: jsonEncode(patch.toJson(includeId: false)),
      );

      print('📥 Respuesta del backend:');
      print('  - Status: ${response.statusCode}');
      print('  - Body: ${response.body}');

      if (response.statusCode != 200 && response.statusCode != 204) {
        throw Exception('Failed to update patch: ${response.statusCode} - ${response.body}');
      }
      
      print('✅ Parche actualizado exitosamente');
    } catch (e) {
      print('❌ Error updating patch: $e');
      rethrow;
    }
  }
}

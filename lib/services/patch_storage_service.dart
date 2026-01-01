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
}

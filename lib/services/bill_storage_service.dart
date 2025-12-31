import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/saved_bill.dart';
import '../models/bill_item.dart';
import 'api_headers_helper.dart';
import 'user_service.dart';

class BillStorageService {
  static const String baseUrl = 'https://sbz5mzdtp6.execute-api.us-east-1.amazonaws.com/prod';
  // Ya no se usa X-Test-User-Id, ahora se usa Access Token de Cognito
  final UserService _userService = UserService();

  BillStorageService();

  Future<List<SavedBill>> getSavedBills({String? userId}) async {
    try {
      // Usar Access Token de Cognito en lugar de X-Test-User-Id
      final headers = await ApiHeadersHelper.getAuthHeaders();
      
      final response = await http.get(
        Uri.parse('$baseUrl/bills'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        // Manejar si el backend devuelve un objeto con wrapper o array directo
        final List<dynamic> billsJson = decoded is List 
            ? decoded 
            : (decoded['data'] ?? decoded['bills'] ?? decoded['items'] ?? []);
        return billsJson.map((json) => SavedBill.fromJson(json)).toList();
      } else {
        print('Failed to load bills: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      print('Error loading bills: $e');
      return [];
    }
  }

  Future<String> saveBill(SavedBill bill, {String? userId, bool isNewBill = true}) async {
    try {
      // Para bills nuevos, no enviar el ID ni el name (el backend los maneja)
      // El backend espera: parche_id, date, total, items, taxes
      final requestBody = bill.toJson(includeId: false, includeName: false);
      
      print('💾 Guardando bill (POST):');
      print('  - Es nuevo bill: $isNewBill');
      print('  - Body: ${jsonEncode(requestBody)}');
      
      // Usar Access Token de Cognito en lugar de X-Test-User-Id
      final headers = await ApiHeadersHelper.getAuthHeaders();
      
      final response = await http.post(
        Uri.parse('$baseUrl/bills'),
        headers: headers,
        body: jsonEncode(requestBody),
      );

      print('📥 Respuesta del backend:');
      print('  - Status: ${response.statusCode}');
      print('  - Body: ${response.body}');

      if (response.statusCode != 200 && response.statusCode != 201) {
        throw Exception('Failed to save bill: ${response.statusCode} - ${response.body}');
      }
      
      // El backend devuelve el ID generado
      final decoded = jsonDecode(response.body);
      final savedBillId = decoded is Map 
          ? (decoded['id'] as String? ?? '')
          : '';
      
      if (savedBillId.isEmpty) {
        throw Exception('Backend no devolvió un ID válido');
      }
      
      print('✅ Bill guardado exitosamente con ID: $savedBillId');
      return savedBillId;
    } catch (e) {
      print('❌ Error saving bill: $e');
      rethrow;
    }
  }

  /// Actualiza un bill completo
  /// Solo los miembros del patch asociado pueden editar
  /// El backend espera: date, total, items (con participants), taxes
  Future<void> updateBill(SavedBill bill, {String? userId}) async {
    try {
      // Para UPDATE, enviar todos los campos excepto el ID (va en la URL)
      // El backend espera: date, total, items, taxes (no requiere name ni parche_id en el body)
      final requestBody = bill.toJson(includeId: false, includeName: false);
      
      print('💾 Actualizando bill (PUT):');
      print('  - Bill ID: ${bill.id}');
      print('  - Body: ${jsonEncode(requestBody)}');
      
      final headers = await ApiHeadersHelper.getAuthHeaders();
      
      final response = await http.put(
        Uri.parse('$baseUrl/bills/${bill.id}'),
        headers: headers,
        body: jsonEncode(requestBody),
      );

      print('📥 Respuesta del backend:');
      print('  - Status: ${response.statusCode}');
      print('  - Body: ${response.body}');

      if (response.statusCode != 200 && response.statusCode != 204) {
        throw Exception('Failed to update bill: ${response.statusCode} - ${response.body}');
      }
      
      print('✅ Bill actualizado exitosamente');
    } catch (e) {
      print('❌ Error updating bill: $e');
      rethrow;
    }
  }

  /// Actualiza un item específico dentro de un bill
  /// Útil para edición colaborativa donde solo se modifica un item
  Future<void> updateBillItem(String billId, BillItem item, {String? userId}) async {
    try {
      final headers = await ApiHeadersHelper.getAuthHeaders();
      
      final response = await http.put(
        Uri.parse('$baseUrl/bills/$billId/items/${item.id}'),
        headers: headers,
        body: jsonEncode(item.toJson()),
      );

      if (response.statusCode != 200 && response.statusCode != 204) {
        throw Exception('Failed to update bill item: ${response.statusCode}');
      }
    } catch (e) {
      print('Error updating bill item: $e');
      rethrow;
    }
  }

  /// Obtiene un bill específico por ID
  /// Retry con delay si no se encuentra (para manejar eventual consistency)
  Future<SavedBill?> getBillById(String id, {String? userId, int retries = 3}) async {
    for (int attempt = 1; attempt <= retries; attempt++) {
      try {
        print('🔍 Buscando bill (intento $attempt/$retries):');
        print('  - Bill ID: $id');
        
        final headers = await ApiHeadersHelper.getAuthHeaders();
        
        final response = await http.get(
          Uri.parse('$baseUrl/bills/$id'),
          headers: headers,
        );

        print('📥 Respuesta del backend:');
        print('  - Status: ${response.statusCode}');
        print('  - Body: ${response.body}');

        if (response.statusCode == 200) {
          final decoded = jsonDecode(response.body);
          // Manejar si viene como objeto directo o dentro de un wrapper
          final billJson = decoded is Map ? decoded : (decoded['data'] ?? decoded['bill'] ?? decoded);
          return SavedBill.fromJson(billJson as Map<String, dynamic>);
        } else if (response.statusCode == 404 && attempt < retries) {
          // Si es 404 y hay más intentos, esperar un poco y reintentar
          print('  - ⏳ Bill no encontrado, esperando antes de reintentar...');
          await Future.delayed(Duration(milliseconds: 500 * attempt));
          continue;
        } else {
          print('❌ Failed to load bill: ${response.statusCode}');
          return null;
        }
      } catch (e) {
        if (attempt < retries) {
          print('  - ⚠️ Error en intento $attempt, reintentando...');
          await Future.delayed(Duration(milliseconds: 500 * attempt));
          continue;
        } else {
          print('❌ Error loading bill después de $retries intentos: $e');
          return null;
        }
      }
    }
    return null;
  }

  Future<void> deleteBill(String id, {String? userId}) async {
    try {
      final headers = await ApiHeadersHelper.getAuthHeaders();
      
      final response = await http.delete(
        Uri.parse('$baseUrl/bills/$id'),
        headers: headers,
      );

      if (response.statusCode != 200 && response.statusCode != 204) {
        throw Exception('Failed to delete bill: ${response.statusCode}');
      }
    } catch (e) {
      print('Error deleting bill: $e');
      rethrow;
    }
  }
}

import 'dart:io';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:uuid/uuid.dart';
import 'api_headers_helper.dart';
import 'user_service.dart';

class ReceiptService {
  // https://xqj1m2m881.execute-api.us-east-1.amazonaws.com/prod
  static const String baseUrl = 'https://sbz5mzdtp6.execute-api.us-east-1.amazonaws.com/prod';
  static const String testUserId = 'usuario-123'; // Valor fijo para X-Test-User-Id
  static const _uuid = Uuid();
  final UserService _userService = UserService();

  /// Genera un nombre único para el archivo usando UUID y mantiene la extensión original
  String _generateUniqueFilename(String? originalFilename) {
    // Obtener la extensión del archivo original
    String extension = 'jpg'; // Por defecto
    if (originalFilename != null && originalFilename.isNotEmpty) {
      final parts = originalFilename.toLowerCase().split('.');
      if (parts.length > 1) {
        extension = parts.last;
        // Validar que la extensión sea válida
        if (!['jpg', 'jpeg', 'png', 'gif', 'webp'].contains(extension)) {
          extension = 'jpg';
        }
      }
    }
    
    // Generar UUID y crear nombre único
    final uniqueId = _uuid.v4();
    return 'receipt_$uniqueId.$extension';
  }

  /// Obtiene el tipo de contenido basado en la extensión del archivo
  String _getContentType(String filename) {
    final extension = filename.toLowerCase().split('.').last;
    switch (extension) {
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'gif':
        return 'image/gif';
      case 'webp':
        return 'image/webp';
      default:
        return 'image/jpeg';
    }
  }

  /// Paso 1: Obtiene una URL pre-firmada para subir el archivo a S3
  Future<Map<String, dynamic>> _getPresignedUrl(
      String filename, String contentType) async {
    try {

      final headers = await ApiHeadersHelper.getAuthHeaders();

      print('Obteniendo URL pre-firmada para: $filename');

      final response = await http.post(
        Uri.parse('$baseUrl/generate-presigned-url'),
        headers: headers,
        body: json.encode({
          'filename': filename,
          'content_type': contentType,
        }),
      );

      print('Respuesta URL pre-firmada: ${response.statusCode}');
      print('Datos: ${response.body}');

      if (response.statusCode == 200) {
        return Map<String, dynamic>.from(
          json.decode(response.body) as Map,
        );
      } else {
        throw Exception(
            'Error al obtener URL pre-firmada: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('Error al obtener URL pre-firmada: $e');
      rethrow;
    }
  }

  /// Paso 2: Sube el archivo a S3 usando la URL pre-firmada
  Future<void> _uploadToS3(String uploadUrl, dynamic file, String contentType) async {
    try {
      print('Subiendo archivo a S3...');

      List<int> fileBytes;
      if (kIsWeb) {
        // Para web, el archivo es un Uint8List
        fileBytes = file as List<int>;
      } else {
        // Para móvil/desktop, el archivo es un File
        fileBytes = await (file as File).readAsBytes();
      }

      final response = await http.put(
        Uri.parse(uploadUrl),
        headers: {
          'Content-Type': contentType,
        },
        body: fileBytes,
      );

      print('Respuesta subida S3: ${response.statusCode}');
      print('Headers de respuesta S3: ${response.headers}');
      if (response.body.isNotEmpty) {
        print('Body de respuesta S3: ${response.body}');
      }

      // S3 puede devolver 200 o 204 para subidas exitosas
      if (response.statusCode != 200 && response.statusCode != 204) {
        throw Exception(
            'Error al subir archivo a S3: ${response.statusCode} - ${response.body}');
      }

      print('Archivo subido exitosamente a S3');
      print('URL de subida utilizada: $uploadUrl');
    } catch (e) {
      print('Error al subir a S3: $e');
      rethrow;
    }
  }

  /// Paso 3: Procesa el recibo usando el nombre del archivo (el mismo que se usó para subir)
  Future<Map<String, dynamic>> _processReceipt(String filename, {String? currency, String? s3Url}) async {
    try {
      print('Procesando recibo con filename: $filename');
      print('⚠️ IMPORTANTE: El filename debe coincidir exactamente con la key de S3');

      // Construir el request body con filename y campos opcionales
      final requestBody = <String, dynamic>{
        'filename': filename,
      };
      
      // Agregar currency si está presente
      if (currency != null && currency.isNotEmpty) {
        requestBody['currency'] = currency;
      }
      
      // Agregar s3_url si está presente
      if (s3Url != null && s3Url.isNotEmpty) {
        requestBody['s3_url'] = s3Url;
      }

      print('Enviando request a /process-receipt: ${json.encode(requestBody)}');

      final response = await http.post(
        Uri.parse('$baseUrl/process-receipt'),
        headers: {
          'Content-Type': 'application/json',
          'X-Test-User-Id': testUserId,
        },
        body: json.encode(requestBody),
      );

      print('Respuesta procesamiento: ${response.statusCode}');
      print('Datos de respuesta: ${response.body}');

      if (response.statusCode == 200) {
        return Map<String, dynamic>.from(
          json.decode(response.body) as Map,
        );
      } else {
        throw Exception(
            'Error al procesar el recibo: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('Error al procesar recibo: $e');
      rethrow;
    }
  }

  /// Método principal que orquesta todo el flujo: obtener URL, subir a S3 y procesar
  Future<Map<String, dynamic>> processReceipt(dynamic file, {String? filename, String? currency, String? s3Url}) async {
    try {
      print('Iniciando procesamiento de recibo...');

      // Generar un nombre único para el archivo (evita problemas con espacios y caracteres especiales)
      final originalFilename = filename ?? 
          (kIsWeb ? 'receipt.jpg' : (file as File).path.split('/').last);
      final finalFilename = _generateUniqueFilename(originalFilename);
      
      print('Nombre original: $originalFilename');
      print('Nombre único generado: $finalFilename');

      // Determinar content type basado en el nombre único generado
      final contentType = _getContentType(finalFilename);

      // Paso 1: Obtener URL pre-firmada usando el filename generado
      print('⚠️ Paso 1: Obteniendo URL pre-firmada para filename: $finalFilename');
      final presignedUrlData = await _getPresignedUrl(finalFilename, contentType);
      final uploadUrl = presignedUrlData['upload_url'] as String;
      
      print('Datos recibidos de presigned URL: $presignedUrlData');

      if (uploadUrl == null || uploadUrl.isEmpty) {
        throw Exception('No se recibió una URL de subida válida');
      }
      
      print('URL de subida obtenida: $uploadUrl');
      print('⚠️ El filename usado en este paso es: $finalFilename');

      // Paso 2: Subir archivo a S3
      print('⚠️ Subiendo archivo a S3 con filename: $finalFilename');
      await _uploadToS3(uploadUrl, file, contentType);
      
      print('Esperando un momento para que S3 propague el archivo...');
      // Pequeña pausa para asegurar que S3 haya procesado el archivo
      await Future.delayed(const Duration(milliseconds: 1000));

      // Paso 3: Procesar el recibo usando el MISMO filename que se usó en los pasos anteriores
      print('⚠️ Llamando a /process-receipt con filename: $finalFilename');
      print('⚠️ Este filename DEBE coincidir exactamente con la key de S3');
      final result = await _processReceipt(finalFilename, currency: currency, s3Url: s3Url);

      print('Procesamiento completado exitosamente');
      return result;
    } catch (e, stackTrace) {
      print('Error completo: $e');
      print('Stack trace: $stackTrace');
      throw Exception('Error al procesar el recibo: $e');
    }
  }
}

import 'dart:convert';
import 'package:amplify_auth_cognito/amplify_auth_cognito.dart';
import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:flutter/foundation.dart';

// https://github.com/Bhalani/Flutter-Amplify/blob/d37bda2e1f2257ade7130037c6af7bcdcbfb0305/lib/router/app_router.dart#L41

// https://github.com/nottmey/climate-platform-ui/blob/33e9936c5d65186b2026f5502a56b78b9ac9cf85/lib/features/profile/pages/profile_page.dart#L55

/// Helper para obtener headers de autenticación para llamadas a la API
class ApiHeadersHelper {
  // User ID de prueba para desarrollo/local cuando no hay token
  static const String testUserId = 'usuario-123';

  /// Obtiene los headers con el Access Token de Cognito
  ///
  /// Flujo:
  /// 1. Intenta obtener el Access Token de Cognito (si el usuario está logueado)
  /// 2. Si hay token → usa Authorization: Bearer {accessToken}
  /// 3. Si NO hay token (debug/local) → usa X-Test-User-Id: usuario-123
  ///
  /// El Access Token se envía en el header Authorization: Bearer {accessToken}
  /// Este es el token que el backend valida con el Cognito User Pool Authorizer
  ///
  /// 💡 DEBUG: Puedes poner breakpoints aquí para inspeccionar:
  ///    - result.isSignedIn: estado de autenticación
  ///    - accessToken: el token JWT completo
  ///    - headers: los headers finales que se enviarán
  static Future<Map<String, String>> getAuthHeaders() async {

    safePrint('🔐 [DEBUG] Provider: Headers');

    final headers = <String, String>{
      'Content-Type': 'application/json',
    };

    try {
      // 1. Obtener la sesión de autenticación y tokens
      final result = await Amplify.Auth.fetchAuthSession() as CognitoAuthSession;
      
      // 2. Verificar si el usuario está autenticado
      if (result.isSignedIn) {
        // 3. Obtener el Access Token directamente
        final accessToken = result.userPoolTokensResult.value.idToken.raw;


        if (accessToken.isNotEmpty) {
          // ✅ Usuario logueado: usar Access Token
          // IMPORTANTE: El formato debe ser "Bearer {token}" con espacio
          headers['Authorization'] = 'Bearer $accessToken';
          if (kDebugMode) {
            print('✅ [ApiHeadersHelper] Access Token agregado a headers');
            print('🔍 [ApiHeadersHelper] Header Authorization: Bearer ${accessToken.substring(0, accessToken.length > 20 ? 20 : accessToken.length)}...');
          }
          return headers;
        } else {
          if (kDebugMode) {
            print('⚠️ [ApiHeadersHelper] Access Token vacío');
          }
        }
      } else {
        if (kDebugMode) {
          print('⚠️ [ApiHeadersHelper] Usuario no autenticado (isSignedIn: false)');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('⚠️ [ApiHeadersHelper] Error obteniendo Access Token: $e');
      }
    }

    // 4. Fallback: usar X-Test-User-Id para debug/local
    headers['X-Test-User-Id'] = testUserId;
    if (kDebugMode) {
      print('🔧 [ApiHeadersHelper] Usando X-Test-User-Id (modo debug/local)');
    }

    return headers;
  }

  /// Obtiene headers básicos sin autenticación
  static Map<String, String> getBasicHeaders() {
    return {
      'Content-Type': 'application/json',
    };
  }
}

import 'package:amplify_auth_cognito/amplify_auth_cognito.dart';
import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:flutter/material.dart';
import 'package:parchando/screens/home_screen.dart';
import 'package:parchando/screens/presentation/pages/auth_screen.dart';


Future<bool> isUserSignedIn() async {
  final result = await Amplify.Auth.fetchAuthSession();
  return result.isSignedIn;
}

Future<AuthUser> getCurrentUser() async {
  final result = await Amplify.Auth.getCurrentUser();
  return result;
}

Future<void> signInWithWebUIProvider(BuildContext context) async {
  try {
    safePrint('🔐 [DEBUG] Iniciando signInWithWebUI...');
    safePrint('🔐 [DEBUG] Provider: Google');
    safePrint('🔐 [DEBUG] Context mounted: ${context.mounted}');
    
    // Punto de debug 1: Antes de llamar a signInWithWebUI
    // Coloca un breakpoint aquí para inspeccionar el estado antes de la llamada
    
    final result = await Amplify.Auth.signInWithWebUI(
      provider: AuthProvider.google,
    );
    
    // Punto de debug 2: Después de recibir la respuesta
    // Coloca un breakpoint aquí para inspeccionar el resultado
    safePrint('🔐 [DEBUG] Resultado recibido:');
    safePrint('🔐 [DEBUG] - isSignedIn: ${result.isSignedIn}');
    safePrint('🔐 [DEBUG] - Tipo de resultado: ${result.runtimeType}');
    
    // Inspeccionar propiedades del resultado (si están disponibles)
    try {
      safePrint('🔐 [DEBUG] - Resultado completo: $result');
    } catch (e) {
      safePrint('🔐 [DEBUG] - No se pudo imprimir resultado completo');
    }
    
    if (result.isSignedIn) {
      safePrint('✅ [DEBUG] Usuario autenticado correctamente');
      
      if (!context.mounted) {
        safePrint('⚠️ [DEBUG] Context ya no está montado, abortando navegación');
        return;
      }
      
      safePrint('🔐 [DEBUG] Navegando a HomeScreen...');
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const HomeScreen()),
      );
      safePrint('✅ [DEBUG] Navegación completada');
    } else {
      safePrint('❌ [DEBUG] 로그인 실패: 사용자 인증 필요');
      safePrint('❌ [DEBUG] isSignedIn = false');
    }
  } on AuthException catch (e, stackTrace) {
    // Punto de debug 3: Captura de excepciones de autenticación
    safePrint('❌ [DEBUG] AuthException capturada:');
    safePrint('❌ [DEBUG] - Mensaje: ${e.message}');
    safePrint('❌ [DEBUG] - Recovery suggestion: ${e.recoverySuggestion}');
    safePrint('❌ [DEBUG] - Underlying exception: ${e.underlyingException}');
    safePrint('❌ [DEBUG] - Stack trace: $stackTrace');
    safePrint('로그인 중 오류 발생: ${e.message}');
  } catch (e, stackTrace) {
    // Punto de debug 4: Captura de excepciones generales
    safePrint('❌ [DEBUG] Excepción general capturada:');
    safePrint('❌ [DEBUG] - Tipo: ${e.runtimeType}');
    safePrint('❌ [DEBUG] - Mensaje: $e');
    safePrint('❌ [DEBUG] - Stack trace: $stackTrace');
    safePrint('로그인 중 오류 발생: $e');
  }
}

Future<void> signOutCurrentUser(BuildContext context) async {
  try {
    final result = await Amplify.Auth.signOut();
    if (result is CognitoCompleteSignOut) {
      safePrint('Sign out completed successfully');
      if (!context.mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => AuthScreen()),
      );
    } else if (result is CognitoFailedSignOut) {
      safePrint('로그아웃 실패: ${result.exception.message}');
    }
  } catch (e) {
    safePrint('로그아웃 중 오류 발생: ${e.toString()}');
  }
}

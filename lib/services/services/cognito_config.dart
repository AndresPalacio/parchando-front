import 'package:flutter/foundation.dart';

// Configuración para Cognito con Google Federation - Valores públicos hardcodeados
class CognitoConfig {
  // Google OAuth Configuration
  static const String googleClientId =
      '1075980020579-ld6bplahcfholgvf55jn79tq2b37f36f.apps.googleusercontent.com';

  // Cognito Configuration - Reemplaza con tus valores reales
  static const String userPoolId =
      'us-east-1_c6B9FNm3t'; // Reemplaza con tu User Pool ID
  static const String appClientId =
      'hu2asksok5oljjdqmop25gic0'; // Reemplaza con tu App Client ID
  static const String region = 'us-east-1';
  static const String domain =
      'parchando-prod'; // Reemplaza con tu dominio de Cognito

  // API Endpoint - Reemplaza con tu endpoint real
  static const String restApiEndpoint =
      'https://3lp396k7td.execute-api.us-east-1.amazonaws.com/prod/api';

  // URL fija para desarrollo web (debe estar registrada en Cognito)
  // Cambia este puerto si necesitas usar uno diferente
  // IMPORTANTE: Esta URL debe estar registrada en AWS Cognito como callback URL
  // NOTA: La barra final (/) es importante para que coincida con Cognito
  static const String webDevelopmentPort = '3000';
  //static String get webRedirectUri => 'http://localhost:$webDevelopmentPort/';
  //static String get webSignOutUri => 'http://localhost:$webDevelopmentPort/';

 static String get webRedirectUri => 'https://master.de15vlrxbzx0z.amplifyapp.com/';
 static String get webSignOutUri => 'https://master.de15vlrxbzx0z.amplifyapp.com/';


  // Redirect URI - Debe coincidir con la configurada en Google Console y Cognito
  // Para web: usa una URL fija para desarrollo (configurable arriba)
  // Para móvil: usa un custom scheme
  static String get redirectUri {
    if (kIsWeb) {
      return webRedirectUri;
    }
    return 'myapp://callback/';
  }
  
  // Custom URL Scheme (para AndroidManifest/Info.plist)
  static const String customUrlScheme = 'myapp';

  // Sign out URI
  static String get signoutUri {
    if (kIsWeb) {
      return webSignOutUri;
    }
    return 'myapp://signout/';
  }
}

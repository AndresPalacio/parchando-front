import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:amplify_auth_cognito/amplify_auth_cognito.dart';
import 'package:flutter/foundation.dart';
import 'cognito_config.dart';
import 'dart:convert';

class AppAmplifyConfig {
  static Future<void> configure() async {
    try {
      if (Amplify.isConfigured) {
        print('⚠️ Amplify ya está configurado.');
        return;
      }

      final authPlugin = AmplifyAuthCognito();
      await Amplify.addPlugin(authPlugin);

      // Obtener URLs de redirección según la plataforma
      String signInRedirectUri;
      String signOutRedirectUri;
      
      if (kIsWeb) {
        // Para web, usar una URL fija configurada en CognitoConfig
        // Esto evita problemas con puertos aleatorios en desarrollo
        signInRedirectUri = CognitoConfig.webRedirectUri;
        signOutRedirectUri = CognitoConfig.webSignOutUri;
      } else {
        // Para móvil, usar custom schemes
        signInRedirectUri = CognitoConfig.redirectUri;
        signOutRedirectUri = CognitoConfig.signoutUri;
      }

      // Configuración estructurada
      final amplifyConfig = {
        "UserAgent": "aws-amplify-cli/2.0",
        "Version": "1.0",
        "auth": {
          "plugins": {
            "awsCognitoAuthPlugin": {
              "UserAgent": "aws-amplify-cli/0.1.0",
              "Version": "0.1.0",
              "IdentityManager": {
                "Default": {}
              },
              "CognitoUserPool": {
                "Default": {
                  "PoolId": CognitoConfig.userPoolId,
                  "AppClientId": CognitoConfig.appClientId,
                  "Region": CognitoConfig.region
                }
              },
              "Auth": {
                "Default": {
                  "OAuth": {
                    "WebDomain": "${CognitoConfig.domain}.auth.${CognitoConfig.region}.amazoncognito.com",
                    "AppClientId": CognitoConfig.appClientId,
                    "SignInRedirectURI": signInRedirectUri,
                    "SignOutRedirectURI": signOutRedirectUri,
                    "Scopes": [
                      "email",
                      "openid"
                    ]
                  },
                  "authenticationFlowType": "USER_SRP_AUTH",
                  "socialProviders": ["GOOGLE"],
                  "usernameAttributes": ["EMAIL"],
                  "signupAttributes": ["EMAIL"],
                  "passwordProtectionSettings": {
                    "passwordPolicyMinLength": 8,
                    "passwordPolicyCharacters": []
                  },
                  "mfaConfiguration": "OFF",
                  "mfaTypes": ["SMS"],
                  "verificationMechanisms": ["EMAIL"]
                }
              }
            }
          }
        }
      };

      final configJson = jsonEncode(amplifyConfig);
      
      // Formatear JSON para mejor legibilidad
      final jsonEncoder = JsonEncoder.withIndent('  ');
      final formattedJson = jsonEncoder.convert(amplifyConfig);
      
      print('🔍 Configurando Amplify con JSON...');
      print('📍 Plataforma: ${kIsWeb ? "Web" : "Móvil"}');
      print('🔗 SignInRedirectURI: $signInRedirectUri');
      print('🔗 SignOutRedirectURI: $signOutRedirectUri');
      print('');
      print('📋 JSON de configuración completo:');
      print('─' * 80);
      print(formattedJson);
      print('─' * 80);
      print('');
      
      await Amplify.configure(configJson);
      
      print('✅ Amplify configurado correctamente');
      
    } catch (e) {
      print('❌ Error configurando Amplify: $e');
      rethrow;
    }
  }
}

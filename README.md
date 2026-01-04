# parchando

Parchando project

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.


https://dribbble.com/shots/24762215-Split-Bill-Mobile-App

## 🚀 Ejecutar la Aplicación

### Desarrollo Web (Puerto 3000)

La aplicación está configurada para ejecutarse siempre en el puerto **3000** para desarrollo web. Esto es importante porque:

- Las URLs de callback de Cognito están configuradas para `http://localhost:3000`
- El puerto está definido en `.flutter_config` y en los scripts de ejecución

#### Opción 1: Usar los scripts (Recomendado)

**Windows:**
```bash
run_web.bat
```

**Linux/Mac:**
```bash
./run_web.sh
```

#### Opción 2: Comando manual

```bash
flutter run -d chrome --web-port=3000
```

#### Opción 3: Debug en VS Code (Recomendado para desarrollo)

1. Abre VS Code en la raíz del proyecto
2. Ve a la pestaña "Run and Debug" (F5 o Ctrl+Shift+D)
3. Selecciona "Flutter Web (Puerto 3000)" del dropdown
4. Presiona F5 o haz clic en el botón de play ▶️
5. La app se abrirá en Chrome con el puerto 3000 y podrás usar breakpoints

**💡 Tip:** Puedes poner breakpoints en cualquier archivo Dart (como `api_headers_helper.dart`) y el debugger se detendrá ahí.

### Configuración del Puerto

El puerto 3000 está configurado en:
- `.flutter_config` - Archivo de configuración del proyecto
- `run_web.bat` / `run_web.sh` - Scripts de ejecución
- `.vscode/launch.json` - Configuración de debug para VS Code
- `.vscode/settings.json` - Configuración global de VS Code
- `lib/services/services/cognito_config.dart` - Configuración de Cognito

**⚠️ Importante:** No cambies el puerto sin actualizar también la configuración de Cognito en AWS.

# TODO

- [X] Add taxes to the bill
- [X] Add friends to the bill
- [ ] Add propina to the bill
- [ ] Add bill split summary
- [X] Add bill split details
- [ ] Verificar logueo en cada ruta que ingrese 
- [ ] Verificar que esta logueado al iniciar la app puede estar cubierta 
- [ ] Enviar el header cada que se logueo 
- [ ] Cambiar por la autenticacion de el cdk desplegado 
- [ ] Probar endpoint de logueo 

Para pruebas en local con debug
https://stackoverflow.com/questions/58248277/how-to-specify-a-port-number-while-running-flutter-web

# Detalles del usuario 

https://github.com/nottmey/climate-platform-ui/blob/33e9936c5d65186b2026f5502a56b78b9ac9cf85/lib/features/profile/pages/profile_page.dart#L55



https://stackoverflow.com/questions/58248277/how-to-specify-a-port-number-while-running-flutter-web



Otras referencias

https://github.com/pybsh/schedulist/blob/e0a5f486ff9c2a3e33f59ca3129427a6caf6a2d8/lib/amplifyconfiguration.dart#L1

https://github.com/KitaharaMugiro/englister/blob/9aa79dd621d746723aa4894f1648b283834027c4/lib/models/auth/AuthService.dart#L56
https://github.com/shinonome-inc/tokyo-flutter-hackathon-2025-team-PlayGround/blob/develop/app/lib/screens/sign_in/sign_in_screen.dart


https://us-east-1.console.aws.amazon.com/cognito/v2/idp/user-pools/us-east-1_wC8ztuiNR/applications/app-clients/hcfldrsfsmucnanf80oslkbdt/login-pages?region=us-east-1





Outputs:
ParchandoApiWithCognitoStack.CognitoDomain = parchando-prod
ParchandoApiWithCognitoStack.CognitoRegion = us-east-1
ParchandoApiWithCognitoStack.CognitoUserPoolClientId = hu2asksok5oljjdqmop25gic0
ParchandoApiWithCognitoStack.CognitoUserPoolId = us-east-1_c6B9FNm3t
ParchandoApiWithCognitoStack.ParchandoApiCognitoEndpoint677A28F5 = https://sbz5mzdtp6.execute-api.us-east-1.amazonaws.com/prod/
ParchandoApiWithCognitoStack.ParchandoApiUrlWithCognito = https://sbz5mzdtp6.execute-api.us-east-1.amazonaws.com/prod/
ParchandoApiWithCognitoStack.ParchandoLambdaFunctionNameWithCognito = ParchandoApiWithCognitoSt-ParchandoFastApiCognitoF-EI5Lm38HwEev
ParchandoApiWithCognitoStack.ParchandoTableNameWithCognito = parchando
ParchandoApiWithCognitoStack.ParchandoUploadsBucketNameWithCognito = parchando-uploads-9338-cognito


https://blog.flutter.dev/rich-and-dynamic-user-interfaces-with-flutter-and-generative-ui-178405af2455
debe de ser meroparche  


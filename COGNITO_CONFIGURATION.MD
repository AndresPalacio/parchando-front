# Configuración de AWS Cognito para Amplify

## 🔧 Configuración de OAuth Scopes

Este documento explica la configuración de OAuth scopes en Amplify y cómo se corrigió el error `invalid_scope`.

---

## ❌ Configuración Anterior (con error `invalid_scope`)

La configuración anterior incluía 4 scopes, pero solo 2 estaban habilitados en Cognito:

```dart
"OAuth": {
  "WebDomain": "${CognitoConfig.domain}.auth.${CognitoConfig.region}.amazoncognito.com",
  "AppClientId": CognitoConfig.appClientId,
  "SignInRedirectURI": signInRedirectUri,
  "SignOutRedirectURI": signOutRedirectUri,
  "Scopes": [
    "email",
    "openid",
    "profile",                          // ❌ Este scope causaba el error
    "aws.cognito.signin.user.admin"     // ❌ Este scope causaba el error
  ]
}
```

### Scopes incluidos (anterior):
- ✅ `email` - Habilitado en Cognito
- ✅ `openid` - Habilitado en Cognito
- ❌ `profile` - **NO habilitado en Cognito** (causaba error)
- ❌ `aws.cognito.signin.user.admin` - **NO habilitado en Cognito** (causaba error)

---

## ✅ Configuración Actual (corregida)

La configuración actual solo incluye los scopes que están habilitados en Cognito:

```dart
"OAuth": {
  "WebDomain": "${CognitoConfig.domain}.auth.${CognitoConfig.region}.amazoncognito.com",
  "AppClientId": CognitoConfig.appClientId,
  "SignInRedirectURI": signInRedirectUri,
  "SignOutRedirectURI": signOutRedirectUri,
  "Scopes": [
    "email",
    "openid"                            // ✅ Solo los scopes habilitados en Cognito
  ]
}
```

### Scopes incluidos (actual):
- ✅ `email` - Habilitado en Cognito
- ✅ `openid` - Habilitado en Cognito

---

## 📝 Explicación del Error

El error `invalid_scope` se debía a solicitar scopes que **no estaban habilitados** en tu App Client de Cognito.

### ¿Por qué ocurrió?

Cuando Amplify intenta autenticar con Cognito, envía una lista de scopes en la petición OAuth. Si alguno de esos scopes no está habilitado en la configuración del App Client en AWS Cognito, Cognito rechaza la petición con el error `invalid_scope`.

### Solución

La solución fue **remover los scopes no habilitados** (`profile` y `aws.cognito.signin.user.admin`) y mantener solo los que están configurados en Cognito (`email` y `openid`).

---

## 🔄 Si necesitas agregar más scopes

Si en el futuro necesitas usar los scopes `profile` o `aws.cognito.signin.user.admin`, debes:

1. Ir a **AWS Cognito Console**
2. Seleccionar tu **User Pool**: `us-east-1_wC8ztuiNR`
3. Ir a **App integration** → **App client settings**
4. Buscar tu **App Client**: `hcfldrsfsmucnanf80oslkbdt`
5. En la sección **"OpenID Connect scopes"**, habilitar los scopes que necesites:
   - `profile`
   - `aws.cognito.signin.user.admin`
6. Guardar los cambios
7. Actualizar el código para incluir esos scopes en el array `"Scopes"`

---

## 📍 Ubicación del código

La configuración se encuentra en:
- **Archivo**: `lib/services/services/amplify_config.dart`
- **Líneas**: 54-63 (sección OAuth)

---

## ✅ Estado actual

- ✅ Configuración corregida
- ✅ Solo scopes habilitados en Cognito
- ✅ Error `invalid_scope` resuelto
- ✅ Autenticación funcionando correctamente

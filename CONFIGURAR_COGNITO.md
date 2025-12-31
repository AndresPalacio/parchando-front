# 🔧 Guía: Configurar URLs de Redirección en AWS Cognito

## ❌ Problema Actual

El error que estás viendo:
```
No sign in redirect URLs registered for base URL: http://localhost:3000/
```

Significa que **la URL `http://localhost:3000` NO está registrada en AWS Cognito**.

## ✅ Solución: Registrar la URL en AWS Cognito

### Paso 1: Acceder a AWS Cognito Console

1. Ve a [AWS Console](https://console.aws.amazon.com/)
2. Busca "Cognito" en el buscador de servicios
3. Haz clic en "Cognito"

### Paso 2: Seleccionar tu User Pool

1. En el menú lateral, haz clic en **"User pools"**
2. Busca y haz clic en tu User Pool: **`us-east-1_wC8ztuiNR`**

### Paso 3: Ir a App Integration

1. En el menú lateral del User Pool, haz clic en **"App integration"**
2. Desplázate hacia abajo hasta la sección **"App client list"**

### Paso 4: Configurar el App Client

1. Busca tu App Client: **`hcfldrsfsmucnanf80oslkbdt`**
2. Haz clic en el **ID del App Client** (no en el nombre, sino en el ID)
3. Esto te llevará a la página de configuración del App Client

### Paso 5: Configurar Hosted UI

1. Desplázate hasta la sección **"Hosted UI"** o **"OAuth 2.0 settings"**
2. Busca el campo **"Allowed callback URLs"**
3. Agrega la siguiente URL (una por línea o separadas por comas):
   ```
   http://localhost:3000
   ```
4. Busca el campo **"Allowed sign-out URLs"**
5. Agrega la misma URL:
   ```
   http://localhost:3000
   ```

### Paso 6: Guardar Cambios

1. Haz clic en **"Save changes"** o **"Guardar cambios"**
2. Espera a que se confirme que los cambios se guardaron

### Paso 7: Verificar Configuración

Asegúrate de que también esté configurado:
- **OAuth 2.0 grant types**: Debe incluir "Authorization code grant"
- **OpenID Connect scopes**: Debe incluir "openid", "email", "profile"
- **Identity providers**: Debe tener "Google" habilitado

## 📝 URLs que debes agregar

En **"Allowed callback URLs"**:
```
http://localhost:3000
```

En **"Allowed sign-out URLs"**:
```
http://localhost:3000
```

## ⚠️ Notas Importantes

1. **NO agregues la barra final** (`/`) en las URLs de Cognito, a menos que tu código también la use
2. **Espera unos segundos** después de guardar para que los cambios se propaguen
3. **Reinicia tu aplicación Flutter** después de hacer los cambios en Cognito

## 🔍 Verificación

Después de configurar, cuando ejecutes tu app, deberías ver en la consola:
```
🌐 Usando URL fija para desarrollo web: http://localhost:3000
🔗 SignInRedirectURI: http://localhost:3000
🔗 SignOutRedirectURI: http://localhost:3000
✅ Amplify configurado correctamente
```

Y **NO** deberías ver el error de "No sign in redirect URLs registered".

## 🚀 Ejecutar la App

Asegúrate de ejecutar siempre con el puerto 3000:
```bash
flutter run -d chrome --web-port=3000
```

O usa los scripts creados:
- Windows: `run_web.bat`
- Linux/Mac: `./run_web.sh`


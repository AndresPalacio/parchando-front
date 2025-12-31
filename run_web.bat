@echo off
REM Script para ejecutar Flutter Web en el puerto 3000
REM El puerto 3000 está configurado en .flutter_config

echo ========================================
echo   Parchando App - Flutter Web
echo   Puerto: 3000
echo ========================================
echo.

REM Verificar que Flutter esté instalado
where flutter >nul 2>&1
if %ERRORLEVEL% NEQ 0 (
    echo ERROR: Flutter no está instalado o no está en el PATH
    pause
    exit /b 1
)

echo Iniciando Flutter en Chrome con puerto 3000...
echo.
flutter run -d chrome --web-port=3000

if %ERRORLEVEL% NEQ 0 (
    echo.
    echo ERROR: No se pudo iniciar la aplicación
    pause
)


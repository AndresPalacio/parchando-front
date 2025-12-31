#!/bin/bash
# Script para ejecutar Flutter Web en el puerto 3000
# El puerto 3000 está configurado en .flutter_config

echo "========================================"
echo "  Parchando App - Flutter Web"
echo "  Puerto: 3000"
echo "========================================"
echo ""

# Verificar que Flutter esté instalado
if ! command -v flutter &> /dev/null; then
    echo "ERROR: Flutter no está instalado o no está en el PATH"
    exit 1
fi

echo "Iniciando Flutter en Chrome con puerto 3000..."
echo ""

flutter run -d chrome --web-port=3000

if [ $? -ne 0 ]; then
    echo ""
    echo "ERROR: No se pudo iniciar la aplicación"
    exit 1
fi


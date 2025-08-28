#!/bin/bash

# Script para probar la aplicación Flask con Gunicorn
echo "🚀 Iniciando pruebas de la aplicación Nemesix..."

# Activar entorno virtual
source venv/bin/activate

# Función para limpiar procesos
cleanup() {
    echo "🧹 Limpiando procesos..."
    pkill -f gunicorn
    sleep 2
}

# Limpiar al salir
trap cleanup EXIT

echo "📦 Iniciando Gunicorn..."
gunicorn --bind 0.0.0.0:8080 --workers 2 app:app &
GUNICORN_PID=$!

echo "⏳ Esperando que Gunicorn inicie..."
sleep 5

echo "🔍 Probando endpoint de health..."
curl -X GET http://127.0.0.1:8080/health -v

echo ""
echo "🔍 Probando endpoint principal..."
curl -X GET http://127.0.0.1:8080/ -v

echo ""
echo "🔍 Probando endpoint de login (GET)..."
curl -X GET http://127.0.0.1:8080/login -v

echo ""
echo "✅ Pruebas completadas!"

# Matar Gunicorn
kill $GUNICORN_PID

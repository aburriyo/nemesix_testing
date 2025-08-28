#!/bin/bash

# Script de inicio para Nemesix en producción
# Asegúrate de tener permisos de ejecución: chmod +x start.sh

echo "🚀 Iniciando Nemesix..."

# Verificar si existe el entorno virtual
if [ ! -d ".venv" ]; then
    echo "📦 Creando entorno virtual..."
    python3 -m venv .venv
fi

# Activar entorno virtual
echo "🔧 Activando entorno virtual..."
source .venv/bin/activate

# Instalar dependencias
echo "📚 Instalando dependencias..."
pip install -r requirements.txt

# Crear directorios necesarios
echo "📁 Creando directorios..."
mkdir -p database
mkdir -p logs

# Configurar permisos
echo "🔒 Configurando permisos..."
chmod 755 .
chmod 644 database/
chmod 644 logs/

# Verificar que la base de datos existe
if [ ! -f "database/nemesix_db.db" ]; then
    echo "🗄️ Inicializando base de datos..."
    python3 -c "from models.user import User; print('Base de datos inicializada')"
fi

# Iniciar la aplicación con Gunicorn
echo "🌐 Iniciando servidor con Gunicorn..."
gunicorn --config gunicorn_config.py app:app

echo "✅ Nemesix iniciado correctamente"

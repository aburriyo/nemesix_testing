# 🚀 Guía de Despliegue - Nemesix

## 📋 Flujo de Trabajo para Actualizaciones

### 🔄 **Actualización Local (Desarrollo)**

```bash
# 1. Hacer cambios en el código
# 2. Probar localmente
./test_app.sh

# 3. Commitear cambios
git add .
git commit -m "Descripción de cambios"

# 4. Subir a repositorio
git push origin main

# 5. Actualizar servidor local
./update_server.sh
```

### 🌐 **Despliegue en Producción (Ubuntu Server)**

```bash
# Conectar al servidor
ssh user@tu-servidor

# Ir al directorio del proyecto
cd /ruta/a/tu/proyecto

# Actualizar desde Git y reiniciar servicios
./deploy_production.sh
```

## 📁 Scripts Disponibles

### **Desarrollo Local:**
- `start_server.sh` - Inicia servidor con screen
- `manage_screen.sh` - Gestiona sesiones de screen
- `update_server.sh` - Actualiza código y reinicia servidor
- `test_app.sh` - Pruebas automatizadas

### **Producción:**
- `deploy_production.sh` - Despliegue completo en producción
- `fix_nginx_complete.sh` - Configuración completa de Nginx

## 🔧 Comandos Útiles

### **Gestión de Screen:**
```bash
# Ver estado
./manage_screen.sh status

# Ver sesiones activas
./manage_screen.sh list

# Conectarte al servidor
./manage_screen.sh connect

# Detener servidor
./manage_screen.sh stop

# Ver logs
./manage_screen.sh logs
```

### **Comandos de Screen Básicos:**
```bash
# Dentro de screen:
Ctrl+A, D     # Desconectarte (servidor sigue corriendo)
Ctrl+A, C     # Nueva ventana
Ctrl+A, N     # Siguiente ventana

# Fuera de screen:
screen -list           # Ver sesiones
screen -r nombre       # Conectarte
screen -S nombre -X quit  # Matar sesión
```

## 🌐 URLs de Acceso

- **Desarrollo:** `http://127.0.0.1:8080`
- **Producción:** `http://tu-dominio.com`
- **Health Check:** `/health`

## 📋 Checklist de Despliegue

### **Primera Vez:**
- [ ] Instalar Python 3.8+
- [ ] Crear entorno virtual: `python3 -m venv venv`
- [ ] Instalar dependencias: `pip install -r requirements.txt`
- [ ] Instalar screen: `sudo apt-get install screen`
- [ ] Configurar Nginx: `sudo ./fix_nginx_complete.sh`
- [ ] Crear servicio systemd: `sudo cp nemesix.service /etc/systemd/system/`
- [ ] Iniciar servicios: `sudo systemctl enable nemesix && sudo systemctl start nemesix`

### **Actualizaciones:**
- [ ] Hacer cambios en código
- [ ] Probar localmente
- [ ] Commitear y hacer push
- [ ] En servidor: `./deploy_production.sh`

## 🚨 Solución de Problemas

### **502 Bad Gateway:**
```bash
sudo ./fix_nginx_complete.sh
sudo systemctl restart nginx nemesix
```

### **Servidor no responde:**
```bash
./manage_screen.sh status
./manage_screen.sh logs
./start_server.sh
```

### **Problemas de permisos:**
```bash
sudo chown -R www-data:www-data /var/www/nemesix
sudo chmod -R 755 /var/www/nemesix
```

## 📞 Soporte

Si tienes problemas:
1. Revisa logs: `./manage_screen.sh logs`
2. Verifica servicios: `sudo systemctl status nemesix nginx`
3. Prueba conectividad: `curl http://localhost/health`
4. Revisa configuración: `sudo nginx -t`

¡Tu servidor Flask está listo para producción! 🎉

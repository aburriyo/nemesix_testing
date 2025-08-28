# Nemesix - Aplicación Web

Una aplicación web moderna construida con Flask para el proyecto Nemesix.

## 🚀 Despliegue en Digital Ocean

### Prerrequisitos

- Droplet de Ubuntu 20.04 o superior
- Python 3.8+
- Nginx
- Supervisor (opcional, para gestión de procesos)

### Instalación

1. **Clonar el repositorio:**
```bash
git clone https://github.com/aburriyo/nemesix_testing.git
cd nemesix_testing
```

2. **Instalar dependencias del sistema:**
```bash
sudo apt update
sudo apt install python3 python3-pip python3-venv nginx
```

3. **Configurar entorno virtual:**
```bash
python3 -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
```

4. **Configurar variables de entorno:**
```bash
cp .env.example .env
# Edita .env con tus configuraciones
nano .env
```

5. **Configurar Nginx:**
```bash
sudo cp nginx.conf /etc/nginx/sites-available/nemesix
sudo ln -s /etc/nginx/sites-available/nemesix /etc/nginx/sites-enabled/
sudo nginx -t
sudo systemctl reload nginx
```

6. **Configurar firewall:**
```bash
sudo ufw allow 'Nginx Full'
sudo ufw allow ssh
sudo ufw --force enable
```

7. **Iniciar la aplicación:**
```bash
chmod +x start.sh
./start.sh
```

### Configuración de SSL (Opcional)

Para configurar HTTPS con Let's Encrypt:

```bash
sudo apt install certbot python3-certbot-nginx
sudo certbot --nginx -d tu-dominio.com
```

### Monitoreo

La aplicación incluye un endpoint de health check:
```
GET /health
```

### Logs

Los logs se almacenan en:
- `/var/log/nginx/nemesix_access.log`
- `/var/log/nginx/nemesix_error.log`
- Los logs de la aplicación se muestran en la consola de Gunicorn

### Troubleshooting

#### Problema: Solo se muestra HTML sin estilos/CSS

**Solución:**
1. Verificar que Nginx esté sirviendo correctamente los archivos estáticos
2. Revisar permisos de archivos: `chmod 755 static/`
3. Verificar configuración de Nginx para archivos estáticos
4. Reiniciar Nginx: `sudo systemctl restart nginx`

#### Problema: Error 500

**Solución:**
1. Revisar logs de Gunicorn
2. Verificar conexión a base de datos
3. Revisar variables de entorno
4. Verificar permisos de escritura en `database/`

#### Problema: Error de conexión

**Solución:**
1. Verificar que Gunicorn esté ejecutándose: `ps aux | grep gunicorn`
2. Revisar configuración de firewall
3. Verificar configuración de Nginx

### Comandos útiles

```bash
# Reiniciar servicios
sudo systemctl restart nginx
sudo systemctl reload nginx

# Ver logs
sudo tail -f /var/log/nginx/nemesix_error.log
sudo tail -f /var/log/nginx/nemesix_access.log

# Ver procesos
ps aux | grep gunicorn
ps aux | grep nginx

# Verificar configuración
sudo nginx -t
```

## 📋 Características

- ✅ Autenticación de usuarios
- ✅ Dashboard administrativo
- ✅ Sistema de perfiles
- ✅ Interfaz responsiva
- ✅ Animaciones modernas
- ✅ Base de datos SQLite
- ✅ Configuración de producción
- ✅ Manejo de errores
- ✅ Logging integrado

## 🛠️ Tecnologías

- **Backend:** Flask 3.0.3
- **Base de datos:** SQLite
- **Servidor:** Gunicorn
- **Web Server:** Nginx
- **Frontend:** HTML5, CSS3, JavaScript
- **Animaciones:** Anime.js

## 📞 Soporte

Si encuentras problemas durante el despliegue, verifica:
1. Los logs de error
2. La configuración de Nginx
3. Los permisos de archivos
4. Las variables de entorno


## Make Changes to Your App

If you forked our repo, you can now make changes to your copy of the sample app. Pushing a new change to the forked repo automatically redeploys the app to App Platform with zero downtime.

Here's an example code change you can make for this app:

1. Edit `templates/index.html` and replace "Welcome to your new Flask App!" with a different greeting
1. Commit the change to the `main` branch. Normally it's a better practice to create a new branch for your change and then merge that branch to `main` after review, but for this demo you can commit to the `main` branch directly.
1. Visit the [control panel](https://cloud.digitalocean.com/apps) and navigate to your sample app.
1. You should see a "Building..." progress indicator, just like when you first created the app.
1. Once the build completes successfully, click the **Live App** link in the header and you should see your updated application running. You may need to force refresh the page in your browser (e.g. using **Shift** + **Reload**).

## Learn More

To learn more about App Platform and how to manage and update your application, see [our App Platform documentation](https://www.digitalocean.com/docs/app-platform/).

## Delete the App

When you no longer need this sample application running live, you can delete it by following these steps:
1. Visit the [Apps control panel](https://cloud.digitalocean.com/apps).
2. Navigate to the sample app.
3. In the **Settings** tab, click **Destroy**.

**Note**: If you do not delete your app, charges for using DigitalOcean services will continue to accrue.

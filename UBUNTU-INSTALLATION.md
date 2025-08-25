# Instalación de vlmcsd en Ubuntu

Esta guía explica cómo instalar vlmcsd (servidor KMS) en Ubuntu después de compilar los binarios.

## 🚀 Instalación Automática

### Usando el Script de Instalación

Si descargaste un release pre-compilado:

```bash
# Descargar y extraer
wget https://github.com/tu-usuario/vlmcsd/releases/latest/download/vlmcsd-ubuntu-x64-full-openssl-vX.X.X.tar.gz
tar -xzf vlmcsd-ubuntu-x64-*.tar.gz
cd vlmcsd-ubuntu-x64-*

# Instalar como servicio systemd
sudo ./install-ubuntu.sh
```

### Verificación de la Instalación

```bash
# Verificar estado del servicio
sudo systemctl status vlmcsd

# Probar funcionamiento
vlmcs -v localhost

# Ver logs
sudo journalctl -u vlmcsd -f
```

## ⚙️ Instalación Manual

### 1. Compilación desde Código Fuente

```bash
# Instalar dependencias
sudo apt-get update
sudo apt-get install -y build-essential gcc make libssl-dev pkg-config

# Clonar repositorio
git clone https://github.com/tu-usuario/vlmcsd.git
cd vlmcsd

# Compilar con todas las características
make FEATURES=full CRYPTO=openssl STRIP=1

# Compilar versión mínima (opcional)
make clean
make FEATURES=minimum STRIP=1
```

### 2. Instalación de Binarios

```bash
# Crear usuario para el servicio
sudo useradd -r -s /bin/false -d /nonexistent -c "vlmcsd KMS Server" vlmcsd

# Copiar binarios
sudo cp bin/vlmcsd /usr/local/bin/
sudo cp bin/vlmcs /usr/local/bin/
sudo chmod +x /usr/local/bin/vlmcsd /usr/local/bin/vlmcs

# Crear directorio de configuración
sudo mkdir -p /etc/vlmcsd
sudo cp etc/vlmcsd.ini /etc/vlmcsd/ 2>/dev/null || echo "No config file found"
sudo cp etc/vlmcsd.kmd /etc/vlmcsd/ 2>/dev/null || echo "No KMS data file found"
sudo chown -R vlmcsd:vlmcsd /etc/vlmcsd
```

### 3. Configuración del Servicio systemd

Crear el archivo de servicio:

```bash
sudo tee /etc/systemd/system/vlmcsd.service > /dev/null << 'EOF'
[Unit]
Description=vlmcsd KMS Server
Documentation=man:vlmcsd(8)
After=network.target
Wants=network.target

[Service]
Type=forking
User=vlmcsd
Group=vlmcsd
ExecStart=/usr/local/bin/vlmcsd -D -d -i /etc/vlmcsd/vlmcsd.ini
ExecReload=/bin/kill -HUP $MAINPID
PIDFile=/run/vlmcsd.pid
Restart=on-failure
RestartSec=10

# Seguridad
NoNewPrivileges=true
ProtectSystem=strict
ProtectHome=true
ReadWritePaths=/run
PrivateDevices=true
ProtectKernelTunables=true
ProtectKernelModules=true
ProtectControlGroups=true
RestrictRealtime=true
RestrictSUIDSGID=true
RemoveIPC=true
PrivateMounts=true

[Install]
WantedBy=multi-user.target
EOF
```

### 4. Activar y Iniciar el Servicio

```bash
# Recargar systemd
sudo systemctl daemon-reload

# Habilitar inicio automático
sudo systemctl enable vlmcsd

# Iniciar servicio
sudo systemctl start vlmcsd

# Verificar estado
sudo systemctl status vlmcsd
```

## 🔧 Configuración

### Archivo de Configuración Principal

Editar `/etc/vlmcsd/vlmcsd.ini`:

```ini
# Puerto de escucha (por defecto 1688)
Listen = 0.0.0.0:1688

# Archivo de log
LogFile = /var/log/vlmcsd.log

# Nivel de logging
LogVerbose = false

# Timeout de conexión
ConnectionTimeout = 30

# Máximo de workers
MaxWorkers = 4

# Archivo PID
PidFile = /run/vlmcsd.pid
```

### Configuración del Firewall

```bash
# UFW (Ubuntu Firewall)
sudo ufw allow 1688/tcp comment "KMS Server"

# iptables directo
sudo iptables -A INPUT -p tcp --dport 1688 -j ACCEPT
```

## 🧪 Pruebas y Validación

### Prueba Local

```bash
# Probar conectividad
vlmcs -v localhost

# Probar con IP específica
vlmcs -v 127.0.0.1

# Verificar puerto
netstat -tlnp | grep 1688
```

### Prueba desde Cliente Windows

```cmd
# Configurar servidor KMS
slmgr /skms IP_DEL_SERVIDOR:1688

# Activar Windows
slmgr /ato

# Verificar estado
slmgr /xpr
```

### Prueba desde Cliente Office

```cmd
# Office 2019/2021
cd "C:\Program Files\Microsoft Office\Office16"
cscript ospp.vbs /sethst:IP_DEL_SERVIDOR
cscript ospp.vbs /act
cscript ospp.vbs /dstatus
```

## 🔍 Monitoreo y Logs

### Ver Logs del Servicio

```bash
# Logs en tiempo real
sudo journalctl -u vlmcsd -f

# Logs históricos
sudo journalctl -u vlmcsd --since "1 hour ago"

# Logs con detalles
sudo journalctl -u vlmcsd -o verbose
```

### Logs de Aplicación

Si configuraste `LogFile` en vlmcsd.ini:

```bash
# Ver logs de aplicación
sudo tail -f /var/log/vlmcsd.log

# Rotar logs (configurar logrotate)
sudo tee /etc/logrotate.d/vlmcsd > /dev/null << 'EOF'
/var/log/vlmcsd.log {
    daily
    missingok
    rotate 30
    compress
    delaycompress
    notifempty
    copytruncate
}
EOF
```

## 🛠️ Gestión del Servicio

### Comandos Básicos

```bash
# Iniciar
sudo systemctl start vlmcsd

# Parar
sudo systemctl stop vlmcsd

# Reiniciar
sudo systemctl restart vlmcsd

# Recargar configuración
sudo systemctl reload vlmcsd

# Estado
sudo systemctl status vlmcsd

# Habilitar/deshabilitar inicio automático
sudo systemctl enable vlmcsd
sudo systemctl disable vlmcsd
```

### Actualización

```bash
# Parar servicio
sudo systemctl stop vlmcsd

# Reemplazar binarios
sudo cp nuevo_vlmcsd /usr/local/bin/vlmcsd
sudo chmod +x /usr/local/bin/vlmcsd

# Reiniciar servicio
sudo systemctl start vlmcsd
```

## 🔐 Consideraciones de Seguridad

### Restricciones de Red

```bash
# Permitir solo red local (ejemplo para 192.168.x.x)
sudo iptables -A INPUT -p tcp --dport 1688 -s 192.168.0.0/16 -j ACCEPT
sudo iptables -A INPUT -p tcp --dport 1688 -j DROP
```

### Configuración Segura

En `/etc/vlmcsd/vlmcsd.ini`:

```ini
# Solo escuchar en IPs específicas
Listen = 192.168.1.100:1688

# Limitar conexiones concurrentes
MaxWorkers = 2

# Timeout rápido
ConnectionTimeout = 15

# Protección contra IPs públicas
PublicIPProtectionLevel = 3
```

## ❌ Desinstalación

```bash
# Parar y deshabilitar servicio
sudo systemctl stop vlmcsd
sudo systemctl disable vlmcsd

# Eliminar archivos de servicio
sudo rm /etc/systemd/system/vlmcsd.service
sudo systemctl daemon-reload

# Eliminar binarios
sudo rm /usr/local/bin/vlmcsd
sudo rm /usr/local/bin/vlmcs

# Eliminar configuración
sudo rm -rf /etc/vlmcsd

# Eliminar usuario
sudo userdel vlmcsd

# Eliminar logs
sudo rm -f /var/log/vlmcsd.log
```

## 🐛 Solución de Problemas

### Servicio no Inicia

```bash
# Ver errores detallados
sudo journalctl -u vlmcsd -n 50

# Verificar permisos
ls -la /usr/local/bin/vlmcsd
ls -la /etc/vlmcsd/

# Probar manualmente
sudo -u vlmcsd /usr/local/bin/vlmcsd -D -f
```

### Puerto Ocupado

```bash
# Ver qué usa el puerto 1688
sudo netstat -tlnp | grep 1688
sudo lsof -i :1688

# Cambiar puerto en configuración
echo "Listen = 0.0.0.0:1689" | sudo tee -a /etc/vlmcsd/vlmcsd.ini
```

### Problemas de Conectividad

```bash
# Verificar firewall
sudo ufw status
sudo iptables -L | grep 1688

# Probar telnet
telnet IP_SERVIDOR 1688

# Verificar DNS
nslookup IP_SERVIDOR
```

## 📚 Referencias

- [Manual de vlmcsd](man/vlmcsd.8)
- [Manual de vlmcs](man/vlmcs.1)
- [Configuración vlmcsd.ini](man/vlmcsd.ini.5)
- [Documentación systemd](https://systemd.io/)

## ⚖️ Nota Legal

Este software es solo para **fines educativos y de prueba**. Asegúrate de cumplir con los términos de licencia de Microsoft y las leyes aplicables en tu jurisdicción.

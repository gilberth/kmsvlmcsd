# 🚀 Guía de Instalación Rápida - vlmcsd Ubuntu

## 📥 Opciones de Instalación

### 1️⃣ **Instalación Automática (Recomendada)**

**Instalación interactiva** - El script te preguntará qué configuración prefieres:

```bash
curl -fsSL https://raw.githubusercontent.com/gilberth/kmsvlmcsd/master/scripts/install-ubuntu.sh | sudo bash
```

### 2️⃣ **Instalación con Configuración Específica**

**Para servidores de producción** (todas las características + OpenSSL):

```bash
VARIANT=full CRYPTO=openssl curl -fsSL https://raw.githubusercontent.com/gilberth/kmsvlmcsd/master/scripts/install-ubuntu.sh | sudo bash
```

**Para sistemas embebidos** (optimizado, sin dependencias):

```bash
VARIANT=embedded CRYPTO=internal curl -fsSL https://raw.githubusercontent.com/gilberth/kmsvlmcsd/master/scripts/install-ubuntu.sh | sudo bash
```

**Para scripts de autostart** (características básicas):

```bash
VARIANT=autostart CRYPTO=internal curl -fsSL https://raw.githubusercontent.com/gilberth/kmsvlmcsd/master/scripts/install-ubuntu.sh | sudo bash
```

**Con aceleración hardware AES** (solo para variant=full):

```bash
VARIANT=full CRYPTO=openssl_with_aes curl -fsSL https://raw.githubusercontent.com/gilberth/kmsvlmcsd/master/scripts/install-ubuntu.sh | sudo bash
```

**Instalación no interactiva** (para scripts):

```bash
INTERACTIVE=no VARIANT=full CRYPTO=openssl curl -fsSL https://raw.githubusercontent.com/gilberth/kmsvlmcsd/master/scripts/install-ubuntu.sh | sudo bash
```

## 🔧 **Configuraciones Disponibles**

| Variante    | Crypto Backend     | Descripción                         | Uso Recomendado                 |
| ----------- | ------------------ | ----------------------------------- | ------------------------------- |
| `full`      | `openssl`          | ✅ **Recomendado para servidores**  | Servidores de producción        |
| `full`      | `internal`         | Todas las características, sin deps | Servidores sin OpenSSL          |
| `full`      | `openssl_with_aes` | Con aceleración hardware            | Servidores con CPU moderno      |
| `embedded`  | `internal`         | ✅ **Recomendado para embebidos**   | Sistemas con recursos limitados |
| `embedded`  | `openssl`          | Optimizado con SSL                  | Embebidos que necesitan SSL     |
| `autostart` | `internal`         | ✅ **Recomendado para scripts**     | Scripts de inicio automático    |

### 🎯 **¿Cuál elegir?**

- **🖥️ Servidor Ubuntu**: `VARIANT=full CRYPTO=openssl`
- **🔧 Docker/Contenedor**: `VARIANT=embedded CRYPTO=internal`
- **⚡ Raspberry Pi**: `VARIANT=embedded CRYPTO=internal`
- **🚀 Script de inicio**: `VARIANT=autostart CRYPTO=internal`
- **💾 Mínimo espacio**: `VARIANT=autostart CRYPTO=internal`

## ✅ **Verificación Post-Instalación**

```bash
# Verificar estado del servicio
sudo systemctl status vlmcsd

# Probar funcionamiento
vlmcs -v localhost

# Ver logs
sudo journalctl -u vlmcsd -f

# Verificar puerto
netstat -tlnp | grep 1688
```

## 🔧 **Gestión del Servicio**

```bash
# Control básico
sudo systemctl start vlmcsd
sudo systemctl stop vlmcsd
sudo systemctl restart vlmcsd

# Configuración
sudo nano /etc/vlmcsd/vlmcsd.ini
sudo systemctl reload vlmcsd

# Logs
sudo journalctl -u vlmcsd --since "1 hour ago"
```

## 🖥️ **Activación de Clientes**

### Windows

```cmd
slmgr /skms IP_DEL_SERVIDOR:1688
slmgr /ato
slmgr /xpr
```

### Office 2019/2021

```cmd
cd "C:\Program Files\Microsoft Office\Office16"
cscript ospp.vbs /sethst:IP_DEL_SERVIDOR
cscript ospp.vbs /act
cscript ospp.vbs /dstatus
```

## 🛠️ **Solución de Problemas**

### Error de descarga

```bash
# Verificar conectividad
curl -I https://github.com/gilberth/kmsvlmcsd/releases/latest

# Instalación manual
wget https://github.com/gilberth/kmsvlmcsd/releases/latest/download/vlmcsd-ubuntu-x64-full-openssl-latest.tar.gz
```

### Servicio no inicia

```bash
# Ver errores detallados
sudo journalctl -u vlmcsd -n 50

# Verificar permisos
ls -la /usr/local/bin/vlmcsd /etc/vlmcsd/

# Probar manualmente
sudo -u vlmcsd /usr/local/bin/vlmcsd -f -D
```

## �️ **Desinstalación Completa**

### **Desinstalación Automática (Un Comando)**

```bash
curl -fsSL https://raw.githubusercontent.com/gilberth/kmsvlmcsd/master/scripts/uninstall-ubuntu.sh | sudo bash
```

### **¿Qué se elimina?**

- ✅ Servicio systemd (detiene y deshabilita)
- ✅ Binarios (`vlmcsd`, `vlmcs`, `vlmcsdmulti`)
- ✅ Archivos de configuración (`/etc/vlmcsd/`)
- ✅ Usuario del sistema (`vlmcsd`)
- ✅ Logs de aplicación (`/var/log/vlmcsd.log`)
- ✅ Reglas de firewall (puerto 1688)

### **Desinstalación Manual (si prefieres paso a paso)**

```bash
# Detener y deshabilitar servicio
sudo systemctl stop vlmcsd
sudo systemctl disable vlmcsd

# Eliminar archivos de servicio
sudo rm -f /etc/systemd/system/vlmcsd.service
sudo systemctl daemon-reload

# Eliminar binarios
sudo rm -f /usr/local/bin/vlmcsd
sudo rm -f /usr/local/bin/vlmcs
sudo rm -f /usr/local/bin/vlmcsdmulti

# Eliminar configuración
sudo rm -rf /etc/vlmcsd

# Eliminar usuario
sudo userdel vlmcsd

# Eliminar logs
sudo rm -f /var/log/vlmcsd.log

# Limpiar firewall
sudo ufw delete allow 1688/tcp
```

## �🔄 **Reinstalación/Cambio de Configuración**

Para cambiar de configuración, simplemente ejecuta el script con una configuración diferente:

```bash
# Cambiar de embedded a full
sudo systemctl stop vlmcsd
VARIANT=full CRYPTO=openssl curl -fsSL https://raw.githubusercontent.com/gilberth/kmsvlmcsd/master/scripts/install-ubuntu.sh | sudo bash
```

## 📚 **Enlaces Útiles**

- [Documentación completa](UBUNTU-INSTALLATION.md)
- [Manual de compilación](README.compile-and-pre-built-binaries.md)
- [Análisis de seguridad](SECURITY-ANALYSIS.md)
- [GitHub Releases](https://github.com/gilberth/kmsvlmcsd/releases)

---

**⚖️ Aviso Legal**: Este software es solo para fines educativos y de prueba. Asegúrate de cumplir con los términos de licencia de Microsoft y las leyes aplicables.

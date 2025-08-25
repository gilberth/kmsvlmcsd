# 🖥️ vlmcsd – KMS Server

**vlmcsd** es un servidor KMS (_Key Management Service_) emulador que permite activar productos **Microsoft Windows** y **Office**.  
Emula un servidor KMS en tu red local, permitiendo que los clientes activen su software sin conectarse a los servidores de Microsoft.

---

## ✨ Características

- **Ligero** – Imagen Docker optimizada con soporte SSL.
- **Multiplataforma** – Soporte para arquitecturas `amd64` y `arm64`.
- **Autocontenido** – No requiere dependencias externas.
- **Seguro** – Construido con `Dockerfile.secure` y buenas prácticas de seguridad.
- **Persistente** – Configuración con reinicio automático.

---

## 🚀 Despliegue Rápido con Docker

### 1️⃣ Requisitos Previos

- **Docker** instalado en el sistema.
- **Puerto 1688** abierto (puerto estándar para KMS, configurable).
- **Acceso a red local** para los clientes que requieran activación.

### 2️⃣ Comando de despliegue rápido

```bash
docker run -d   --name vlmcsd   --restart unless-stopped   -p 1688:1688   ghcr.io/gilberth/kms:latest
```

### 3️⃣ Verificación

```bash
# Verificar que el contenedor está en ejecución
docker ps

# Ver logs del servidor
docker logs vlmcsd

# Probar el servidor
docker exec vlmcsd /usr/bin/vlmcs -v localhost
```

---

## 🐳 Opciones de Despliegue

### 📦 Despliegue Básico

```bash
docker pull ghcr.io/gilberth/kms:latest
docker run -d   --name vlmcsd   --restart unless-stopped   -p 1688:1688   ghcr.io/gilberth/kms:latest
```

### 📄 Docker Compose

Archivo `docker-compose.yml`:

```yaml
version: "3.8"
services:
  vlmcsd:
    image: ghcr.io/gilberth/kms:latest
    container_name: vlmcsd
    restart: unless-stopped
    ports:
      - "1688:1688"
    # Opcional: configuración personalizada
    # volumes:
    #   - ./vlmcsd.ini:/etc/vlmcsd.ini:ro
```

Ejecutar:

```bash
docker-compose up -d
```

### ⚙️ Configuración Avanzada

```bash
# Con archivo de configuración
docker run -d   --name vlmcsd   --restart unless-stopped   -p 1688:1688   -v /ruta/a/vlmcsd.ini:/etc/vlmcsd.ini:ro   ghcr.io/gilberth/kms:latest

# Con puerto personalizado
docker run -d   --name vlmcsd   --restart unless-stopped   -p 1689:1688   ghcr.io/gilberth/kms:latest
```

---

## 🛠️ Activación de Clientes

### 💻 Windows

```cmd
slmgr /skms TU_IP_SERVIDOR:1688
slmgr /ato
slmgr /xpr
```

### 📄 Office 2019/2021

```cmd
cscript "C:\Program Files\Microsoft Office\Office16\ospp.vbs" /sethst:TU_IP_SERVIDOR
cscript "C:\Program Files\Microsoft Office\Office16\ospp.vbs" /act
cscript "C:\Program Files\Microsoft Office\Office16\ospp.vbs" /dstatus
```

---

## 📋 Gestión del Contenedor

```bash
docker ps                  # Ver estado
docker stop vlmcsd         # Detener
docker start vlmcsd        # Iniciar
docker restart vlmcsd      # Reiniciar
docker logs -f vlmcsd      # Logs en tiempo real
docker rm vlmcsd           # Eliminar
```

---

## 🔍 Pruebas y Monitoreo

```bash
docker exec vlmcsd /usr/bin/vlmcs -v localhost
vlmcs -v TU_IP_SERVIDOR
telnet TU_IP_SERVIDOR 1688
```

---

## 🏗️ Construcción desde Código Fuente

### Compilación Local

#### Prerrequisitos

- Compilador GCC o compatible
- Sistema de construcción Make
- Librerías de desarrollo OpenSSL (opcional para soporte SSL)

#### Ubuntu/Debian

```bash
# Instalar dependencias
sudo apt-get install -y build-essential gcc make libssl-dev pkg-config

# Compilar
make FEATURES=full CRYPTO=openssl STRIP=1

# Compilar versión mínima
make clean
make FEATURES=minimum STRIP=1
```

#### Binarios Generados

- `bin/vlmcsd` – Servidor KMS
- `bin/vlmcs` – Cliente KMS para pruebas
- `bin/vlmcsdmulti` – Binario multi-llamada

### 🤖 Compilación Automática con GitHub Actions

Este proyecto incluye workflows de GitHub Actions que compilan automáticamente binarios para Ubuntu x64:

#### Características del Workflow

- **Múltiples variantes**: `full`, `embedded`, `minimum`
- **Backends crypto**: `internal`, `openssl`, `openssl_with_aes`
- **Pruebas automáticas**: Verificación de funcionalidad
- **Artefactos**: Binarios empaquetados con script de instalación
- **Releases**: Creación automática de releases en tags

#### Uso de Releases Pre-compilados

```bash
# Instalación automática desde GitHub Releases
curl -fsSL https://raw.githubusercontent.com/gilberth/kmsvlmcsd/master/scripts/install-ubuntu.sh | sudo bash

# O descarga manual
wget https://github.com/gilberth/kmsvlmcsd/releases/latest/download/vlmcsd-ubuntu-x64-full-openssl-vX.X.X.tar.gz
tar -xzf vlmcsd-ubuntu-x64-*.tar.gz
cd vlmcsd-ubuntu-x64-*
sudo ./install-ubuntu.sh
```

### 📋 Opciones de Compilación Avanzadas

```bash
# Con todas las características y soporte SSL hardware
make FEATURES=full CRYPTO=openssl_with_aes STRIP=1 VERBOSE=1

# Para sistemas embebidos
make FEATURES=embedded CRYPTO=internal STRIP=1

# Con configuración personalizada
make FEATURES=full CONFIG=mi_config.h INI=mi_vlmcsd.ini

# Compilación cross-platform
make CC=/path/to/cross-compiler FEATURES=embedded
```

---

## 🐧 Instalación en Ubuntu

### 🚀 Instalación Rápida (Un Comando)

```bash
curl -fsSL https://raw.githubusercontent.com/gilberth/kmsvlmcsd/master/scripts/install-ubuntu.sh | sudo bash
```

### 📥 Instalación Manual desde Release

```bash
# Descargar última versión
wget https://github.com/gilberth/kmsvlmcsd/releases/latest/download/vlmcsd-ubuntu-x64-full-openssl-latest.tar.gz

# Extraer e instalar
tar -xzf vlmcsd-ubuntu-x64-*.tar.gz
cd vlmcsd-ubuntu-x64-*
sudo ./install-ubuntu.sh
```

### ⚙️ Gestión del Servicio

```bash
sudo systemctl status vlmcsd    # Ver estado
sudo systemctl restart vlmcsd   # Reiniciar
sudo journalctl -u vlmcsd -f    # Ver logs
vlmcs -v localhost              # Probar funcionamiento
```

### �️ Desinstalación

```bash
curl -fsSL https://raw.githubusercontent.com/gilberth/kmsvlmcsd/master/scripts/uninstall-ubuntu.sh | sudo bash
```

### �📋 Configuración

- **Archivo de configuración**: `/etc/vlmcsd/vlmcsd.ini`
- **Logs**: `/var/log/vlmcsd.log` o `journalctl -u vlmcsd`
- **Puerto**: `1688` (configurable)

Para más detalles, consulta [UBUNTU-INSTALLATION.md](UBUNTU-INSTALLATION.md)

---

## 📚 Documentación

```bash
man man/vlmcsd.8
man man/vlmcs.1
man man/vlmcsd.7
man man/vlmcsd.ini.5
```

Si no tienes `man` instalado, revisa los archivos `.txt`, `.html` y `.pdf` en el directorio `man`.

---

## ⚠️ Consideraciones de Seguridad

Consulta `SECURITY-ANALYSIS.md` antes de usar en producción.

---

## ⚖️ Aviso Legal

Este software es solo para **fines educativos y de prueba**.  
Asegúrate de cumplir con los términos de licencia de Microsoft y las leyes aplicables.

---

## 🤝 Contribuciones

¡Bienvenidas! Asegúrate de mantener el estilo y la documentación.

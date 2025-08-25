#!/bin/bash
# Script de instalación rápida de vlmcsd para Ubuntu
# Uso básico: curl -fsSL https://raw.githubusercontent.com/gilberth/kmsvlmcsd/master/scripts/install-ubuntu.sh | sudo bash
# Uso avanzado: curl -fsSL https://raw.githubusercontent.com/gilberth/kmsvlmcsd/master/scripts/install-ubuntu.sh | sudo VARIANT=embedded CRYPTO=internal bash

set -e

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Variables (pueden ser sobrescritas por variables de entorno)
INSTALL_DIR="/usr/local/bin"
CONFIG_DIR="/etc/vlmcsd"
SERVICE_FILE="/etc/systemd/system/vlmcsd.service"
USER="vlmcsd"
GITHUB_REPO="gilberth/kmsvlmcsd"
ARCH="x64"

# Configuraciones disponibles
VARIANT="${VARIANT:-full}"          # full, embedded, autostart
CRYPTO="${CRYPTO:-openssl}"         # internal, openssl, openssl_with_aes

# Modo interactivo (si no se especifican variables de entorno)
INTERACTIVE="${INTERACTIVE:-auto}"   # auto, yes, no

echo -e "${BLUE}=== vlmcsd Ubuntu Installation Script ===${NC}"
echo "Este script instalará vlmcsd como servicio systemd en Ubuntu"
echo ""

# Verificar que se ejecute como root
if [[ $EUID -ne 0 ]]; then
   echo -e "${RED}❌ Este script debe ejecutarse como root (usa sudo)${NC}" 
   exit 1
fi

# Verificar Ubuntu
if ! grep -q "Ubuntu" /etc/os-release 2>/dev/null; then
    echo -e "${YELLOW}⚠️  Advertencia: Este script está diseñado para Ubuntu${NC}"
    echo "¿Continuar de todos modos? (y/N)"
    read -r response
    if [[ ! $response =~ ^[Yy]$ ]]; then
        exit 1
    fi
fi

# Funciones
log_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

log_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

log_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

log_error() {
    echo -e "${RED}❌ $1${NC}"
}

log_cyan() {
    echo -e "${CYAN}🔧 $1${NC}"
}

# Función para seleccionar configuración
select_configuration() {
    if [[ "$INTERACTIVE" == "no" ]] || [[ -n "$VARIANT" && -n "$CRYPTO" && "$INTERACTIVE" == "auto" ]]; then
        log_info "Usando configuración: VARIANT=$VARIANT, CRYPTO=$CRYPTO"
        return
    fi
    
    echo ""
    log_cyan "Configuraciones disponibles de vlmcsd:"
    echo ""
    echo -e "${CYAN}📋 VARIANTES:${NC}"
    echo "  1) full      - Todas las características (recomendado para servidores)"
    echo "  2) embedded  - Optimizado para sistemas embebidos (menor tamaño)"
    echo "  3) autostart - Para scripts de inicio automático (características básicas)"
    echo ""
    echo -e "${CYAN}🔐 BACKENDS CRYPTO:${NC}"
    echo "  1) openssl           - OpenSSL del sistema (recomendado, requiere libssl)"
    echo "  2) internal          - Crypto interno (sin dependencias externas)"
    echo "  3) openssl_with_aes  - OpenSSL + aceleración hardware AES (solo para 'full')"
    echo ""
    
    # Seleccionar variante
    while true; do
        echo -n -e "${CYAN}Selecciona variante [1-3] (por defecto: 1-full): ${NC}"
        read -r variant_choice
        case $variant_choice in
            ""|1) VARIANT="full"; break ;;
            2) VARIANT="embedded"; break ;;
            3) VARIANT="autostart"; break ;;
            *) echo -e "${RED}Opción inválida. Usa 1, 2 o 3.${NC}" ;;
        esac
    done
    
    # Seleccionar crypto
    while true; do
        echo -n -e "${CYAN}Selecciona backend crypto [1-3] (por defecto: 1-openssl): ${NC}"
        read -r crypto_choice
        case $crypto_choice in
            ""|1) CRYPTO="openssl"; break ;;
            2) CRYPTO="internal"; break ;;
            3) 
                if [[ "$VARIANT" == "full" ]]; then
                    CRYPTO="openssl_with_aes"
                    break
                else
                    echo -e "${RED}openssl_with_aes solo está disponible para la variante 'full'.${NC}"
                fi
                ;;
            *) echo -e "${RED}Opción inválida. Usa 1, 2 o 3.${NC}" ;;
        esac
    done
    
    echo ""
    log_success "Configuración seleccionada: $VARIANT + $CRYPTO"
    echo ""
}

# Detectar la última release
get_latest_release() {
    log_info "Detectando la última versión disponible..."
    LATEST_VERSION=$(curl -s "https://api.github.com/repos/$GITHUB_REPO/releases/latest" | \
                     grep '"tag_name":' | \
                     sed -E 's/.*"([^"]+)".*/\1/')
    
    if [[ -z "$LATEST_VERSION" ]]; then
        log_error "No se pudo detectar la última versión"
        exit 1
    fi
    
    log_success "Última versión detectada: $LATEST_VERSION"
}

# Descargar binarios
download_binaries() {
    log_info "Descargando binarios vlmcsd..."
    
    DOWNLOAD_URL="https://github.com/$GITHUB_REPO/releases/download/$LATEST_VERSION/vlmcsd-ubuntu-$ARCH-$VARIANT-$CRYPTO-$LATEST_VERSION.tar.gz"
    TEMP_DIR=$(mktemp -d)
    
    log_info "Configuración seleccionada: $VARIANT + $CRYPTO"
    log_info "Descargando desde: $DOWNLOAD_URL"
    
    # Lista de configuraciones de fallback
    FALLBACK_CONFIGS=(
        "$VARIANT-$CRYPTO"
        "$VARIANT-openssl"
        "$VARIANT-internal"
        "full-openssl"
        "full-internal"
        "embedded-internal"
    )
    
    SUCCESS=false
    
    for config in "${FALLBACK_CONFIGS[@]}"; do
        IFS='-' read -r try_variant try_crypto <<< "$config"
        
        # Evitar repetir la misma configuración
        if [[ "$try_variant-$try_crypto" == "$VARIANT-$CRYPTO" && "$SUCCESS" == "false" ]]; then
            try_url="$DOWNLOAD_URL"
        else
            try_url="https://github.com/$GITHUB_REPO/releases/download/$LATEST_VERSION/vlmcsd-ubuntu-$ARCH-$try_variant-$try_crypto-$LATEST_VERSION.tar.gz"
        fi
        
        log_info "Intentando descargar: $try_variant + $try_crypto"
        
        if curl -fsSL "$try_url" -o "$TEMP_DIR/vlmcsd.tar.gz"; then
            log_success "Descarga exitosa: $try_variant + $try_crypto"
            VARIANT="$try_variant"
            CRYPTO="$try_crypto"
            SUCCESS=true
            break
        else
            log_warning "No disponible: $try_variant + $try_crypto"
        fi
    done
    
    if [[ "$SUCCESS" == "false" ]]; then
        log_error "No se pudieron descargar los binarios de ninguna configuración"
        log_info "Configuraciones intentadas: ${FALLBACK_CONFIGS[*]}"
        exit 1
    fi
    
    cd "$TEMP_DIR"
    tar -xzf vlmcsd.tar.gz
    EXTRACT_DIR=$(find . -maxdepth 1 -type d -name "vlmcsd-*" | head -1)
    
    if [[ -z "$EXTRACT_DIR" ]]; then
        log_error "No se pudo extraer el archivo"
        exit 1
    fi
    
    cd "$EXTRACT_DIR"
    log_success "Binarios extraídos correctamente"
}

# Instalar dependencias
install_dependencies() {
    log_info "Actualizando repositorios e instalando dependencias..."
    
    apt-get update -qq
    
    if [[ "$CRYPTO" == "openssl" ]]; then
        apt-get install -y libssl3 2>/dev/null || apt-get install -y libssl1.1 2>/dev/null || {
            log_warning "No se pudo instalar libssl, usando versión interna"
            CRYPTO="internal"
        }
    fi
    
    log_success "Dependencias instaladas"
}

# Crear usuario del sistema
create_user() {
    log_info "Configurando usuario del sistema..."
    
    if ! id "$USER" &>/dev/null; then
        useradd -r -s /bin/false -d /nonexistent -c "vlmcsd KMS Server" "$USER"
        log_success "Usuario vlmcsd creado"
    else
        log_info "Usuario vlmcsd ya existe"
    fi
}

# Instalar binarios
install_binaries() {
    log_info "Instalando binarios..."
    
    if [[ ! -f "vlmcsd" ]]; then
        log_error "Binario vlmcsd no encontrado"
        exit 1
    fi
    
    cp vlmcsd "$INSTALL_DIR/"
    cp vlmcs "$INSTALL_DIR/"
    [[ -f vlmcsdmulti ]] && cp vlmcsdmulti "$INSTALL_DIR/"
    
    chmod +x "$INSTALL_DIR/vlmcsd" "$INSTALL_DIR/vlmcs"
    [[ -f "$INSTALL_DIR/vlmcsdmulti" ]] && chmod +x "$INSTALL_DIR/vlmcsdmulti"
    
    log_success "Binarios instalados en $INSTALL_DIR"
}

# Configurar archivos
setup_config() {
    log_info "Configurando archivos de configuración..."
    
    mkdir -p "$CONFIG_DIR"
    
    # Copiar archivos de configuración si existen
    [[ -f vlmcsd.ini ]] && cp vlmcsd.ini "$CONFIG_DIR/"
    [[ -f vlmcsd.kmd ]] && cp vlmcsd.kmd "$CONFIG_DIR/"
    
    # Crear configuración básica si no existe
    if [[ ! -f "$CONFIG_DIR/vlmcsd.ini" ]]; then
        cat > "$CONFIG_DIR/vlmcsd.ini" << 'CONFIG_EOF'
# Configuración básica de vlmcsd
Listen = 0.0.0.0:1688
LogFile = /var/log/vlmcsd.log
LogDateAndTime = true
MaxWorkers = 4
ConnectionTimeout = 30
PidFile = /run/vlmcsd.pid
CONFIG_EOF
    fi
    
    chown -R "$USER:$USER" "$CONFIG_DIR"
    log_success "Configuración establecida"
}

# Crear servicio systemd
create_service() {
    log_info "Creando servicio systemd..."
    
    cat > "$SERVICE_FILE" << 'SERVICE_EOF'
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

# Hardening de seguridad
NoNewPrivileges=true
ProtectSystem=strict
ProtectHome=true
ReadWritePaths=/run /var/log
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
SERVICE_EOF
    
    log_success "Servicio systemd creado"
}

# Configurar firewall
setup_firewall() {
    log_info "Configurando firewall..."
    
    if command -v ufw >/dev/null 2>&1; then
        if ufw status | grep -q "Status: active"; then
            ufw allow 1688/tcp comment "KMS Server" >/dev/null
            log_success "Regla UFW agregada para puerto 1688"
        else
            log_info "UFW no está activo, omitiendo configuración de firewall"
        fi
    else
        log_info "UFW no está instalado, omitiendo configuración de firewall"
    fi
}

# Iniciar servicio
start_service() {
    log_info "Iniciando servicio vlmcsd..."
    
    systemctl daemon-reload
    systemctl enable vlmcsd
    systemctl start vlmcsd
    
    # Esperar un momento y verificar
    sleep 2
    
    if systemctl is-active --quiet vlmcsd; then
        log_success "Servicio vlmcsd iniciado correctamente"
    else
        log_error "Error al iniciar el servicio vlmcsd"
        log_info "Verificando logs..."
        journalctl -u vlmcsd --no-pager -n 10
        exit 1
    fi
}

# Verificar instalación
verify_installation() {
    log_info "Verificando instalación..."
    
    # Verificar que el binario funciona
    if "$INSTALL_DIR/vlmcsd" -V >/dev/null 2>&1; then
        log_success "Binario vlmcsd funcional"
    else
        log_warning "El binario vlmcsd puede tener problemas"
    fi
    
    # Verificar conectividad
    sleep 1
    if "$INSTALL_DIR/vlmcs" -v localhost >/dev/null 2>&1; then
        log_success "Servidor KMS respondiendo correctamente"
    else
        log_warning "El servidor KMS puede no estar respondiendo"
    fi
    
    # Verificar puerto
    if netstat -tlnp 2>/dev/null | grep -q ":1688 "; then
        log_success "Puerto 1688 abierto y escuchando"
    else
        log_warning "Puerto 1688 puede no estar abierto"
    fi
}

# Mostrar información final
show_final_info() {
    echo ""
    echo -e "${GREEN}🎉 ¡Instalación completada exitosamente!${NC}"
    echo ""
    echo -e "${BLUE}📋 Información del servicio:${NC}"
    echo "  Configuración:  $VARIANT + $CRYPTO"
    echo "  Estado:         $(systemctl is-active vlmcsd)"
    echo "  Habilitado:     $(systemctl is-enabled vlmcsd)"
    echo "  Puerto:         1688"
    echo ""
    echo -e "${BLUE}🛠️  Comandos útiles:${NC}"
    echo "  Estado del servicio:  sudo systemctl status vlmcsd"
    echo "  Reiniciar servicio:   sudo systemctl restart vlmcsd"
    echo "  Ver logs:             sudo journalctl -u vlmcsd -f"
    echo "  Probar servidor:      vlmcs -v localhost"
    echo ""
    echo -e "${BLUE}📁 Archivos importantes:${NC}"
    echo "  Binarios:       $INSTALL_DIR/vlmcsd, $INSTALL_DIR/vlmcs"
    echo "  Configuración:  $CONFIG_DIR/vlmcsd.ini"
    echo "  Servicio:       $SERVICE_FILE"
    echo ""
    echo -e "${BLUE}🔧 Para configurar clientes Windows:${NC}"
    echo "  slmgr /skms $(hostname -I | awk '{print $1}'):1688"
    echo "  slmgr /ato"
    echo ""
    echo -e "${CYAN}📖 Configuraciones disponibles para reinstalar:${NC}"
    echo "  # Instalación específica con variables de entorno:"
    echo "  VARIANT=full CRYPTO=openssl curl -fsSL ... | sudo bash"
    echo "  VARIANT=embedded CRYPTO=internal curl -fsSL ... | sudo bash"
    echo "  VARIANT=autostart CRYPTO=internal curl -fsSL ... | sudo bash"
    echo ""
    echo -e "${CYAN}🗑️  Para desinstalar completamente vlmcsd:${NC}"
    echo "  curl -fsSL https://raw.githubusercontent.com/gilberth/kmsvlmcsd/master/scripts/uninstall-ubuntu.sh | sudo bash"
    echo ""
    echo -e "${YELLOW}⚠️  Nota: Usar solo para fines educativos y de prueba${NC}"
}

# Función de limpieza
cleanup() {
    if [[ -n "$TEMP_DIR" ]] && [[ -d "$TEMP_DIR" ]]; then
        rm -rf "$TEMP_DIR"
    fi
}

# Trap para limpieza en caso de error
trap cleanup EXIT

# Ejecución principal
main() {
    select_configuration
    get_latest_release
    install_dependencies
    download_binaries
    create_user
    install_binaries
    setup_config
    create_service
    setup_firewall
    start_service
    verify_installation
    show_final_info
}

# Ejecutar instalación
main "$@"

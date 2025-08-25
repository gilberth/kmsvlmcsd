#!/bin/bash
# Script de desinstalación de vlmcsd para Ubuntu
# Uso: curl -fsSL https://raw.githubusercontent.com/gilberth/kmsvlmcsd/master/scripts/uninstall-ubuntu.sh | sudo bash

set -e

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Variables
INSTALL_DIR="/usr/local/bin"
CONFIG_DIR="/etc/vlmcsd"
SERVICE_FILE="/etc/systemd/system/vlmcsd.service"
USER="vlmcsd"
LOG_FILE="/var/log/vlmcsd.log"

echo -e "${RED}=== vlmcsd Ubuntu Uninstallation Script ===${NC}"
echo "Este script desinstalará completamente vlmcsd del sistema"
echo ""

# Verificar que se ejecute como root
if [[ $EUID -ne 0 ]]; then
   echo -e "${RED}❌ Este script debe ejecutarse como root (usa sudo)${NC}" 
   exit 1
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

# Confirmación de desinstalación
confirm_uninstall() {
    echo -e "${YELLOW}⚠️  ADVERTENCIA: Esta operación eliminará completamente vlmcsd${NC}"
    echo ""
    echo "Se eliminarán:"
    echo "  • Servicio systemd"
    echo "  • Binarios de vlmcsd"
    echo "  • Archivos de configuración"
    echo "  • Usuario del sistema"
    echo "  • Logs del sistema"
    echo "  • Reglas de firewall"
    echo ""
    
    while true; do
        echo -n -e "${CYAN}¿Estás seguro de que quieres desinstalar vlmcsd? [y/N]: ${NC}"
        read -r response
        case $response in
            [Yy]|[Yy][Ee][Ss]) 
                log_info "Procediendo con la desinstalación..."
                break
                ;;
            [Nn]|[Nn][Oo]|"")
                log_info "Desinstalación cancelada por el usuario"
                exit 0
                ;;
            *)
                echo -e "${RED}Por favor responde 'y' (sí) o 'n' (no)${NC}"
                ;;
        esac
    done
}

# Detener y deshabilitar servicio
stop_service() {
    log_info "Deteniendo y deshabilitando servicio vlmcsd..."
    
    if systemctl is-active --quiet vlmcsd 2>/dev/null; then
        systemctl stop vlmcsd
        log_success "Servicio vlmcsd detenido"
    else
        log_info "Servicio vlmcsd no estaba ejecutándose"
    fi
    
    if systemctl is-enabled --quiet vlmcsd 2>/dev/null; then
        systemctl disable vlmcsd
        log_success "Servicio vlmcsd deshabilitado"
    else
        log_info "Servicio vlmcsd no estaba habilitado"
    fi
}

# Eliminar servicio systemd
remove_service() {
    log_info "Eliminando archivos de servicio systemd..."
    
    if [ -f "$SERVICE_FILE" ]; then
        rm -f "$SERVICE_FILE"
        log_success "Archivo de servicio eliminado: $SERVICE_FILE"
    else
        log_info "Archivo de servicio no encontrado"
    fi
    
    # Recargar systemd
    systemctl daemon-reload
    log_success "Configuración de systemd recargada"
}

# Eliminar binarios
remove_binaries() {
    log_info "Eliminando binarios de vlmcsd..."
    
    BINARIES=("vlmcsd" "vlmcs" "vlmcsdmulti")
    
    for binary in "${BINARIES[@]}"; do
        if [ -f "$INSTALL_DIR/$binary" ]; then
            rm -f "$INSTALL_DIR/$binary"
            log_success "Binario eliminado: $INSTALL_DIR/$binary"
        else
            log_info "Binario no encontrado: $INSTALL_DIR/$binary"
        fi
    done
}

# Eliminar configuración
remove_configuration() {
    log_info "Eliminando archivos de configuración..."
    
    if [ -d "$CONFIG_DIR" ]; then
        rm -rf "$CONFIG_DIR"
        log_success "Directorio de configuración eliminado: $CONFIG_DIR"
    else
        log_info "Directorio de configuración no encontrado"
    fi
}

# Eliminar logs
remove_logs() {
    log_info "Eliminando archivos de log..."
    
    # Log específico de vlmcsd
    if [ -f "$LOG_FILE" ]; then
        rm -f "$LOG_FILE"
        log_success "Archivo de log eliminado: $LOG_FILE"
    else
        log_info "Archivo de log no encontrado"
    fi
    
    # Logs de systemd (opcional, comentado por seguridad)
    # journalctl --vacuum-time=1s --unit=vlmcsd >/dev/null 2>&1 || true
    log_info "Logs de systemd conservados (usar 'sudo journalctl --vacuum-time=1d' para limpiar)"
}

# Eliminar usuario del sistema
remove_user() {
    log_info "Eliminando usuario del sistema..."
    
    if id "$USER" &>/dev/null; then
        # Verificar que no haya procesos ejecutándose bajo este usuario
        if pgrep -u "$USER" >/dev/null 2>&1; then
            log_warning "Hay procesos ejecutándose bajo el usuario $USER. Terminándolos..."
            pkill -u "$USER" || true
            sleep 2
        fi
        
        userdel "$USER" 2>/dev/null || true
        log_success "Usuario $USER eliminado"
    else
        log_info "Usuario $USER no existe"
    fi
}

# Limpiar reglas de firewall
cleanup_firewall() {
    log_info "Limpiando reglas de firewall..."
    
    if command -v ufw >/dev/null 2>&1; then
        if ufw status | grep -q "Status: active"; then
            # Eliminar regla específica del puerto 1688
            ufw delete allow 1688/tcp >/dev/null 2>&1 || true
            log_success "Regla UFW para puerto 1688 eliminada"
        else
            log_info "UFW no está activo"
        fi
    else
        log_info "UFW no está instalado"
    fi
    
    # Nota sobre iptables
    log_info "Nota: Si configuraste reglas iptables manualmente, elimínalas manualmente"
}

# Verificar limpieza
verify_cleanup() {
    log_info "Verificando que la desinstalación esté completa..."
    
    ISSUES=()
    
    # Verificar servicio
    if systemctl list-unit-files | grep -q vlmcsd; then
        ISSUES+=("Servicio systemd aún presente")
    fi
    
    # Verificar binarios
    for binary in vlmcsd vlmcs vlmcsdmulti; do
        if [ -f "$INSTALL_DIR/$binary" ]; then
            ISSUES+=("Binario aún presente: $INSTALL_DIR/$binary")
        fi
    done
    
    # Verificar configuración
    if [ -d "$CONFIG_DIR" ]; then
        ISSUES+=("Directorio de configuración aún presente: $CONFIG_DIR")
    fi
    
    # Verificar usuario
    if id "$USER" &>/dev/null; then
        ISSUES+=("Usuario $USER aún existe")
    fi
    
    # Verificar puerto
    if netstat -tlnp 2>/dev/null | grep -q ":1688 "; then
        ISSUES+=("Puerto 1688 aún está en uso")
    fi
    
    if [ ${#ISSUES[@]} -eq 0 ]; then
        log_success "Desinstalación completada correctamente"
        return 0
    else
        log_warning "Se encontraron algunos problemas:"
        for issue in "${ISSUES[@]}"; do
            echo "  - $issue"
        done
        return 1
    fi
}

# Mostrar información final
show_final_info() {
    echo ""
    echo -e "${GREEN}🎉 ¡Desinstalación de vlmcsd completada!${NC}"
    echo ""
    echo -e "${BLUE}📋 Resumen de lo eliminado:${NC}"
    echo "  ✅ Servicio systemd detenido y eliminado"
    echo "  ✅ Binarios eliminados de $INSTALL_DIR"
    echo "  ✅ Configuración eliminada de $CONFIG_DIR"
    echo "  ✅ Usuario del sistema eliminado"
    echo "  ✅ Logs de aplicación eliminados"
    echo "  ✅ Reglas de firewall limpiadas"
    echo ""
    echo -e "${BLUE}🔧 Para reinstalar vlmcsd:${NC}"
    echo "  curl -fsSL https://raw.githubusercontent.com/gilberth/kmsvlmcsd/master/scripts/install-ubuntu.sh | sudo bash"
    echo ""
    echo -e "${BLUE}🧹 Limpieza adicional opcional:${NC}"
    echo "  # Limpiar logs de systemd:"
    echo "  sudo journalctl --vacuum-time=1d"
    echo ""
    echo -e "${BLUE}📝 Si configuraste iptables manualmente:${NC}"
    echo "  sudo iptables -D INPUT -p tcp --dport 1688 -j ACCEPT"
    echo ""
    echo -e "${GREEN}✨ Sistema limpio - vlmcsd ha sido completamente eliminado${NC}"
}

# Ejecución principal
main() {
    confirm_uninstall
    stop_service
    remove_service
    remove_binaries
    remove_configuration
    remove_logs
    remove_user
    cleanup_firewall
    
    if verify_cleanup; then
        show_final_info
    else
        echo ""
        log_warning "La desinstalación se completó pero con algunos problemas menores"
        log_info "Puedes ignorar estos problemas o solucionarlos manualmente"
        show_final_info
    fi
}

# Trap para limpieza en caso de error
cleanup_on_error() {
    echo ""
    log_error "Error durante la desinstalación"
    log_info "El sistema puede estar en un estado parcialmente desinstalado"
    log_info "Puedes ejecutar el script nuevamente para completar la desinstalación"
}

trap cleanup_on_error ERR

# Ejecutar desinstalación
main "$@"

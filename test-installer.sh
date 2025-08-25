#!/bin/bash

# Test script para verificar instalador vlmcsd
# Simula la ejecución como root saltándose las verificaciones

set -e

# Colores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Variables globales
GITHUB_REPO="gilberth/kmsvlmcsd"
ARCH="x64"

# Funciones de logging del script original
log_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

log_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

log_error() {
    echo -e "${RED}❌ $1${NC}"
}

log_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

# Función select_configuration simulada (usa valores por defecto)
select_configuration() {
    VARIANT="full"
    CRYPTO="openssl"
    log_success "Configuración de prueba: $VARIANT + $CRYPTO"
}

# Función get_latest_release (copiada del script original)
get_latest_release() {
    echo "🔍 Obteniendo información de la última versión..."
    
    # Intentar obtener la última release de GitHub
    LATEST_RELEASE=$(curl -s "https://api.github.com/repos/$GITHUB_REPO/releases/latest" 2>/dev/null)
    
    if [ $? -eq 0 ] && echo "$LATEST_RELEASE" | jq -e '.tag_name' >/dev/null 2>&1; then
        VERSION=$(echo "$LATEST_RELEASE" | jq -r '.tag_name')
        echo "✓ Última versión encontrada: $VERSION"
        return 0
    else
        echo "❌ No se pudo obtener información de releases desde GitHub"
        
        # Fallback: intentar obtener el último tag
        echo "🔄 Intentando obtener el último tag..."
        LATEST_TAG=$(curl -s "https://api.github.com/repos/$GITHUB_REPO/tags" 2>/dev/null | jq -r '.[0].name' 2>/dev/null)
        
        if [ -n "$LATEST_TAG" ] && [ "$LATEST_TAG" != "null" ]; then
            VERSION="$LATEST_TAG"
            echo "✓ Último tag encontrado: $VERSION"
            return 0
        else
            echo "❌ No se pudo obtener información de tags"
            echo "ℹ️  Esto puede ocurrir si:"
            echo "   - El repositorio no tiene releases publicados aún"
            echo "   - Hay problemas de conectividad"
            echo "   - Los workflows están en proceso"
            return 1
        fi
    fi
}

# Función de descarga simplificada para prueba
test_download() {
    local config_name=$1
    
    log_info "Probando descarga para configuración: $config_name"
    
    if [ -z "$LATEST_VERSION" ]; then
        log_error "Error: No se ha determinado la versión a descargar"
        return 1
    fi
    
    # Construir URL igual que el script original
    DOWNLOAD_URL="https://github.com/$GITHUB_REPO/releases/download/$LATEST_VERSION/vlmcsd-ubuntu-$ARCH-$VARIANT-$CRYPTO-$LATEST_VERSION.tar.gz"
    
    log_info "URL de descarga: $DOWNLOAD_URL"
    
    # Probar acceso a la URL
    if curl -f -s -I "$DOWNLOAD_URL" >/dev/null 2>&1; then
        log_success "✓ URL accesible"
        
        # Probar descarga (solo los primeros bytes para no desperdiciar ancho de banda)
        if curl -f -s -r 0-1023 "$DOWNLOAD_URL" >/dev/null 2>&1; then
            log_success "✓ Descarga funcional"
            return 0
        else
            log_error "❌ Error en descarga"
            return 1
        fi
    else
        log_error "❌ URL no accesible"
        return 1
    fi
}

# Función principal de prueba
main_test() {
    echo -e "${BLUE}=== Prueba del Script de Instalación vlmcsd ===${NC}"
    echo ""
    
    # Paso 1: Configuración
    log_info "1. Configurando parámetros de prueba..."
    select_configuration
    echo ""
    
    # Paso 2: Obtener versión
    log_info "2. Obteniendo última versión..."
    if get_latest_release; then
        LATEST_VERSION="$VERSION"
        log_success "Versión detectada: $LATEST_VERSION"
    else
        log_error "No se pudo detectar la última versión"
        exit 1
    fi
    echo ""
    
    # Paso 3: Probar descarga
    log_info "3. Probando descarga de binarios..."
    if test_download "$VARIANT-$CRYPTO"; then
        log_success "Descarga verificada exitosamente"
    else
        log_error "Error en verificación de descarga"
        exit 1
    fi
    echo ""
    
    # Mostrar resumen
    echo -e "${GREEN}=== Resumen de la Prueba ===${NC}"
    echo "  Repositorio: $GITHUB_REPO"
    echo "  Versión: $LATEST_VERSION"
    echo "  Configuración: $VARIANT + $CRYPTO"
    echo "  URL: $DOWNLOAD_URL"
    echo ""
    log_success "Todos los componentes funcionan correctamente"
    echo ""
    echo -e "${CYAN}El script de instalación debería funcionar ahora.${NC}"
    echo -e "${CYAN}Para ejecutar: sudo bash scripts/install-ubuntu.sh${NC}"
}

# Ejecutar prueba
main_test

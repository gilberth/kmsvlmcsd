#!/bin/bash

# Script de prueba para debug del instalador
set -e

GITHUB_REPO="gilberth/kmsvlmcsd"
ARCH="x64"
VARIANT="full"
CRYPTO="openssl"

# Función para obtener la última versión
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
        return 1
    fi
}

# Probar la función
echo "=== Prueba de get_latest_release ==="
if get_latest_release; then
    LATEST_VERSION="$VERSION"
    echo "✓ LATEST_VERSION asignada: $LATEST_VERSION"
else
    echo "❌ Error al obtener versión"
    exit 1
fi

echo ""
echo "=== Construyendo URLs de prueba ==="

# Construir la URL como lo hace el script original
DOWNLOAD_URL="https://github.com/$GITHUB_REPO/releases/download/$LATEST_VERSION/vlmcsd-ubuntu-$ARCH-$VARIANT-$CRYPTO-$LATEST_VERSION.tar.gz"

echo "Variables:"
echo "  GITHUB_REPO: $GITHUB_REPO"
echo "  ARCH: $ARCH"
echo "  VARIANT: $VARIANT"
echo "  CRYPTO: $CRYPTO"
echo "  LATEST_VERSION: $LATEST_VERSION"
echo ""
echo "URL construida:"
echo "  $DOWNLOAD_URL"

echo ""
echo "=== Probando acceso a la URL ==="

# Probar si existe
if curl -f -s -I "$DOWNLOAD_URL" >/dev/null 2>&1; then
    echo "✓ URL accesible: $DOWNLOAD_URL"
    
    # Probar descarga a un archivo temporal
    TEMP_FILE="/tmp/test-vlmcsd-download.tar.gz"
    echo "🔄 Probando descarga..."
    
    if curl -f -s -L -o "$TEMP_FILE" "$DOWNLOAD_URL"; then
        echo "✓ Descarga exitosa"
        echo "📊 Tamaño del archivo: $(du -h "$TEMP_FILE" | cut -f1)"
        echo "📋 Tipo de archivo: $(file "$TEMP_FILE")"
        
        # Limpiar
        rm -f "$TEMP_FILE"
        echo "✓ Archivo temporal eliminado"
    else
        echo "❌ Error en la descarga"
    fi
else
    echo "❌ URL no accesible: $DOWNLOAD_URL"
    
    echo ""
    echo "=== Diagnóstico de posibles problemas ==="
    
    # Probar diferentes variaciones
    echo "🔍 Probando variaciones de la URL..."
    
    # URL sin el sufijo de versión en el nombre del archivo
    ALT_URL1="https://github.com/$GITHUB_REPO/releases/download/$LATEST_VERSION/vlmcsd-ubuntu-$ARCH-$VARIANT-$CRYPTO.tar.gz"
    echo "  Probando: $ALT_URL1"
    if curl -f -s -I "$ALT_URL1" >/dev/null 2>&1; then
        echo "  ✓ Funciona sin sufijo de versión"
    else
        echo "  ❌ No funciona"
    fi
    
    # Listar archivos disponibles en el release
    echo ""
    echo "🔍 Listando archivos disponibles en el release..."
    curl -s "https://api.github.com/repos/$GITHUB_REPO/releases/latest" | jq -r '.assets[].name' | while read -r asset; do
        echo "  - $asset"
    done
fi

echo ""
echo "=== Fin de la prueba ==="

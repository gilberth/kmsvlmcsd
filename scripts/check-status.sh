#!/bin/bash

# Script de verificación de estado de vlmcsd
# Verifica el estado de workflows y releases en GitHub

set -e

# Colores para output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

GITHUB_REPO="gilberth/kmsvlmcsd"

echo -e "${BLUE}=== Verificador de Estado vlmcsd ===${NC}"
echo ""

# Función para verificar dependencias
check_dependencies() {
    echo -e "${BLUE}🔧 Verificando dependencias...${NC}"
    
    local missing_deps=()
    
    if ! command -v curl >/dev/null 2>&1; then
        missing_deps+=("curl")
    fi
    
    if ! command -v jq >/dev/null 2>&1; then
        missing_deps+=("jq")
    fi
    
    if [ ${#missing_deps[@]} -gt 0 ]; then
        echo -e "${RED}❌ Dependencias faltantes: ${missing_deps[*]}${NC}"
        echo -e "${YELLOW}💡 Para instalar:${NC}"
        echo "   sudo apt-get update && sudo apt-get install -y curl jq"
        return 1
    else
        echo -e "${GREEN}✓ Todas las dependencias están disponibles${NC}"
        return 0
    fi
}

# Función para verificar releases
check_releases() {
    echo -e "${BLUE}📦 Verificando releases...${NC}"
    
    local api_url="https://api.github.com/repos/$GITHUB_REPO/releases"
    local releases_data
    
    if releases_data=$(curl -s "$api_url" 2>/dev/null); then
        local releases_count=$(echo "$releases_data" | jq length 2>/dev/null || echo "0")
        
        if [ "$releases_count" -gt 0 ]; then
            echo -e "${GREEN}✓ Encontrados $releases_count release(s)${NC}"
            
            # Mostrar información del último release
            local latest_release=$(echo "$releases_data" | jq -r '.[0]')
            local tag_name=$(echo "$latest_release" | jq -r '.tag_name')
            local published_at=$(echo "$latest_release" | jq -r '.published_at')
            local assets_count=$(echo "$latest_release" | jq '.assets | length')
            
            echo "   📌 Último: $tag_name"
            echo "   📅 Publicado: $published_at"
            echo "   📁 Assets: $assets_count archivos"
            
            if [ "$assets_count" -gt 0 ]; then
                echo -e "${GREEN}   ✓ Release listo para descarga${NC}"
                
                # Listar assets disponibles
                echo "   📋 Archivos disponibles:"
                echo "$latest_release" | jq -r '.assets[].name' | sed 's/^/      - /'
            else
                echo -e "${YELLOW}   ⚠️  Release sin archivos binarios${NC}"
            fi
        else
            echo -e "${YELLOW}⚠️  No se encontraron releases publicados${NC}"
            return 1
        fi
    else
        echo -e "${RED}❌ Error al acceder a la API de GitHub${NC}"
        return 1
    fi
}

# Función para verificar tags
check_tags() {
    echo -e "${BLUE}🏷️  Verificando tags...${NC}"
    
    local api_url="https://api.github.com/repos/$GITHUB_REPO/tags"
    local tags_data
    
    if tags_data=$(curl -s "$api_url" 2>/dev/null); then
        local tags_count=$(echo "$tags_data" | jq length 2>/dev/null || echo "0")
        
        if [ "$tags_count" -gt 0 ]; then
            echo -e "${GREEN}✓ Encontrados $tags_count tag(s)${NC}"
            
            # Mostrar los últimos 3 tags
            echo "   📌 Tags recientes:"
            echo "$tags_data" | jq -r '.[0:3][].name' | sed 's/^/      - /'
        else
            echo -e "${YELLOW}⚠️  No se encontraron tags${NC}"
            return 1
        fi
    else
        echo -e "${RED}❌ Error al acceder a tags de GitHub${NC}"
        return 1
    fi
}

# Función para verificar workflows
check_workflows() {
    echo -e "${BLUE}⚙️  Verificando workflows...${NC}"
    
    local api_url="https://api.github.com/repos/$GITHUB_REPO/actions/runs?per_page=5"
    local runs_data
    
    if runs_data=$(curl -s "$api_url" 2>/dev/null); then
        local total_count=$(echo "$runs_data" | jq -r '.total_count' 2>/dev/null || echo "0")
        
        if [ "$total_count" -gt 0 ]; then
            echo -e "${GREEN}✓ Workflow history encontrado ($total_count ejecuciones)${NC}"
            
            # Mostrar información de las últimas ejecuciones
            echo "   📊 Últimas ejecuciones:"
            echo "$runs_data" | jq -r '.workflow_runs[0:3][] | "      - \(.status) | \(.conclusion // "en progreso") | \(.created_at) | \(.name)"'
        else
            echo -e "${YELLOW}⚠️  No se encontraron ejecuciones de workflow${NC}"
        fi
    else
        echo -e "${RED}❌ Error al acceder a workflows de GitHub${NC}"
    fi
}

# Función para mostrar recomendaciones
show_recommendations() {
    echo ""
    echo -e "${BLUE}💡 Recomendaciones:${NC}"
    echo ""
    
    # Verificar si hay releases
    if ! check_releases >/dev/null 2>&1; then
        echo -e "${YELLOW}📦 Sin releases disponibles:${NC}"
        echo "   ➜ Espera a que el workflow complete la compilación"
        echo "   ➜ Revisa: https://github.com/$GITHUB_REPO/actions"
        echo ""
    fi
    
    # Verificar si hay tags
    if ! check_tags >/dev/null 2>&1; then
        echo -e "${YELLOW}🏷️  Sin tags:${NC}"
        echo "   ➜ Crea un tag: git tag v1.0.1 && git push origin v1.0.1"
        echo "   ➜ Esto activará la creación automática de releases"
        echo ""
    fi
    
    echo -e "${BLUE}🔗 Enlaces útiles:${NC}"
    echo "   📦 Releases: https://github.com/$GITHUB_REPO/releases"
    echo "   ⚙️  Actions:  https://github.com/$GITHUB_REPO/actions"
    echo "   📋 Repo:     https://github.com/$GITHUB_REPO"
}

# Función principal
main() {
    if ! check_dependencies; then
        exit 1
    fi
    
    echo ""
    
    check_releases
    echo ""
    
    check_tags
    echo ""
    
    check_workflows
    
    show_recommendations
    
    echo ""
    echo -e "${GREEN}✓ Verificación completada${NC}"
}

# Ejecutar solo si el script es llamado directamente
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi

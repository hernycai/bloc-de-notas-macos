#!/bin/bash
set -e

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$DIR"

echo "==> Verificando existencia de Bloc de notas.app..."
if [ ! -d "Bloc de notas.app" ]; then
    echo "Bloc de notas.app no encontrado. Compilando..."
    ./build.sh
fi

DMG_NAME="Bloc de notas.dmg"
STAGING_DIR="dmg_staging"

echo "==> Preparando contenido para el instalador DMG..."
rm -rf "$STAGING_DIR" "$DMG_NAME"
mkdir -p "$STAGING_DIR"

# Copiar la aplicación
cp -R "Bloc de notas.app" "$STAGING_DIR/"

# Crear acceso directo a /Applications para arrastrar y soltar
ln -s /Applications "$STAGING_DIR/Applications"

echo "==> Creando imagen de disco comprimida ($DMG_NAME)..."
hdiutil create -volname "Bloc de notas" -srcfolder "$STAGING_DIR" -ov -format UDZO "$DMG_NAME"

# Limpiar directorio temporal
rm -rf "$STAGING_DIR"

echo "==> ✅ ¡Instalador DMG creado con éxito!"
echo "Ubicación: $DIR/$DMG_NAME"
ls -lh "$DMG_NAME"

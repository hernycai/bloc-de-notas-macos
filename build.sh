#!/bin/bash
set -e

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$DIR"

echo "==> Generando icono de Windows Notepad..."
if [ ! -f "AppIcon.icns" ]; then
    swift generate_icon.swift
    iconutil -c icns AppIcon.iconset -o AppIcon.icns
fi

echo "==> Compilando Bloc de notas (Swift nativo)..."
swiftc -O src/*.swift -o "Bloc de notas"

echo "==> Empaquetando Bloc de notas.app..."
APP_DIR="Bloc de notas.app"
rm -rf "$APP_DIR"
mkdir -p "$APP_DIR/Contents/MacOS"
mkdir -p "$APP_DIR/Contents/Resources"

cp "Bloc de notas" "$APP_DIR/Contents/MacOS/Bloc de notas"
chmod +x "$APP_DIR/Contents/MacOS/Bloc de notas"
cp Info.plist "$APP_DIR/Contents/Info.plist"
cp AppIcon.icns "$APP_DIR/Contents/Resources/AppIcon.icns"

echo "==> Firmando aplicación..."
codesign --force --deep --sign - "$APP_DIR"

echo "==> Instalando en /Applications/Bloc de notas.app..."
rm -rf "/Applications/$APP_DIR"
cp -R "$APP_DIR" "/Applications/"

echo "==> ✅ Éxito: Bloc de notas está listo y disponible en /Applications!"

echo "==> Generando instalador DMG..."
./create_dmg.sh

#!/bin/bash
set -e

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$DIR"

echo "==> Generando icono de Windows Notepad..."
if [ ! -f "AppIcon.icns" ]; then
    swift generate_icon.swift
    iconutil -c icns AppIcon.iconset -o AppIcon.icns
fi

echo "==> Compilando Bloc de notas para Apple Silicon (arm64)..."
swiftc -target arm64-apple-macos11.0 -O src/*.swift -o "Bloc de notas_arm64"

echo "==> Compilando Bloc de notas para Intel (x86_64)..."
swiftc -target x86_64-apple-macos11.0 -O src/*.swift -o "Bloc de notas_x86_64"

echo "==> Creando binario Universal 2 (arm64 + x86_64)..."
lipo -create -output "Bloc de notas" "Bloc de notas_arm64" "Bloc de notas_x86_64"
rm -f "Bloc de notas_arm64" "Bloc de notas_x86_64"
lipo -info "Bloc de notas"

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

echo "==> ✅ Éxito: Bloc de notas.app empaquetado localmente!"

echo "==> Generando instalador DMG..."
./create_dmg.sh

#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

OUTPUT_DIR="${1:-$ROOT_DIR/dist}"
mkdir -p "$OUTPUT_DIR"

echo "Building Moto Buds CLI (Rust)..."
cargo build --release

echo "Building Moto Buds GUI (Qt6 / QML)..."
cmake -B build -S . -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX=/usr -G Ninja
ninja -C build

echo "Setting up AppDir..."
APPDIR="$ROOT_DIR/build/AppDir"
rm -rf "$APPDIR"
mkdir -p "$APPDIR/usr/bin"
mkdir -p "$APPDIR/usr/share/applications"
mkdir -p "$APPDIR/usr/share/icons/hicolor/512x512/apps"
mkdir -p "$APPDIR/usr/share/icons/hicolor/192x192/apps"
mkdir -p "$APPDIR/usr/share/metainfo"
mkdir -p "$APPDIR/usr/lib"

# Copy binaries
cp -v target/release/moto-buds "$APPDIR/usr/bin/"
cp -v build/gui/moto-buds-gui "$APPDIR/usr/bin/"

# Copy desktop, icon, and metainfo
cp -v data/com.motorola.motobuds.desktop "$APPDIR/com.motorola.motobuds.desktop"
cp -v data/com.motorola.motobuds.desktop "$APPDIR/usr/share/applications/"
cp -v data/com.motorola.motobuds.metainfo.xml "$APPDIR/usr/share/metainfo/"
cp -v assets/icon.png "$APPDIR/moto-buds.png"
cp -v assets/icon.png "$APPDIR/usr/share/icons/hicolor/512x512/apps/moto-buds.png"
cp -v assets/icon.png "$APPDIR/usr/share/icons/hicolor/192x192/apps/moto-buds.png"

# AppRun script
cat << 'EOF' > "$APPDIR/AppRun"
#!/bin/sh
HERE="$(dirname "$(readlink -f "${0}")")"
export PATH="${HERE}/usr/bin:${PATH}"
export LD_LIBRARY_PATH="${HERE}/usr/lib:${HERE}/usr/lib/x86_64-linux-gnu:${LD_LIBRARY_PATH}"
export QML2_IMPORT_PATH="${HERE}/usr/lib/qt6/qml:${HERE}/usr/qml:${QML2_IMPORT_PATH}"
export QT_PLUGIN_PATH="${HERE}/usr/lib/qt6/plugins:${QT_PLUGIN_PATH}"

case "$(basename "$0")" in
    moto-buds)
        exec "${HERE}/usr/bin/moto-buds" "$@"
        ;;
    *)
        exec "${HERE}/usr/bin/moto-buds-gui" "$@"
        ;;
esac
EOF
chmod +x "$APPDIR/AppRun"

# Check tools
TOOLS_DIR="$ROOT_DIR/build/tools"
mkdir -p "$TOOLS_DIR"

if [ ! -f "$TOOLS_DIR/linuxdeploy" ]; then
    echo "Downloading linuxdeploy..."
    curl -sLo "$TOOLS_DIR/linuxdeploy" https://github.com/linuxdeploy/linuxdeploy/releases/download/continuous/linuxdeploy-x86_64.AppImage
    chmod +x "$TOOLS_DIR/linuxdeploy"
fi

if [ ! -f "$TOOLS_DIR/appimagetool" ]; then
    echo "Downloading appimagetool..."
    curl -sLo "$TOOLS_DIR/appimagetool" https://github.com/AppImage/AppImageKit/releases/download/continuous/appimagetool-x86_64.AppImage
    chmod +x "$TOOLS_DIR/appimagetool"
fi

export APPIMAGE_EXTRACT_AND_RUN=1

echo "Deploying dependencies with linuxdeploy..."
"$TOOLS_DIR/linuxdeploy" --appdir "$APPDIR" \
    --executable "$APPDIR/usr/bin/moto-buds-gui" \
    --desktop-file "$APPDIR/com.motorola.motobuds.desktop" \
    --icon-file "$APPDIR/moto-buds.png" || true

echo "Packaging AppImage with appimagetool..."
ARCH=x86_64 "$TOOLS_DIR/appimagetool" "$APPDIR" "$OUTPUT_DIR/Moto_Buds-x86_64.AppImage"

echo "AppImage created successfully at $OUTPUT_DIR/Moto_Buds-x86_64.AppImage"

#!/bin/bash
set -e

# Path to the input high-res logo
INPUT_IMAGE="Resources/app_logo.png"
OUTPUT_ICNS="Resources/ShakeShare.icns"
ICONSET_DIR="Resources/ShakeShare.iconset"

if [ ! -f "$INPUT_IMAGE" ]; then
    echo "Error: $INPUT_IMAGE not found!"
    exit 1
fi

echo "Creating iconset directory..."
mkdir -p "$ICONSET_DIR"

echo "Resizing images using sips..."
sips -s format png -z 16 16     "$INPUT_IMAGE" --out "$ICONSET_DIR/icon_16x16.png" > /dev/null
sips -s format png -z 32 32     "$INPUT_IMAGE" --out "$ICONSET_DIR/icon_16x16@2x.png" > /dev/null
sips -s format png -z 32 32     "$INPUT_IMAGE" --out "$ICONSET_DIR/icon_32x32.png" > /dev/null
sips -s format png -z 64 64     "$INPUT_IMAGE" --out "$ICONSET_DIR/icon_32x32@2x.png" > /dev/null
sips -s format png -z 128 128   "$INPUT_IMAGE" --out "$ICONSET_DIR/icon_128x128.png" > /dev/null
sips -s format png -z 256 256   "$INPUT_IMAGE" --out "$ICONSET_DIR/icon_128x128@2x.png" > /dev/null
sips -s format png -z 256 256   "$INPUT_IMAGE" --out "$ICONSET_DIR/icon_256x256.png" > /dev/null
sips -s format png -z 512 512   "$INPUT_IMAGE" --out "$ICONSET_DIR/icon_256x256@2x.png" > /dev/null
sips -s format png -z 512 512   "$INPUT_IMAGE" --out "$ICONSET_DIR/icon_512x512.png" > /dev/null
sips -s format png -z 1024 1024 "$INPUT_IMAGE" --out "$ICONSET_DIR/icon_512x512@2x.png" > /dev/null

echo "Compiling .icns file using iconutil..."
iconutil -c icns "$ICONSET_DIR" -o "$OUTPUT_ICNS"

echo "Cleaning up temporary iconset..."
rm -rf "$ICONSET_DIR"

echo "Icon successfully created at $OUTPUT_ICNS"

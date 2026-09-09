# Makefile for ShakeShare

APP_NAME = ShakeShare
APP_BUNDLE = $(APP_NAME).app
DMG_NAME = $(APP_NAME).dmg
SDK_PATH = $(shell xcrun --show-sdk-path)
TARGET = arm64-apple-macos15.0

.PHONY: all build dmg clean run

all: build

build:
	@echo "Creating App Bundle structure..."
	mkdir -p $(APP_BUNDLE)/Contents/MacOS
	mkdir -p $(APP_BUNDLE)/Contents/Resources
	@echo "Copying Info.plist..."
	cp Info.plist $(APP_BUNDLE)/Contents/Info.plist
	@echo "Copying app icon..."
	cp Resources/ShakeShare.icns $(APP_BUNDLE)/Contents/Resources/
	@echo "Compiling Swift source files..."
	swiftc -sdk $(SDK_PATH) -target $(TARGET) -O -o $(APP_BUNDLE)/Contents/MacOS/$(APP_NAME) Sources/*.swift
	@echo "Performing ad-hoc code signing..."
	codesign --force --deep --sign - $(APP_BUNDLE)
	@echo "Build successful! $(APP_BUNDLE) is ready."

dmg: build
	@echo "Preparing temporary packaging directory..."
	rm -rf dmg_temp
	mkdir -p dmg_temp
	cp -R $(APP_BUNDLE) dmg_temp/
	ln -s /Applications dmg_temp/Applications
	@echo "Setting custom volume icon for DMG..."
	cp Resources/ShakeShare.icns dmg_temp/.VolumeIcon.icns
	SetFile -a C dmg_temp
	@echo "Creating $(DMG_NAME)..."
	rm -f $(DMG_NAME)
	hdiutil create -volname "ShakeShare" -srcfolder dmg_temp -ov -format UDZO $(DMG_NAME)
	rm -rf dmg_temp
	@echo "Applying custom icon to DMG file..."
	swift -e 'import Cocoa; NSWorkspace.shared.setIcon(NSImage(contentsOfFile: "Resources/app_logo.png")!, forFile: "$(DMG_NAME)", options: [])'
	@echo "DMG package $(DMG_NAME) created successfully."

clean:
	@echo "Cleaning build artifacts..."
	rm -rf $(APP_BUNDLE) $(DMG_NAME) dmg_temp

run: build
	@echo "Running ShakeShare..."
	open $(APP_BUNDLE)

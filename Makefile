


# Default goal
.DEFAULT_GOAL := help

# Variables
FLUTTER := flutter

## Build Android APK (release)
apkRelease:
	$(FLUTTER) build apk --release

## Build Android App Bundle (release) - this is the one you upload to Play Store
bundleRelease:
	$(FLUTTER) build appbundle --release

## Build Android APK (debug)
apkDebug:
	$(FLUTTER) build apk --debug

## Clean build artifacts
clean:
	$(FLUTTER) clean

## Get dependencies
get:
	$(FLUTTER) pub get

## Run analyzer
analyze:
	$(FLUTTER) analyze

## Format code
format:
	$(FLUTTER) format .

## Run tests
test:
	$(FLUTTER) test

## Show help
help:
	@echo ""
	@echo "Available make commands:"
	@echo "  make apkRelease     - Build release APK"
	@echo "  make bundleRelease  - Build release App Bundle (AAB)"
	@echo "  make apkDebug       - Build debug APK"
	@echo "  make clean          - Clean build artifacts"
	@echo "  make get            - Get pub dependencies"
	@echo "  make analyze        - Run analyzer"
	@echo "  make format         - Format code"
	@echo "  make test           - Run tests"
	@echo ""

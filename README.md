# Status Mate

A Flutter application for managing and sharing status updates.

## Getting Started

### Prerequisites
- Flutter SDK
- Android Studio / Xcode
- Git

### Setup
1. Clone the repository
2. Run `flutter pub get` to install dependencies
3. Run `flutter run` to start the app

## GitHub Actions Deployment

This project uses GitHub Actions for automated Android builds. The workflow is triggered when you push a version tag (e.g., `v1.0.0`).

### Setup Instructions

1. **Create a new keystore** (if you haven't already):
   ```bash
   keytool -genkey -v -keystore upload-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload -storetype JKS
   ```

2. **Add GitHub Secrets** in your repository settings (Settings > Secrets and variables > Actions):
   - `KEYSTORE`: Base64-encoded content of your keystore file
     ```bash
     openssl base64 -in path/to/your/upload-keystore.jks | pbcopy
     ```
   - `KEY_PASSWORD`: The password for your key
   - `STORE_PASSWORD`: The password for your keystore

3. **Create a new release** by pushing a version tag:
   ```bash
   git tag -a v1.0.0 -m "First release"
   git push origin v1.0.0
   ```

The workflow will automatically:
- Build the release APK and App Bundle
- Upload them as artifacts
- Create a GitHub release with the App Bundle and mapping file

## Development

### Project Structure
```
lib/
  app/
    modules/
      status/         # Status feature module
        controllers/  # Business logic
        view/         # UI components
          widgets/    # Reusable widgets
          status_view.dart
```

### Dependencies
- [Flutter](https://flutter.dev/)
- [Dart](https://dart.dev/)

## Resources
- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)
- [Flutter documentation](https://docs.flutter.dev/)

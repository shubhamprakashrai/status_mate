# Status Mate

A Flutter app to view and save WhatsApp statuses.

## App Info

| Key              | Value                  |
|------------------|------------------------|
| Package ID       | `com.status.mate`      |
| App Name         | Status Mate            |
| Current Version  | `1.0.7+7`             |
| Min SDK          | 24                     |
| Target SDK       | 35                     |
| Flutter SDK      | `^3.6.0`              |

## Project Structure

```
lib/
├── main.dart
├── app/
│   └── modules/
│       └── status/
│           ├── controllers/
│           │   └── status_controller.dart    # Main status logic, download, permissions
│           └── view/
│               ├── status_view.dart          # Status list UI
│               └── widgets/
│                   └── permission_dialog.dart # Permission request dialog
├── core/
│   ├── utils/
│   │   ├── permission_utils.dart             # Permission handling utilities
│   │   ├── whatsapp_status_utils.dart        # WhatsApp status access (direct + SAF)
│   │   └── storage_utils.dart                # File storage utilities
│   ├── constants/
│   │   └── app_strings.dart
│   └── logger/
│       └── app_logger.dart
```

## Keystore / Signing

| Key            | Value                    |
|----------------|--------------------------|
| Keystore File  | `android/status_mate.jks`|
| Key Alias      | `statusmate`             |
| Store Password | `StatusMate@123d`        |
| Key Password   | `StatusMate@123d`        |
| Config File    | `android/key.properties` |

> **Note:** The current JKS was regenerated on 2026-02-11. An upload key reset has been requested on Google Play Console. Once approved, this keystore will be the new upload key.

### Generate PEM certificate (for Play Console upload key reset)

```bash
keytool -export -rfc -keystore android/status_mate.jks -alias statusmate -storepass 'StatusMate@123d' -file upload_certificate.pem
```

## Android Permissions

The app uses the following permissions:

| Permission                    | Purpose                                      | Android Version |
|-------------------------------|----------------------------------------------|-----------------|
| `READ_EXTERNAL_STORAGE`      | Access WhatsApp .Statuses directory          | 10 and below    |
| `WRITE_EXTERNAL_STORAGE`     | Save statuses to Downloads                   | 10 and below    |
| `MANAGE_EXTERNAL_STORAGE`    | Access WhatsApp .Statuses directory          | 11+             |

> **Important:** `READ_MEDIA_IMAGES` and `READ_MEDIA_VIDEO` were removed (v1.0.7) to comply with Google Play's Photo and Video Permissions policy. The app uses `MANAGE_EXTERNAL_STORAGE` + SAF (Storage Access Framework) instead.

### Play Store Declaration

When submitting to Play Store, you need to fill the **MANAGE_EXTERNAL_STORAGE** declaration form:
- Go to **Play Console > Policy and programmes > App content > Sensitive permissions**
- Use case: File management (accessing WhatsApp .Statuses directory)

## How Status Access Works

1. **Saved directory** — Checks SharedPreferences for previously selected directory
2. **Direct access** — Reads from known WhatsApp status paths:
   - Android 10-: `/storage/emulated/0/WhatsApp/Media/.Statuses`
   - Android 11+: `/storage/emulated/0/Android/media/com.whatsapp/WhatsApp/Media/.Statuses`
3. **SAF fallback** — If direct access fails, prompts user to select the directory via FilePicker

Saved statuses go to: `/storage/emulated/0/Download/StatusMate/`

## Build Commands

```bash
# Build release AAB (for Play Store)
flutter build appbundle --release
# or
make bundleRelease

# Build release APK
flutter build apk --release
# or
make apkRelease

# Clean build
flutter clean && flutter pub get

# All make commands
make help
```

## GitHub Actions Deployment

This project uses GitHub Actions for automated Android builds. The workflow is triggered when you push a version tag (e.g., `v1.0.0`).

### Setup Instructions

1. **Add GitHub Secrets** in your repository settings (Settings > Secrets and variables > Actions):
   - `KEYSTORE`: Base64-encoded content of your keystore file
     ```bash
     openssl base64 -in android/status_mate.jks | pbcopy
     ```
   - `KEY_PASSWORD`: `StatusMate@123d`
   - `STORE_PASSWORD`: `StatusMate@123d`

2. **Create a new release** by pushing a version tag:
   ```bash
   git tag -a v1.0.7 -m "Release v1.0.7"
   git push origin v1.0.7
   ```

## Play Store Policy Notes

- App was removed on **4 Dec 2025** for not adhering to Developer Programme Policies
- Update rejected on **1 Jan 2026** for Photo and Video Permissions policy violation
- Fixed in v1.0.7 by removing `READ_MEDIA_IMAGES` / `READ_MEDIA_VIDEO`
- Upload key reset requested on **11 Feb 2026** (pending approval)

## Git Branches

- `main` — stable
- `development` — active development (push here)

# Paytm Intent Mesh — Flutter app

This cross-platform client consumes the same FastAPI backend as the web prototype. It implements the complete clickable demo journey: Ask Paytm, intent confirmation, GPS-aware matching, merchant responses, live offers, offer selection, simulated Paytm payment, and success.

The project has been generated and verified with Flutter 3.47.1. To run it locally, start the backend first, then launch Flutter:

```bash
cd flutter_app
flutter pub get
flutter run -d linux
```

Run the Android version with:

```bash
flutter run -d <android-device-id>
```

The verified debug APK is generated at `build/app/outputs/flutter-apk/app-debug.apk`. Android GPS and internet permissions are already configured. The Android Emulator uses `10.0.2.2:8000`; a physical device must use the development laptop's LAN IP and the backend must listen on `0.0.0.0`.

Linux desktop does not expose the mobile geolocation plugin, so it intentionally uses the KMIT demo coordinates. Android and web request real device GPS permission.

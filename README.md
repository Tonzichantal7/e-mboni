# E-mboni

E-mboni is an AI navigation and safety assistant designed to help blind and visually impaired users move more independently. The Flutter application provides voice-led interaction, navigation support, object detection, emergency alerts, and guardian tracking features.

## Features

- Voice-first navigation and screen interaction
- Text-to-speech and speech-to-text support
- Camera-based object detection
- Location-aware navigation and tracking
- Emergency stop and alert workflows
- Guardian and administrator screens
- Light and dark themes
- Multi-language support

## Project Structure

```text
lib/
├── main.dart                 # Application entry point and routing
├── constants/                # Shared colors and application constants
├── screens/
│   ├── admin/                # Administrator views
│   ├── auth/                 # Login and registration views
│   ├── blind/                # Blind-user navigation and safety views
│   └── guardian/             # Guardian monitoring views
├── services/                 # API, speech, haptic, language, and theme services
└── widgets/                 # Reusable application widgets
assets/images/                # Image assets used by the application
```

## Requirements

- Flutter 3.x or later
- Dart SDK 3.0.0 or later
- A configured Android, iOS, Windows, or supported Flutter device
- Camera, microphone, location, and notification permissions where applicable

## Getting Started

From this directory:

```bash
flutter pub get
flutter run
```

To run the static analyzer and tests:

```bash
flutter analyze
flutter test
```

## Platform Permissions

The app uses device capabilities that require platform configuration and runtime permission handling:

- Camera access for visual detection
- Microphone access for voice commands
- Location access for navigation and guardian tracking
- Speech and text-to-speech services for accessible interaction
- Vibration and notifications for safety alerts

Review the platform-specific Flutter configuration before producing a release build.

## Related Application

The parent repository also contains the React Native implementation in the `my-eye/` directory. This directory contains the Flutter implementation of E-mboni.

## License

This project is currently not published under an open-source license.

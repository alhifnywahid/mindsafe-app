# Mindsafe App

A privacy-focused Android application for monitoring web domain access patterns using local VPN technology.

## Features

- **VPN-Based Monitoring**: Uses Android VpnService to intercept and log domain access
- **Privacy First**: Only stores domain names, no URLs or page content
- **Domain Classification**: Categorizes domains as safe, mixed, adult, or unknown
- **Statistics & Insights**: View usage patterns and trends
- **Google Sign-In**: Easy authentication with admin role support
- **Offline Support**: Works without internet, syncs when online
- **Light & Dark Mode**: Beautiful modern UI with theme support

## Tech Stack

- **Flutter** & **Dart**
- **GetX** - State management and routing
- **Firebase** - Authentication and Cloud Firestore
- **Hive** - Local storage
- **Kotlin** - Android VPN Service
- **fl_chart** - Statistics visualization

## Getting Started

### Prerequisites

- Flutter SDK (>=3.8.1)
- Android Studio or VS Code with Flutter extensions
- Firebase account
- Android device or emulator (API 21+)

### Firebase Setup

**IMPORTANT**: The app currently uses a placeholder Firebase configuration. You MUST set up your own Firebase project:

1. Go to [Firebase Console](https://console.firebase.google.com)
2. Create a new project called "Mindsafe" (or your preferred name)
3. Add an Android app with package name: `com.example.mindsafe_flutter`
4. Download `google-services.json`
5. Replace the placeholder file at:
   ```
   android/app/google-services.json
   ```
6. Enable **Authentication** → **Google Sign-In** in Firebase Console
7. Enable **Firestore Database** in Firebase Console

### Installation

1. **Clone the repository** (if applicable) or navigate to the project directory

2. **Install dependencies**:
   ```bash
   flutter pub get
   ```

3. **Generate Hive adapters**:
   ```bash
   dart run build_runner build --delete-conflicting-outputs
   ```

4. **Run the app**:
   ```bash
   flutter run
   ```

## Project Structure

```
lib/
├── app/
│   ├── bindings/          # Dependency injection
│   └── controllers/       # Business logic controllers
├── core/
│   ├── constants/         # Colors, spacing, text styles
│   └── theme/            # Light and dark themes
├── data/
│   ├── models/           # Hive models
│   ├── repositories/     # Data layer
│   └── services/         # VPN, Auth, Database services
├── routes/               # App navigation
├── screens/              # UI screens
├── widgets/              # Reusable components
└── main.dart             # App entry point

android/
└── app/src/main/kotlin/com/example/mindsafe_flutter/
    ├── LocalVpnService.kt   # VPN implementation
    └── MainActivity.kt       # Platform channel bridge
```

## How It Works

### VPN Monitoring

1. **LocalVpnService.kt**: Establishes a local VPN connection using Android's VpnService API
2. **Packet Capture**: Intercepts network packets to extract DNS queries and TLS SNI
3. **Domain Extraction**: Parses packets to identify target domains
4. **Event Streaming**: Sends domain events to Flutter via EventChannel
5. **Privacy Protection**: 
   - Does NOT decrypt HTTPS traffic
   - Only captures domain names
   - Optional domain hashing for extra privacy

### Data Flow

```
User browses → VPN intercepts packet → Extract domain →
Send to Flutter → Classify domain → Store in Hive →
Update statistics → (Optional) Sync to Firestore
```

### Admin Features

Users with email **jackkolor69@gmail.com** automatically get admin access:
- View aggregate  statistics
- Manage domain classification rules
- Enable/disable users
- View audit logs

Admin features can be accessed from the Admin tab (visible only to admins).

## Configuration

### Privacy Settings

Users can configure:
- **Data Retention**: 7, 30, or 90 days
- **Privacy Mode**: Store raw domains or SHA-256 hashes
- **Theme**: Light, Dark, or System
- **Notifications**: Enable/disable

### Domain Classification

Rules are stored locally in Hive and can be managed by admins:
- **Pattern**: Exact match or regex
- **Category**: adult, mixed, safe, unknown
- **Priority**: Higher priority rules checked first

## Development Notes

### Known Limitations

1. **DNS only**: Currently captures DNS queries. TLS SNI extraction is partially implemented
2. **IPv4 only**: IPv6 support not yet implemented
3. **Simple heuristics**: Domain classification uses basic pattern matching

### Future Improvements

- [ ] Complete TLS SNI extraction
- [ ] ML-based domain classification
- [ ] Weekly/monthly reports
- [ ] Export data functionality
- [ ] Multi-device sync

## Troubleshooting

### App won't build
- Ensure you've replaced the placeholder `google-services.json` with a real Firebase config
- Run `flutter clean` and `flutter pub get`
- Check that Android SDK and Flutter SDK are properly installed

### VPN permission denied
- Android requires explicit user consent for VPN
- System will show a permission dialog on first VPN start
- If denied, user must restart VPN from the app

### Domains not being captured
- Ensure VPN permission is granted
- Check VPN status indicator on home screen
- Look for notification showing "VPN Active"
- Try browsing a few websites and wait a few seconds

### Build errors
- Run `dart run build_runner clean`
- Then `dart run build_runner build --delete-conflicting-outputs`
- If still failing, delete `.dart_tool` folder and run `flutter pub get`

## License

This project is for educational purposes.

## Contact

For admin access or support, contact the developer.

---

**Remember**: This app prioritizes your privacy. It ONLY monitors domain names, never page content or personal data.

# Daily Appointments Tool (DATool)

A complete invoice tracking and reporting system combining Google Sheets, Google Apps Script backend, and Flutter cross-platform mobile/web frontend.

## 📋 Project Overview

This project provides stylists and businesses with an automated invoice consolidation and reporting system:

- **Backend**: Google Apps Script processes invoice data from Google Sheets
- **Frontend**: Flutter cross-platform app for iOS, Android, web, and desktop
- **Data**: Consolidated invoice reports with offline caching and searching

## 🏗️ Architecture

```
Project Root/
├── Code_optimized.gs          # Google Apps Script backend (optimized) ⭐
├── Code.gs                    # Google Apps Script backend (original)
├── manifest.json              # API configuration
├── flutter_app/               # Cross-platform Flutter app ⭐
│   ├── lib/
│   │   ├── main.dart          # Main app entry point
│   │   ├── constants/         # App configuration & colors
│   │   ├── models/            # Data models (Stylist, Report)
│   │   ├── services/          # API & cache services
│   │   ├── utils/             # Helper functions
│   │   └── widgets/           # Reusable UI components
│   ├── pubspec.yaml
│   ├── ARCHITECTURE.md        # Detailed app design
│   └── README.md
├── _archive/                  # Legacy PWA files (archived)
└── .gitignore
```

**⭐ Primary targets**

## 🎯 Component Breakdown

### 1. Backend: Google Apps Script (`Code_optimized.gs`) ⭐

**Purpose**: Process invoice data, consolidate records, provide REST API endpoints

**Key Functions**:
- `generateDataHive()` - Consolidates and deduplicates invoice data
- `doGet(e)` - API handler for `/exec?action=stylists|reports`
- Returns JSON for Flutter app and PWA frontends

**Technology**: Google Apps Script (JavaScript)

**Status**: Live endpoint (no additional deployment needed)

### 2. Frontend: Flutter App (`flutter_app/`) ⭐ RECOMMENDED

**Purpose**: Cross-platform reporting interface with offline support

**Platforms**:
- ✅ Android
- ✅ iOS  
- ✅ Web (Chrome, Firefox, Safari)
- ✅ Windows/Linux/macOS (Desktop)

**Key Features**:
- Offline caching with `shared_preferences`
- Full-text search by invoice number or customer
- Multi-column sorting
- CSV export
- Responsive adaptive design (phone/tablet/desktop)
- Last sync timestamp with retry button
- Summary statistics (count, total amount)

**Technology**: Flutter 3.10+ with Dart 3.0+

**Usage**: 
```bash
cd flutter_app
flutter run     # Run on any connected device
```

### 3. Legacy: Progressive Web App (`_archive/`)

**Status**: Archived but functional as backup

**Files**: `stylist_access_simple.html` + `sw.js` + `manifest.json`

**Purpose**: Browser-based alternative to Flutter app

## 🚀 Getting Started

### Flutter App (Recommended)

Prerequisites:
- Flutter 3.10+ ([Install](https://flutter.dev/docs/get-started/install))
- Connected device or emulator (Android/iOS) OR web browser

```bash
cd flutter_app
flutter pub get                 # Install dependencies
flutter run -d chrome           # Run web
flutter run -d android          # Run Android emulator
flutter run -d ios              # Run iOS simulator
flutter build apk               # Build Android release
flutter build ipa               # Build iOS release
flutter build web               # Build web release
```

### Google Sheets Backend Setup

1. Open the shared Google Sheet: `1UIz7-qxhIZfkl1YMwN45k9TaIO13CMsn8V6l3gbtFm4`
2. Paste invoice data into the **"Paste Data Here"** sheet
3. Click **Extensions** → **Apps Script** (or paste `Code_optimized.gs`)
4. Deploy as Web App (copy deployment URL to app constants)
5. Create stylists in the **"Stylist"** sheet with tokens

### Access the App

```
Login with stylist token → View filtered reports → Export as CSV
```

## 📊 Data Flow

```
Admin pastes data
         ↓
Google Sheets "Paste Data Here"
         ↓
Apps Script consolidates & deduplicates
         ↓
"Data Hive" sheet updated
         ↓
Front-end fetches (PWA or Flutter)
         ↓
User sees filtered/sorted reports
```

## 🔐 Security

### Current Implementation
- Token-based access control
- HTTPS for API communication
- No credentials stored in browser/app

### Recommended Improvements (Production)
- OAuth 2.0 authentication
- Token expiration & rotation
- Rate limiting on API
- Encrypted local storage

## 📁 File Guide

| File | Purpose | Status |
|------|---------|--------|
| `flutter_app/` | Cross-platform reporting app | ✅ **Active** |
| `Code_optimized.gs` | Optimized backend (recommended) | ✅ **Active** |
| `Code.gs` | Original backend (reference) | 📚 Reference |
| `manifest.json` | API/PWA config | 📚 Reference |
| `_archive/` | Legacy PWA files | 🗂️ Archived |

## 🔧 Configuration

### Update API Endpoint

**Flutter App**: Edit `flutter_app/lib/constants/app_constants.dart`
```dart
const String apiBaseUrl = 'https://your-new-endpoint.com/exec';
```

**PWA**: Edit `stylist_access_simple.html`
```javascript
const API_URL = 'https://your-new-endpoint.com/exec';
```

### Change Colors/Theme

**Flutter**: Edit `constants/app_constants.dart`
```dart
const int primaryColorSeed = 0xYOURHEXCOLOR;
```

**PWA**: Edit `stylist_access_simple.html` CSS

## 📦 Deployment

### Deploy Flutter Web

```bash
cd flutter_app
flutter build web
# Upload `build/web` to hosting service
```

### Deploy PWA

Simply host `stylist_access_simple.html` + `sw.js` + `manifest.json` on web server

### Deploy Google Apps Script

Already live - no deployment needed for backend!

## 🧪 Testing Checklist

- [ ] Login with valid token shows correct stylist
- [ ] Invalid token shows error
- [ ] Filters work: month, date range, search
- [ ] Export CSV includes all columns
- [ ] App works offline with cached data
- [ ] Sync button retries failed connections
- [ ] Mobile layout responsive
- [ ] Column sorting works (desktop)

## 📚 Documentation

- **Flutter app architecture**: See [flutter_app/ARCHITECTURE.md](flutter_app/ARCHITECTURE.md)
- **Flutter app README**: See [flutter_app/README.md](flutter_app/README.md)
- **Legacy PWA setup**: See `_archive/PWA_SETUP_FREE.md`
- **Legacy Stylist setup**: See `_archive/STYLIST_SETUP.md`
- **Project plan**: See `_archive/plan.md`

## 🐛 Troubleshooting

### Flutter app won't run
```bash
flutter clean
flutter pub get
flutter run -d chrome
```

### API returns error
- Check Apps Script deployment is active
- Verify token exists in "Stylist" sheet
- Ensure invoice data in "Paste Data Here" sheet

### Cached data is stale
- Native app: Uninstall & reinstall
- Web: Clear browser cache or use incognito
- Both: Tap "Retry sync" button

## 🎓 Learning Resources

- [Flutter Docs](https://flutter.dev)
- [Google Apps Script](https://developers.google.com/apps-script)
- [Progressive Web Apps](https://web.dev/progressive-web-apps/)

## 📝 License

Proprietary - All rights reserved

## 👤 Support

For issues contact the development team.

---

**Last Updated**: February 18, 2026  
**Version**: 1.0.0-refactored

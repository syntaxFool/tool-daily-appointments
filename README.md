# Daily Appointments Tool (DATool)

A complete invoice tracking and reporting system combining Google Sheets, Google Apps Script backend, and Flutter cross-platform mobile/web frontend.

## 📋 Project Overview

This project provides stylists and businesses with an automated invoice consolidation and reporting system. Admin pastes invoice data into Google Sheets, the system consolidates and deduplicates records, then stylists access reports via:
- **Progressive Web App (PWA)** for web browsers
- **Flutter App** for iOS, Android, web, and desktop platforms

## 🏗️ Architecture

```
Project Root/
├── Code_optimized.gs          # Google Apps Script backend (optimized)
├── Code.gs                    # Google Apps Script backend (original)
├── stylist_access_simple.html # PWA frontend
├── sw.js                      # Service Worker for offline
├── manifest.json              # PWA metadata
├── flutter_app/               # Cross-platform Flutter app
│   ├── lib/
│   │   ├── main.dart
│   │   ├── constants/
│   │   ├── models/
│   │   ├── services/
│   │   ├── utils/
│   │   └── widgets/
│   ├── pubspec.yaml
│   ├── ARCHITECTURE.md
│   └── README.md
├── plan.md                    # Project specification
├── STYLIST_SETUP.md          # Token management guide
└── PWA_SETUP_FREE.md         # PWA deployment guide
```

## 🎯 Component Breakdown

### 1. Backend: Google Apps Script (`Code_optimized.gs`)

**Purpose**: Process invoice data, consolidate records, provide API endpoints

**Key Functions**:
- `generateDataHive()` - Consolidates invoice data
- `getStylistsData()` - Returns stylist list with tokens
- `getDataHiveReports()` - Returns all consolidated reports

**Technology**: Google Apps Script (JavaScript-like)

**Deployment**: Web App at Google (live URL in code)

### 2. Frontend: Flutter App (`flutter_app/`)

**Purpose**: Cross-platform reporting interface with offline support

**Platforms**:
- ✅ Android
- ✅ iOS
- ✅ Web
- ✅ Windows/Linux (desktop)

**Key Features**:
- Caching with `shared_preferences`
- Full-text search
- Multi-column sorting
- CSV export
- Responsive design

**Technology**: Flutter + Dart

### 3. Legacy: Progressive Web App (`stylist_access_simple.html`)

**Purpose**: Browser-based reporting without installation (alternate to Flutter)

**Features**:
- Zero installation needed
- Offline support via Service Worker
- Mobile responsive
- CSV export

**Technology**: Vanilla HTML/CSS/JavaScript

## 🚀 Getting Started

### Quick Start (Flutter App)

```bash
cd flutter_app
flutter pub get
flutter run -d chrome     # Web
flutter run -d android    # Android
flutter run -d ios        # iOS
```

### Google Sheets Setup

1. Open shared sheet: `1UIz7-qxhIZfkl1YMwN45k9TaIO13CMsn8V6l3gbtFm4`
2. Paste invoice data into "Paste Data Here" sheet
3. Click Extensions → Custom Functions → "Generate Data Hive Report"
4. Wait for consolidation to complete

### Stylist Access

**Method 1: Flutter App**
```
Download app → Enter token → View reports
```

**Method 2: PWA**
```
Open HTML file in browser → Enter token → View reports
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

| File | Purpose |
|------|---------|
| `Code_optimized.gs` | **USE THIS** - Optimized backend (70% smaller) |
| `Code.gs` | Original backend (kept for reference) |
| `stylist_access_simple.html` | Standalone PWA alternative |
| `sw.js` | Service Worker for offline |
| `manifest.json` | PWA manifest |
| `flutter_app/` | **USE THIS** - Recommended cross-platform app |

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

- **How to use**: See `plan.md`
- **App architecture**: See `flutter_app/ARCHITECTURE.md`
- **Stylist setup**: See `STYLIST_SETUP.md`
- **PWA deployment**: See `PWA_SETUP_FREE.md`

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

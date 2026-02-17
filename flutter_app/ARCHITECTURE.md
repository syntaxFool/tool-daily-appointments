# DATool - Stylist Reports Dashboard

A cross-platform Flutter application for accessing consolidated invoice reports with offline-first architecture, real-time filtering, and CSV export capabilities.

## Features

✨ **Core Features**
- 🔐 Token-based authentication linked to Google Sheets
- 📊 Real-time report viewing and filtering
- 🔍 Full-text search by customer name or invoice number
- 📅 Month-based and date-range filtering
- 💾 Offline support with automatic caching
- 📥 CSV export with filter preservation
- 📱 Fully responsive mobile design
- 🟧 Material Design 3 UI with gradient backgrounds

### Advanced Features
- 📊 **Summary Tiles**: Display count, total amount, and invoice totals
- 🔄 **Sync Status**: Shows last sync time and retry capability
- 🔀 **Column Sorting**: Tap column headers to sort (desktop view)
- 💳 **Compact Cards**: Mobile-optimized card-based layout
- 🚀 **Hot Reload**: Development-friendly Flutter setup
- 📋 **Filter Persistence**: Remembers user preferences across sessions

## Architecture

```
lib/
├── main.dart                 # App entry point & main state management
├── constants/
│   └── app_constants.dart    # All hardcoded values, colors, dimensions
├── models/
│   └── data_models.dart      # Stylist, Report, CachedPayload classes
├── services/
│   ├── api_client.dart       # Google Apps Script API integration
│   └── cache_service.dart    # Local storage & filter state management
├── utils/
│   └── report_utils.dart     # Helpers for sorting, dates, summaries
└── widgets/
    └── common_widgets.dart   # Reusable UI components
```

### Key Design Decisions

1. **Single-file Configuration**: All magic numbers in `app_constants.dart`
2. **Service Layer**: API and cache logic separated from UI
3. **Component Reusability**: Common widgets in dedicated module
4. **State Persistence**: Filter state auto-saves after every change
5. **Offline-First**: Cached data loads instantly, sync happens in background

## Setup & Installation

### Prerequisites
- Flutter 3.10+
- Dart 3.10+
- Chrome (for web development)

### Installation

```bash
# Clone repository
git clone https://github.com/syntaxFool/tool-daily-appointments.git
cd flutter_app

# Install dependencies
flutter pub get

# Run on Chrome
flutter run -d chrome

# Run on Android
flutter run -d android

# Run on iOS
flutter run -d ios
```

## Usage

### For Stylists

1. **Login**: Enter your unique access token
2. **View Reports**: See all consolidated invoices
3. **Filter**: 
   - By month (dropdown)
   - By date range (date picker)
   - By customer/invoice (search box)
4. **Sort**: Click any column header (desktop)
5. **Export**: Download CSV with current filters applied
6. **Offline**: App works offline with cached data

### For Developers

#### Adding a New Filter Type

1. Add constant to `app_constants.dart`:
   ```dart
   const String filterNewTypeKey = 'filter_new_type';
   ```

2. Add field to `FilterState` in `cache_service.dart`

3. Add getter methods to main state class

4. Update `_applyFilters()` to include new logic

#### Modifying API Endpoint

Edit `api_client.dart`:
```dart
const String apiBaseUrl = 'your-new-url';
```

#### Changing App Theme

Edit `constants/app_constants.dart`:
```dart
const int primaryColorSeed = 0xYOURHEX;
```

## Project Structure

### Build & Distribution

```bash
# Build for Web
flutter build web

# Build for Android APK
flutter build apk

# Build for iOS
flutter build ios

# Build for Windows/Linux
flutter build windows
flutter build linux
```

## Dependencies

| Package | Purpose |
|---------|---------|
| `http` | API communication |
| `csv` | CSV export |
| `file_saver` | File download handling |
| `google_fonts` | Custom typography |
| `intl` | Date formatting & localization |
| `shared_preferences` | Local storage & caching |

## Performance Optimizations

- **Lazy Loading**: Reports only load after search/filter
- **Caching**: Full dataset cached locally for instant access
- **Sorting**: In-memory sort only when needed
- **Responsive Rebuild**: Uses `setState()` strategically
- **Single Sync**: Background sync doesn't block UI

## API Integration

### Endpoints

**Get Stylists**
```
GET /exec?action=stylists
Response: { stylists: [{ name, token }] }
```

**Get Reports**
```
GET /exec?action=reports
Response: { reports: [{ date, invoiceNumber, stylist, customerName, amount, invoiceTotal }] }
```

## Testing

### Manual Testing Areas

- [ ] Login with valid/invalid tokens
- [ ] Filter by month, date range, search
- [ ] Sort by each column (desktop)
- [ ] Export CSV matches visible data
- [ ] Offline functionality (disconnect network)
- [ ] Mobile responsiveness (Chrome DevTools)
- [ ] Filter state persists after app restart

### Run Tests

```bash
flutter test
```

## Error Handling

| Error | Behavior |
|-------|----------|
| Invalid token | Shows error, allows retry |
| Network timeout | Shows cached data, offers sync |
| No cached data | Shows login error |
| Empty results | Shows "No reports found" message |

## Troubleshooting

**App won't build?**
```bash
flutter clean
flutter pub get
flutter run
```

**Chrome not detected?**
```bash
flutter devices
# If Chrome not listed, install from: https://flutter.dev/docs/get-started/install
```

**Cache stale?**
- Clear app data in system settings
- Or tap "Retry sync" button in UI

**Search not working?**
- Ensure report names exactly match (case-sensitive in API)

## Future Enhancements

- [ ] Advanced analytics dashboard
- [ ] Invoice detail drill-down
- [ ] Export to PDF with formatting
- [ ] Dark mode support
- [ ] Multi-language support
- [ ] Biometric authentication
- [ ] Cloud backup sync
- [ ] Payment status tracking

## Security Considerations

⚠️ **Warning**: Tokens are stored locally! For production:
- Use OAuth 2.0 instead of static tokens
- Implement token rotation
- Add certificate pinning for HTTPS
- Encrypt local storage
- Add rate limiting

## License

Proprietary - All rights reserved

## Support

For issues or feature requests, contact: support@example.com

## Changelog

### v1.0.0 (February 2026)
- ✅ Initial release
- ✅ Full offline support
- ✅ Search and filtering
- ✅ CSV export
- ✅ Mobile responsive design

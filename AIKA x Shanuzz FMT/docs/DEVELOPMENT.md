# Development Guide

Guidelines for developing and extending the AIKA x Shanuzz FMT application.

## 🏗️ Architecture

### Frontend (Flutter/Dart)
- **Framework**: Flutter Web
- **State Management**: StatefulWidget (can be upgraded to Provider/Riverpod)
- **HTTP Client**: http package
- **Local Storage**: shared_preferences

### Backend (Google Apps Script)
- **Platform**: Google Apps Script (JavaScript)
- **Database**: Google Sheets
- **API Style**: RESTful

### Data Flow
```
Flutter App (UI) 
    ↓↑ HTTP
API Service 
    ↓↑ HTTP/JSON
Google Apps Script 
    ↓↑ 
Google Sheets (Database)
```

## 📁 Project Structure

```
lib/
├── main.dart                    # App initialization & routing
├── models/                      # Data models
│   ├── raw_table_entry.dart    # Financial entry model
│   └── user.dart                # User model
├── services/                    # Business logic & API
│   ├── api_service.dart        # Google Sheets API calls
│   └── storage_service.dart    # Local storage (SharedPreferences)
└── screens/                     # UI screens
    ├── login_screen.dart       # Authentication
    ├── home_screen.dart        # Dashboard & entry list
    ├── entry_form_screen.dart  # Add/Edit entries
    └── user_management_screen.dart # User CRUD

apps-script/
└── Code.gs                      # Backend API

web/
├── manifest.json                # PWA configuration
└── index.html                   # Web entry point

docs/
├── QUICK_START.md              # Quick start guide
├── APPS_SCRIPT_DEPLOYMENT.md   # Deployment instructions
└── DEVELOPMENT.md              # This file
```

## 🛠️ Development Workflow

### 1. Setup Development Environment

```bash
# Verify Flutter installation
flutter doctor

# Get dependencies
flutter pub get

# Run in debug mode
flutter run -d chrome --web-renderer html

# Enable hot reload for faster development
# Press 'r' to hot reload, 'R' to hot restart
```

### 2. Code Style

Follow Flutter's official style guide:
- Use `flutter format .` to format code
- Follow naming conventions:
  - Classes: `PascalCase`
  - Variables: `camelCase`
  - Private members: `_camelCase`
  - Constants: `SCREAMING_SNAKE_CASE`

### 3. Testing Changes

#### Frontend Testing
```bash
# Run the app
flutter run -d chrome

# Build for production (to test PWA features)
flutter build web --release
```

#### Backend Testing
- Test in Apps Script editor using the `testSetup()` function
- Use Apps Script execution logs to debug
- Test API endpoints with Postman or browser

## 🔧 Adding New Features

### Adding a New Screen

1. Create a new file in `lib/screens/`
2. Define a StatefulWidget
3. Add navigation from existing screens
4. Update imports in relevant files

Example:
```dart
// lib/screens/reports_screen.dart
import 'package:flutter/material.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Reports')),
      body: const Center(child: Text('Reports')),
    );
  }
}
```

### Adding a New Data Field

1. **Update Google Sheets**: Add column to the sheet
2. **Update Model**: Add property to the model class
3. **Update fromJson/toJson**: Include the new field
4. **Update UI**: Add form field in the form screen
5. **Test**: Verify data flows correctly

Example (adding "Category" field):

```dart
// In raw_table_entry.dart
class RawTableEntry {
  final String category;  // Add this
  
  // Constructor
  RawTableEntry({
    // ...existing fields...
    required this.category,  // Add this
  });
  
  // fromJson
  factory RawTableEntry.fromJson(Map<String, dynamic> json) {
    return RawTableEntry(
      // ...existing fields...
      category: json['Category'] ?? '',  // Add this
    );
  }
  
  // toJson
  Map<String, dynamic> toJson() {
    return {
      // ...existing fields...
      'Category': category,  // Add this
    };
  }
}
```

### Adding a New API Endpoint

1. **Apps Script**: Add function in `Code.gs`
2. **API Service**: Add method in `api_service.dart`
3. **UI**: Call the method from your screen

Example (adding a search function):

```javascript
// In apps-script/Code.gs
function searchRawTable(query) {
  const sheet = getSpreadsheet().getSheetByName(RAW_TABLE_SHEET_NAME);
  const data = sheet.getDataRange().getValues();
  // ...implement search logic...
  return createResponse(true, results);
}

// Update doGet to handle search
case 'searchRawTable':
  return searchRawTable(e.parameter.query);
```

```dart
// In lib/services/api_service.dart
Future<List<RawTableEntry>> searchRawTable(String query) async {
  final response = await http.get(
    Uri.parse('$_baseUrl?action=searchRawTable&query=$query'),
  );
  // ...handle response...
}
```

## 🎨 UI/UX Guidelines

### Material Design 3
- Use Material 3 components
- Follow color scheme from theme
- Use consistent spacing (8px increments)

### Responsive Design
```dart
// Example: Adaptive layout
LayoutBuilder(
  builder: (context, constraints) {
    if (constraints.maxWidth > 600) {
      return DesktopLayout();
    } else {
      return MobileLayout();
    }
  },
)
```

### Loading States
Always show loading indicators:
```dart
_isLoading 
  ? const CircularProgressIndicator()
  : YourContent()
```

### Error Handling
Always handle errors gracefully:
```dart
try {
  // API call
} catch (e) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text('Error: ${e.toString()}')),
  );
}
```

## 🧪 Testing

### Manual Testing Checklist

Frontend:
- [ ] Login with valid/invalid tokens
- [ ] Add new entry
- [ ] Edit existing entry
- [ ] Delete entry
- [ ] Filter by month
- [ ] Check totals calculation
- [ ] Add/edit/delete users
- [ ] Logout and re-login
- [ ] Test on different screen sizes
- [ ] Test PWA installation

Backend:
- [ ] All API endpoints return correct data
- [ ] Error handling works
- [ ] Data persists in Google Sheets
- [ ] Concurrent updates don't conflict

### Automated Testing (Future Enhancement)

```dart
// Example widget test
testWidgets('Login form validates input', (WidgetTester tester) async {
  await tester.pumpWidget(const MyApp());
  
  // Find the login button
  final loginButton = find.text('Login');
  
  // Tap without entering token
  await tester.tap(loginButton);
  await tester.pump();
  
  // Should show validation error
  expect(find.text('Please enter your token'), findsOneWidget);
});
```

## 🚀 Building for Production

### Web Build

```bash
# Clean build
flutter clean
flutter pub get

# Build for web
flutter build web --release

# Output will be in build/web/
```

### Optimization Tips

1. **Reduce Bundle Size**:
   - Use `--tree-shake-icons` flag
   - Remove unused dependencies
   
2. **Performance**:
   - Use `const` constructors where possible
   - Implement pagination for large lists
   - Cache API responses

3. **PWA Optimization**:
   - Ensure service worker is configured
   - Add offline support
   - Optimize icons and images

## 🔐 Security Best Practices

1. **Never commit sensitive data**:
   - Use environment variables for API URLs
   - Don't hardcode tokens in code

2. **Input validation**:
   - Validate all user inputs
   - Sanitize data before sending to API

3. **API Security**:
   - Implement rate limiting
   - Add request validation
   - Use HTTPS only

## 📊 Performance Monitoring

### Browser DevTools
- Check Network tab for slow requests
- Use Performance tab to identify bottlenecks
- Monitor bundle size

### Apps Script Quotas
Be aware of Google Apps Script quotas:
- URL Fetch calls: 20,000/day
- Script runtime: 6 min/execution
- Trigger runtime: 90 min/day

## 🐛 Debugging

### Flutter App
```bash
# Run with verbose logging
flutter run -d chrome -v

# Check the console
# Press F12 in Chrome > Console tab
```

### Apps Script
```javascript
// Add logging
Logger.log('Debug info: ' + JSON.stringify(data));

// Check logs in Apps Script editor
// View > Logs or View > Executions
```

### Common Issues

**White screen on load:**
- Check browser console for errors
- Verify service worker registration
- Clear browser cache

**API not responding:**
- Check Apps Script deployment is active
- Verify URL in api_service.dart
- Check CORS settings

## 📚 Resources

- [Flutter Documentation](https://flutter.dev/docs)
- [Dart Documentation](https://dart.dev/guides)
- [Material Design 3](https://m3.material.io/)
- [Apps Script Documentation](https://developers.google.com/apps-script)
- [PWA Documentation](https://web.dev/progressive-web-apps/)

## 🤝 Contributing

1. Create a feature branch
2. Make your changes
3. Test thoroughly
4. Submit for review
5. Update documentation

## 📝 Code Review Checklist

- [ ] Code follows style guidelines
- [ ] No hardcoded values
- [ ] Error handling implemented
- [ ] Loading states added
- [ ] Works on mobile and desktop
- [ ] No console errors
- [ ] Documentation updated
- [ ] Tested manually

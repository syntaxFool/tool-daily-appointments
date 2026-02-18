# AIKA x Shanuzz FMT - Financial Management Tool

A Progressive Web Application (PWA) built with Flutter and Dart, integrated with Google Sheets via Apps Script for managing financial data.

## 🚀 Features

- **User Authentication**: Token-based login system
- **Financial Entries Management**: 
  - Add, edit, and delete financial entries
  - Track date, amount, payment mode, and descriptions
  - Filter entries by month
  - View total amounts
- **User Management**: Admin panel to manage users and access tokens
- **Progressive Web App**: Install on any device, works offline
- **Google Sheets Integration**: All data synced with Google Sheets in real-time
- **Responsive Design**: Works on mobile, tablet, and desktop

## 📋 Prerequisites

- Flutter SDK (3.0.0 or higher)
- Dart SDK (3.0.0 or higher)
- Google Account with access to Google Sheets and Apps Script
- A modern web browser

## 🛠️ Installation & Setup

### 1. Clone the Repository

```bash
git clone <repository-url>
cd "AIKA x Shanuzz FMT"
```

### 2. Install Dependencies

```bash
flutter pub get
```

### 3. Google Sheets Setup

1. Open the Google Sheet: [https://docs.google.com/spreadsheets/d/1e2Zt5EsUvdAXzlHigNwsT8EmytJXV7mXwuP1vY-378Q/edit](https://docs.google.com/spreadsheets/d/1e2Zt5EsUvdAXzlHigNwsT8EmytJXV7mXwuP1vY-378Q/edit)

2. Ensure you have two sheets:
   - **rawtable** with headers: `Reffid`, `Date`, `Month`, `Amount`, `Mode Of Payment`, `Row Desc`, `Row Note`, `Entry Timestamp`, `Entry User`, `Edit Timestamp`, `Edit User`
   - **user** with headers: `Reffid`, `Name`, `Token`

### 4. Apps Script Deployment

1. Open Google Apps Script Editor: Extensions > Apps Script
2. Delete any existing code
3. Copy the content from `apps-script/Code.gs` into the script editor
4. Save the project (give it a name like "FMT Backend")
5. Deploy as Web App:
   - Click "Deploy" > "New deployment"
   - Select type: "Web app"
   - Description: "FMT API"
   - Execute as: "Me"
   - Who has access: "Anyone"
   - Click "Deploy"
6. Copy the Web App URL (it should look like the one in the project)
7. Paste this URL in `lib/services/api_service.dart` if different

### 5. Run the Application

#### For Web (Development)
```bash
flutter run -d chrome
```

#### Build for Production (PWA)
```bash
flutter build web --release
```

The built files will be in the `build/web` directory. Deploy these to any web hosting service.

## 📱 Usage

### First Time Setup

1. **Create a User**:
   - Manually add a user to the "user" sheet in Google Sheets
   - Columns: Reffid (e.g., "USER001"), Name (e.g., "John Doe"), Token (e.g., "abc123")

2. **Login**:
   - Open the app
   - Enter your token
   - Click "Login"

### Managing Entries

- **Add Entry**: Click the "+" button on the home screen
- **Edit Entry**: Click on any entry in the list
- **Delete Entry**: Open an entry and click the delete icon
- **Filter by Month**: Use the dropdown on the home screen

### Managing Users

- Click the people icon in the app bar
- Add, edit, or delete users
- Generate secure tokens for new users

## 🏗️ Project Structure

```
lib/
├── main.dart                    # App entry point
├── models/
│   ├── raw_table_entry.dart    # Raw table data model
│   └── user.dart                # User data model
├── services/
│   ├── api_service.dart        # Google Sheets API integration
│   └── storage_service.dart    # Local storage service
└── screens/
    ├── login_screen.dart       # Login screen
    ├── home_screen.dart        # Main dashboard
    ├── entry_form_screen.dart  # Add/Edit entry form
    └── user_management_screen.dart # User management

apps-script/
└── Code.gs                     # Google Apps Script backend

web/
├── manifest.json               # PWA manifest
└── index.html                  # Web entry point
```

## 🔧 Configuration

### API Endpoint

The API endpoint is configured in `lib/services/api_service.dart`:

```dart
static const String _baseUrl = 'YOUR_APPS_SCRIPT_WEB_APP_URL';
```

### Google Sheets ID

The spreadsheet ID is configured in `apps-script/Code.gs`:

```javascript
const SPREADSHEET_ID = '1e2Zt5EsUvdAXzlHigNwsT8EmytJXV7mXwuP1vY-378Q';
```

## 📊 Data Structure

### Raw Table Entry
- **Reffid**: Unique reference ID
- **Date**: Entry date (YYYY-MM-DD)
- **Month**: Month and year (e.g., "January 2026")
- **Amount**: Transaction amount
- **Mode Of Payment**: Cash, Card, UPI, Bank Transfer, Other
- **Row Desc**: Description of the entry
- **Row Note**: Additional notes (optional)
- **Entry Timestamp**: When the entry was created
- **Entry User**: Who created the entry
- **Edit Timestamp**: Last edit time
- **Edit User**: Who last edited

### User
- **Reffid**: Unique user ID
- **Name**: User's name
- **Token**: Authentication token

## 🚢 Deployment

### Deploy to Firebase Hosting

```bash
flutter build web --release
firebase init hosting
firebase deploy
```

### Deploy to GitHub Pages

```bash
flutter build web --release --base-href "/your-repo-name/"
# Copy build/web contents to your gh-pages branch
```

### Deploy to Any Web Server

Simply upload the contents of `build/web` to your web server.

## 🔒 Security Notes

- The current implementation uses simple token-based authentication
- For production, consider implementing more secure authentication
- Keep your Apps Script deployment URL private
- Regularly rotate user tokens
- Consider adding rate limiting on the Apps Script side

## 🐛 Troubleshooting

### CORS Errors
- Make sure the Apps Script is deployed with "Who has access: Anyone"
- Check that the Web App URL in the Flutter app matches the deployment

### Data Not Loading
- Verify the Google Sheets ID is correct
- Check that sheet names match exactly ("rawtable" and "user")
- Ensure headers are spelled correctly

### PWA Not Installing
- The app must be served over HTTPS (except localhost)
- Check that manifest.json is accessible
- Verify service worker is registered

## 📝 License

This project is private and proprietary.

## 👥 Authors

AIKA x Shanuzz Team

## 🙏 Acknowledgments

- Flutter team for the amazing framework
- Google Apps Script for easy backend integration
- Material Design for UI components

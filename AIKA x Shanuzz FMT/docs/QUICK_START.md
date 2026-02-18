# Quick Start Guide

Get up and running with AIKA x Shanuzz FMT in 5 minutes!

## ⚡ Quick Setup

### 1. Install Flutter (if not already installed)

```bash
# Windows (using chocolatey)
choco install flutter

# Or download from: https://flutter.dev/docs/get-started/install
```

### 2. Clone and Setup Project

```bash
cd "d:\codeProject\Google Sheet Tools\AIKA x Shanuzz FMT"
flutter pub get
```

### 3. Verify Setup

```bash
flutter doctor
```

Make sure you see a checkmark next to:
- ✓ Flutter
- ✓ Chrome (for web development)

### 4. Setup Google Sheets

The sheets should already be set up at:
https://docs.google.com/spreadsheets/d/1e2Zt5EsUvdAXzlHigNwsT8EmytJXV7mXwuP1vY-378Q/edit

**Required Sheets:**

1. **rawtable** (with headers):
   ```
   Reffid | Date | Month | Amount | Mode Of Payment | Row Desc | Row Note | Entry Timestamp | Entry User | Edit Timestamp | Edit User
   ```

2. **user** (with headers):
   ```
   Reffid | Name | Token
   ```

### 5. Deploy Apps Script

1. Open the Google Sheet
2. Go to **Extensions** > **Apps Script**
3. Copy content from `apps-script/Code.gs`
4. Paste into the editor and save
5. Deploy as Web App:
   - **Execute as**: Me
   - **Who has access**: Anyone
6. Copy the Web App URL

The URL is already configured in the app:
```
https://script.google.com/macros/s/AKfycbwkkNNoLSvazoc_7z6M5-3MGh53Kb1GgavTlvnpg1RSpgBPrrkNlt721aX1sTPhW7zbCg/exec
```

### 6. Create Test User

Add a test user to the "user" sheet:

| Reffid | Name | Token |
|--------|------|-------|
| USER001 | Test User | test123 |

### 7. Run the App

```bash
flutter run -d chrome
```

### 8. Login

- Open the app in Chrome
- Enter token: `test123`
- Click Login

## 🎉 You're Ready!

Now you can:
- ➕ Add new entries
- ✏️ Edit existing entries
- 🗑️ Delete entries
- 👥 Manage users
- 📊 View totals and filter by month

## 📱 Install as PWA

1. In Chrome, click the install icon (⊕) in the address bar
2. Click "Install"
3. The app will open in its own window
4. You can now launch it from your desktop/start menu!

## 🔄 Next Steps

- Read the full [README.md](../README.md) for detailed documentation
- Check [APPS_SCRIPT_DEPLOYMENT.md](APPS_SCRIPT_DEPLOYMENT.md) for deployment details
- Explore [DEVELOPMENT.md](DEVELOPMENT.md) for development guidelines

## ⚠️ Common Issues

### "Token not found"
- Make sure you added a user to the "user" sheet
- Check that the token matches exactly (case-sensitive)

### "Failed to load entries"
- Verify the Apps Script is deployed correctly
- Check the Web App URL in `api_service.dart`
- Look for errors in the browser console (F12)

### App not loading
```bash
# Clear Flutter cache and rebuild
flutter clean
flutter pub get
flutter run -d chrome
```

## 🆘 Need Help?

Check the troubleshooting section in the main README or review the Apps Script execution logs for errors.

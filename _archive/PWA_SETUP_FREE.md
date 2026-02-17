# 📊 PWA Setup Guide (Completely Free)

## Overview
The system now works **100% for free** using Google Apps Script. No API keys needed!

**Workflow:**
1. Admin: Paste invoices → Generate Data Hive Report
2. Stylist: Open PWA → Enter token → View/export reports

---

## Setup Steps

### Step 1: Deploy Apps Script as Web App

1. Go to your Google Sheet
2. Click **Extensions** → **Apps Script**
3. Click **Deploy** button (top right)
4. Select **New Deployment**
5. Choose type: **Web app**
6. Set:
   - Execute as: Your email
   - Who has access: **Anyone**
7. Click **Deploy**
8. ✅ You'll see a URL like: `https://script.google.com/macros/d/AKfycbx.../userweb`
9. **Copy this URL** (you'll need it next)

### Step 2: Update the HTML File

1. Open `stylist_access_simple.html` in a text editor
2. Find this line (near the top of the `<script>` section):
   ```javascript
   const APPS_SCRIPT_URL = 'https://script.google.com/macros/d/YOUR_DEPLOYMENT_ID/userweb';
   ```
3. Replace `YOUR_DEPLOYMENT_ID` with the URL from Step 1
4. **Example:** If your URL is `https://script.google.com/macros/d/AKfycbx123/userweb`, replace it exactly

### Step 3: Share with Stylists

1. Upload `stylist_access_simple.html` to:
   - Local server
   - Google Drive
   - GitHub Pages
   - Any web hosting

2. Share the link with your stylists

---

## Usage

### For Admins
1. Paste invoice data into **"Paste Data Here"** sheet
2. Click **Invoice Tools** → **Generate Data Hive Report**
3. Share the PWA link with stylists

### For Stylists
1. Open the PWA link
2. Enter your **Access Token** (from the "Stylist" sheet)
3. Select a month to filter
4. Click **Export CSV** to download your reports
5. Click **Logout** when done

---

## Troubleshooting

### "Could not connect to server"
- ❌ Apps Script URL is wrong or not deployed
- ✅ Copy the URL exactly from the deployment step
- ✅ Make sure "Who has access" is set to "Anyone"

### "Invalid token"
- ❌ Token doesn't match what's in the "Stylist" sheet
- ✅ Check spelling in the Stylist sheet (Column B)

### No data showing
- ❌ Data Hive report hasn't been generated yet
- ✅ Run "Generate Data Hive Report" from the menu
- ✅ Wait a few seconds for data to load

---

## Architecture

```
User opens PWA
    ↓
Enters token → Validated via Apps Script
    ↓
Fetches stylist reports from "Data Hive" sheet
    ↓
Filters by month (optional)
    ↓
Displays table / Exports CSV
```

**Benefits:**
- ✅ No API keys
- ✅ No external services
- ✅ Completely free
- ✅ Automatic token sync with sheet
- ✅ Direct data from your Google Sheet

---

## Need to Update Apps Script Code?

1. Go back to **Extensions** → **Apps Script**
2. Make your changes
3. Click **Deploy** → **Manage deployments**
4. Click the pencil icon and **Deploy new version**
5. The PWA will use the latest version automatically

---

**Questions?** Check that:
- ✅ Apps Script is deployed as web app
- ✅ "Anyone" has access
- ✅ Stylist token matches the sheet exactly
- ✅ Data Hive report has been generated

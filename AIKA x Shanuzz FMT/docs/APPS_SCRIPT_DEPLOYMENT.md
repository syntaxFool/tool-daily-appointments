# Apps Script Deployment Guide

This guide will help you deploy the Google Apps Script backend for the AIKA x Shanuzz FMT application.

## Prerequisites

- Google Account with access to the spreadsheet
- The spreadsheet must have the following sheets:
  - `rawtable` 
  - `user`

## Step-by-Step Deployment

### 1. Open Apps Script Editor

1. Open your Google Sheet: https://docs.google.com/spreadsheets/d/1e2Zt5EsUvdAXzlHigNwsT8EmytJXV7mXwuP1vY-378Q/edit
2. Go to **Extensions** > **Apps Script**
3. If there's existing code, delete it all

### 2. Add the Backend Code

1. Copy all the code from `apps-script/Code.gs`
2. Paste it into the Apps Script editor
3. Click the disk icon or press `Ctrl+S` to save
4. Give your project a name (e.g., "FMT Backend API")

### 3. Test the Setup

1. In the Apps Script editor, select the function `testSetup` from the dropdown
2. Click the "Run" button (▶️)
3. You may need to authorize the script:
   - Click "Review Permissions"
   - Choose your Google account
   - Click "Advanced"
   - Click "Go to [Project Name] (unsafe)"
   - Click "Allow"
4. Check the execution log (View > Logs) to verify:
   - Spreadsheet name is displayed
   - Both sheets (rawtable and user) are found

### 4. Deploy as Web App

1. Click **Deploy** > **New deployment**
2. Click the gear icon ⚙️ next to "Select type"
3. Choose **Web app**
4. Fill in the deployment settings:
   - **Description**: "FMT API v1" (or any description you prefer)
   - **Execute as**: **Me** (your email)
   - **Who has access**: **Anyone**
5. Click **Deploy**
6. You may need to authorize again - follow the same steps as in testing
7. Copy the **Web app URL** - it will look like:
   ```
   https://script.google.com/macros/s/AKfycbw.../exec
   ```

### 5. Update the Flutter App

1. Open `lib/services/api_service.dart` in your Flutter project
2. Replace the `_baseUrl` value with your new Web App URL:
   ```dart
   static const String _baseUrl = 'YOUR_WEB_APP_URL_HERE';
   ```
3. Save the file

### 6. Test the API

You can test the API using your browser or a tool like Postman:

#### Test GET Requests:
```
# Get all raw table entries
YOUR_WEB_APP_URL?action=getRawTable

# Get all users
YOUR_WEB_APP_URL?action=getUsers

# Get user by token
YOUR_WEB_APP_URL?action=getUserByToken&token=YOUR_TOKEN
```

#### Test POST Requests (use Postman or similar):
```json
// Add a test entry
POST: YOUR_WEB_APP_URL
Content-Type: application/json
{
  "action": "addRawTable",
  "data": {
    "Reffid": "TEST001",
    "Date": "2026-02-18",
    "Month": "February 2026",
    "Amount": 100,
    "Mode Of Payment": "Cash",
    "Row Desc": "Test entry",
    "Row Note": "Testing",
    "Entry Timestamp": "2026-02-18T10:00:00",
    "Entry User": "Test User",
    "Edit Timestamp": "2026-02-18T10:00:00",
    "Edit User": "Test User"
  }
}
```

## Updating the Deployment

If you make changes to the Apps Script code:

1. Make your changes in the Apps Script editor
2. Save the file (Ctrl+S)
3. Click **Deploy** > **Manage deployments**
4. Click the pencil icon ✏️ next to your deployment
5. In the "Version" dropdown, select **New version**
6. Add a description of changes
7. Click **Deploy**

**Note**: The Web App URL remains the same, so you don't need to update the Flutter app.

## Troubleshooting

### Error: "Script function not found: doGet"
- Make sure you copied all the code from Code.gs
- Save the file and try deploying again

### Error: "Authorization Required"
- You need to authorize the script to access your Google Sheets
- Follow the authorization steps in "Test the Setup"

### API Returns "Invalid action"
- Check that you're passing the correct action parameter
- Verify the request format matches the examples

### Data Not Saving
- Check the execution logs: View > Executions
- Verify the sheet names match exactly (case-sensitive)
- Ensure the headers in the sheets match the expected format

### CORS Errors
- Make sure "Who has access" is set to "Anyone"
- Redeploy the script if you changed this setting

## Security Notes

- **Do not share your Web App URL publicly** - it has full access to your spreadsheet
- Consider implementing API key validation in the script
- Regularly review the execution logs for suspicious activity
- Use the principle of least privilege - only give access to necessary users

## API Reference

### Available Actions

#### GET Requests:
- `getRawTable` - Get all raw table entries
- `getUsers` - Get all users
- `getUserByToken&token=TOKEN` - Get user by token

#### POST Requests:
- `addRawTable` - Add new raw table entry
- `updateRawTable` - Update existing raw table entry
- `deleteRawTable` - Delete raw table entry
- `addUser` - Add new user
- `updateUser` - Update existing user
- `deleteUser` - Delete user

### Response Format

All responses follow this format:
```json
{
  "success": true/false,
  "data": <data object or array>,
  "message": "Optional message"
}
```

## Support

If you encounter issues:
1. Check the Apps Script execution logs
2. Verify your sheet structure matches the requirements
3. Test the API endpoints manually
4. Check the Flutter app console for errors

/**
 * Invoice Management System - Google Apps Script (Optimized)
 * Spreadsheet ID: 1UIz7-qxhIZfkl1YMwN45k9TaIO13CMsn8V6l3gbtFm4
 * 
 * Workflow:
 * 1. Admin: Paste invoices → Generate Data Hive Report
 * 2. Stylist: Open PWA → Enter token → View/export reports
 */

// Configuration
const DATA_SHEET_NAME = 'Paste Data Here';
const STYLIST_SHEET_NAME = 'Stylist';
const DATA_START_ROW = 3;

// Column indexes (0-based)
const COLS = {
  INVOICE_DATE: 0,
  INVOICE_NUMBER: 1,
  STYLIST: 2,
  CUSTOMER_NAME: 3,
  PAYMENT: 14,
  TOTAL: 11,
  INVOICE_TOTAL: 13
};

/**
 * Creates custom menu when spreadsheet opens
 */
function onOpen() {
  const ui = SpreadsheetApp.getUi();
  ui.createMenu('📊 Invoice Tools')
    .addItem('📊 Generate Data Hive Report', 'generateDataHive')
    .addToUi();
}

/**
 * Get the data sheet
 */
function getDataSheet() {
  const ss = SpreadsheetApp.getActiveSpreadsheet();
  return ss.getSheetByName(DATA_SHEET_NAME) || ss.getActiveSheet();
}

/**
 * Get all invoice data from Paste Data Here sheet
 */
function getInvoiceData() {
  const sheet = getDataSheet();
  const lastRow = sheet.getLastRow();
  
  if (lastRow < DATA_START_ROW) {
    return [];
  }
  
  const lastCol = sheet.getLastColumn();
  const range = sheet.getRange(DATA_START_ROW, 1, lastRow - DATA_START_ROW + 1, lastCol);
  return range.getValues();
}

/**
 * Generate Data Hive Report
 * - Consolidates rows by grouping: Invoice Date, Invoice Number, Stylist, Customer Name
 * - Sums amounts for duplicate invoices
 * - Prevents duplicate entries when report is run multiple times
 * - Appends new data (preserves existing records)
 */
function generateDataHive() {
  const data = getInvoiceData();
  
  if (data.length === 0) {
    SpreadsheetApp.getUi().alert('No data found!');
    return;
  }
  
  const ss = SpreadsheetApp.getActiveSpreadsheet();
  const dataHiveSheet = ss.getSheetByName('Data Hive');
  
  if (!dataHiveSheet) {
    SpreadsheetApp.getUi().alert('Error: "Data Hive" tab not found! Please create it with headers:\nInvoice Date | Invoice Number | Stylist | Customer Name | Amount | Invoice Amount');
    return;
  }
  
  // Get starting row (preserve existing data)
  const existingLastRow = dataHiveSheet.getLastRow();
  const startRow = Math.max(2, existingLastRow + 1);
  
  // Build existing keys to prevent duplicates
  const existingKeys = {};
  if (existingLastRow > 1) {
    const existingData = dataHiveSheet.getRange(2, 1, existingLastRow - 1, 6).getValues();
    existingData.forEach(row => {
      existingKeys[`${row[0]}|${row[1]}|${row[2]}|${row[3]}`] = true;
    });
  }
  
  // Group and consolidate data
  const groupedData = {};
  
  data.forEach(row => {
    const key = `${row[COLS.INVOICE_DATE]}|${row[COLS.INVOICE_NUMBER]}|${row[COLS.STYLIST]}|${row[COLS.CUSTOMER_NAME]}`;
    
    // Skip duplicates
    if (existingKeys[key]) {
      return;
    }
    
    if (!groupedData[key]) {
      groupedData[key] = {
        invoiceDate: row[COLS.INVOICE_DATE],
        invoiceNumber: row[COLS.INVOICE_NUMBER],
        stylist: row[COLS.STYLIST],
        customerName: row[COLS.CUSTOMER_NAME],
        amount: 0,
        invoiceTotal: parseFloat(row[COLS.INVOICE_TOTAL]) || 0
      };
    }
    
    groupedData[key].amount += parseFloat(row[COLS.PAYMENT]) || parseFloat(row[COLS.TOTAL]) || 0;
  });
  
  // Build report data
  const reportData = [];
  Object.values(groupedData).forEach(item => {
    reportData.push([
      item.invoiceDate,
      item.invoiceNumber,
      item.stylist,
      item.customerName,
      item.amount,
      item.invoiceTotal
    ]);
  });
  
  // Sort by date and invoice number
  reportData.sort((a, b) => {
    const dateCompare = new Date(a[0]) - new Date(b[0]);
    return dateCompare !== 0 ? dateCompare : a[1].localeCompare(b[1]);
  });
  
  // Write to sheet
  if (reportData.length > 0) {
    dataHiveSheet.getRange(startRow, 1, reportData.length, 6).setValues(reportData);
    dataHiveSheet.getRange(startRow, 1, reportData.length, 1).setNumberFormat('yyyy-mm-dd');
    dataHiveSheet.getRange(startRow, 5, reportData.length, 2).setNumberFormat('#,##0.00');
  }
  
  SpreadsheetApp.setActiveSheet(dataHiveSheet);
  
  // Display results
  const totalRows = startRow + reportData.length - 2;
  const duplicatesSkipped = data.length - Object.keys(groupedData).length;
  
  let message = '✅ Data Hive updated successfully!\n\n';
  message += '📊 Summary:\n';
  message += '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n';
  message += '✨ New rows added: ' + reportData.length + '\n';
  if (duplicatesSkipped > 0) {
    message += '🚫 Duplicates skipped: ' + duplicatesSkipped + '\n';
  }
  message += '📈 Total rows in Data Hive: ' + totalRows + '\n';
  message += '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n\n';
  message += '✅ Ready to share with stylists!';
  
  SpreadsheetApp.getUi().alert(message);
}

/**
 * Web App Endpoint: Provide data to PWA
 * Usage:
 *   ?action=stylists → Get all stylists with tokens
 *   ?action=reports → Get all Data Hive reports
 */
function doGet(e) {
  try {
    const action = e.parameter.action || 'stylists';
    return action === 'reports' ? getDataHiveReports() : getStylistsData();
  } catch (error) {
    return ContentService.createTextOutput(JSON.stringify({
      success: false,
      error: error.toString()
    })).setMimeType(ContentService.MimeType.JSON);
  }
}

/**
 * API: Get all stylists with tokens from Stylist sheet
 */
function getStylistsData() {
  const ss = SpreadsheetApp.getActiveSpreadsheet();
  const stylistSheet = ss.getSheetByName(STYLIST_SHEET_NAME);
  
  if (!stylistSheet) {
    return ContentService.createTextOutput(JSON.stringify({
      success: false,
      error: 'Stylist sheet not found'
    })).setMimeType(ContentService.MimeType.JSON);
  }
  
  const lastRow = stylistSheet.getLastRow();
  if (lastRow < 2) {
    return ContentService.createTextOutput(JSON.stringify({
      success: false,
      error: 'No stylists found'
    })).setMimeType(ContentService.MimeType.JSON);
  }
  
  const data = stylistSheet.getRange(2, 1, lastRow - 1, 2).getValues();
  const stylists = [];
  
  data.forEach(row => {
    if (row[0] && row[1]) {
      stylists.push({
        name: row[0].toString().trim(),
        token: row[1].toString().trim()
      });
    }
  });
  
  return ContentService.createTextOutput(JSON.stringify({
    success: true,
    stylists: stylists
  })).setMimeType(ContentService.MimeType.JSON);
}

/**
 * API: Get all Data Hive reports
 */
function getDataHiveReports() {
  const ss = SpreadsheetApp.getActiveSpreadsheet();
  const hiveSheet = ss.getSheetByName('Data Hive');
  
  if (!hiveSheet) {
    return ContentService.createTextOutput(JSON.stringify({
      success: false,
      error: 'Data Hive sheet not found'
    })).setMimeType(ContentService.MimeType.JSON);
  }
  
  const lastRow = hiveSheet.getLastRow();
  if (lastRow < 2) {
    return ContentService.createTextOutput(JSON.stringify({
      success: true,
      reports: []
    })).setMimeType(ContentService.MimeType.JSON);
  }
  
  const data = hiveSheet.getRange(2, 1, lastRow - 1, 6).getValues();
  const reports = data.map(row => ({
    date: row[0] ? row[0].toString() : '',
    invoiceNumber: row[1] ? row[1].toString() : '',
    stylist: row[2] ? row[2].toString() : '',
    customerName: row[3] ? row[3].toString() : '',
    amount: parseFloat(row[4]) || 0,
    invoiceTotal: parseFloat(row[5]) || 0
  }));
  
  return ContentService.createTextOutput(JSON.stringify({
    success: true,
    reports: reports
  })).setMimeType(ContentService.MimeType.JSON);
}

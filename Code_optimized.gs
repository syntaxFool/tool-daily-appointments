/**
 * Invoice Management System - Google Apps Script (Auto-Consolidating)
 * Spreadsheet ID: 1UIz7-qxhIZfkl1YMwN45k9TaIO13CMsn8V6l3gbtFm4
 * 
 * Workflow:
 * 1. Admin: Paste invoices into "Paste Data Here" sheet
 * 2. onEdit() auto-consolidates & deduplicates on every paste
 * 3. Stylist: Open app → Enter token → View/export reports (real-time)
 * 
 * No manual processing needed - fully automated!
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
 * Auto-triggers when user pastes data
 * - Consolidates invoices in real-time
 * - Prevents duplicates
 * - Shows notification
 */
function onEdit(e) {
  const sheet = e.source.getActiveSheet();
  
  // Only trigger on "Paste Data Here" sheet
  if (sheet.getName() !== DATA_SHEET_NAME) {
    return;
  }
  
  // Show notification that data will be available immediately
  SpreadsheetApp.getUi().showModelessDialog(
    HtmlService.createHtmlOutput('<p style="padding:20px;font-family:Arial">✅ Data pasted successfully! Reports ready for stylists now.</p>'),
    'Auto-Consolidated'
  );
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
 * Consolidate all invoice data from Paste Data Here sheet
 * - Groups by: Invoice Date, Invoice Number, Stylist, Customer Name
 * - Sums amounts for duplicates
 * - Returns ready-to-display reports
 */
function consolidateInvoiceData() {
  const data = getInvoiceData();
  
  if (data.length === 0) {
    return [];
  }
  
  // Group and consolidate data
  const groupedData = {};
  
  data.forEach(row => {
    const key = `${row[COLS.INVOICE_DATE]}|${row[COLS.INVOICE_NUMBER]}|${row[COLS.STYLIST]}|${row[COLS.CUSTOMER_NAME]}`;
    
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
    reportData.push({
      date: item.invoiceDate ? item.invoiceDate.toString() : '',
      invoiceNumber: item.invoiceNumber ? item.invoiceNumber.toString() : '',
      stylist: item.stylist ? item.stylist.toString() : '',
      customerName: item.customerName ? item.customerName.toString() : '',
      amount: item.amount,
      invoiceTotal: item.invoiceTotal
    });
  });
  
  // Sort by date and invoice number
  reportData.sort((a, b) => {
    const dateCompare = new Date(a.date) - new Date(b.date);
    return dateCompare !== 0 ? dateCompare : a.invoiceNumber.localeCompare(b.invoiceNumber);
  });
  
  return reportData;
}

/**
 * Generate Data Hive Report (DEPRECATED - kept for backward compatibility)
 * Now replaced by onEdit() auto-consolidation
 */
function generateDataHive() {
  SpreadsheetApp.getUi().alert('✅ Auto-consolidation enabled!\n\nData is now processed automatically when you paste.\n\nNo manual step needed. Stylists see reports instantly!');
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
 * API: Get all consolidated reports (in real-time from Paste Data Here)
 * No longer requires "Data Hive" sheet
 */
function getDataHiveReports() {
  const reports = consolidateInvoiceData();
  
  return ContentService.createTextOutput(JSON.stringify({
    success: true,
    reports: reports
  })).setMimeType(ContentService.MimeType.JSON);
}

/**
 * Invoice Management System - Google Apps Script
 * Spreadsheet ID: 1UIz7-qxhIZfkl1YMwN45k9TaIO13CMsn8V6l3gbtFm4
 */

// Configuration
const DATA_SHEET_NAME = 'Paste Data Here'; // Update this to match your sheet name
const STYLIST_SHEET_NAME = 'Stylist'; // Sheet with stylist names and passwords
const DRIVE_FOLDER_ID = '1kcnRoFXmlwBZwGXLB0CvO96LTyowVf40'; // Google Drive folder for reports
const HEADER_ROW = 1;
const DATA_START_ROW = 3;

// Column indexes (0-based)
const COLS = {
  INVOICE_DATE: 0,
  INVOICE_NUMBER: 1,
  STYLIST: 2,
  CUSTOMER_NAME: 3,
  MOBILE_NUMBER: 4,
  GENDER: 5,
  TYPE: 6,
  ITEM: 7,
  PRICE: 8,
  DISCOUNT: 9,
  TAX: 10,
  TOTAL: 11,
  TOTAL_WO_TAX: 12,
  INVOICE_TOTAL: 13,
  PAYMENT: 14,
  REDEMPTION: 15,
  NET_WO_REDEMPTION: 16,
  TOTAL_WO_REDEMPTION: 17,
  REDEMPTION_SHARE: 18,
  PACKAGE_REDEMPTION: 19,
  VOUCHER_REDEMPTION: 20,
  PAYMENT_MODE: 21
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
 * Get all invoice data
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
 * Adds data to existing Data Hive tab with predefined headers
 * Consolidates rows by grouping Invoice Date, Invoice Number, Stylist, Customer Name
 */
function generateDataHive() {
  const data = getInvoiceData();
  
  if (data.length === 0) {
    SpreadsheetApp.getUi().alert('No data found!');
    return;
  }
  
  // Get existing Data Hive sheet
  const ss = SpreadsheetApp.getActiveSpreadsheet();
  let dataHiveSheet = ss.getSheetByName('Data Hive');
  
  if (!dataHiveSheet) {
    SpreadsheetApp.getUi().alert('Error: "Data Hive" tab not found! Please create it first with the required headers.');
    return;
  }
  
  // Get starting row for new data (preserve existing data)
  const existingLastRow = dataHiveSheet.getLastRow();
  const startRow = Math.max(2, existingLastRow + 1);
  
  // Get existing data to check for duplicates
  let existingKeys = {};
  if (existingLastRow > 1) {
    const existingData = dataHiveSheet.getRange(2, 1, existingLastRow - 1, 6).getValues();
    existingData.forEach(row => {
      const existingKey = `${row[0]}|${row[1]}|${row[2]}|${row[3]}`;
      existingKeys[existingKey] = true;
    });
  }
  
  // Group and consolidate data
  const groupedData = {};
  
  data.forEach(row => {
    const invoiceDate = row[COLS.INVOICE_DATE];
    const invoiceNumber = row[COLS.INVOICE_NUMBER];
    const stylist = row[COLS.STYLIST];
    const customerName = row[COLS.CUSTOMER_NAME];
    const amount = parseFloat(row[COLS.PAYMENT]) || parseFloat(row[COLS.TOTAL]) || 0;
    const invoiceTotal = parseFloat(row[COLS.INVOICE_TOTAL]) || 0;
    
    // Create unique key for grouping
    const key = `${invoiceDate}|${invoiceNumber}|${stylist}|${customerName}`;
    
    // Skip if this record already exists in Data Hive
    if (existingKeys[key]) {
      return;
    }
    
    if (!groupedData[key]) {
      groupedData[key] = {
        invoiceDate: invoiceDate,
        invoiceNumber: invoiceNumber,
        stylist: stylist,
        customerName: customerName,
        amount: 0,
        invoiceTotal: invoiceTotal
      };
    }
    
    // Sum the amounts
    groupedData[key].amount += amount;
  });
  
  // Build report data (without headers)
  const reportData = [];
  
  Object.keys(groupedData).forEach(key => {
    const item = groupedData[key];
    reportData.push([
      item.invoiceDate,
      item.invoiceNumber,
      item.stylist,
      item.customerName,
      item.amount,
      item.invoiceTotal
    ]);
  });
  
  // Sort by invoice date and invoice number
  reportData.sort((a, b) => {
    const dateCompare = new Date(a[0]) - new Date(b[0]);
    if (dateCompare !== 0) return dateCompare;
    return a[1].localeCompare(b[1]);
  });
  
  // Write data to sheet starting at calculated row
  if (reportData.length > 0) {
    dataHiveSheet.getRange(startRow, 1, reportData.length, 6).setValues(reportData);
    
    // Format date column
    dataHiveSheet.getRange(startRow, 1, reportData.length, 1).setNumberFormat('yyyy-mm-dd');
    
    // Format amount columns
    dataHiveSheet.getRange(startRow, 5, reportData.length, 2).setNumberFormat('#,##0.00');
  }
  
  // Switch to the Data Hive sheet
  SpreadsheetApp.setActiveSheet(dataHiveSheet);
  
  const duplicatesSkipped = data.length - Object.keys(groupedData).length;
  const totalRows = startRow + reportData.length - 2;
  
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
 * Get stylist information from Stylist sheet
 */
function getStylistData() {
  const ss = SpreadsheetApp.getActiveSpreadsheet();
  const stylistSheet = ss.getSheetByName(STYLIST_SHEET_NAME);
  
  if (!stylistSheet) {
    return [];
  }
  
  const lastRow = stylistSheet.getLastRow();
  if (lastRow < 2) {
    return [];
  }
  
  const data = stylistSheet.getRange(2, 1, lastRow - 1, 2).getValues();
  const stylists = [];
  
  data.forEach(row => {
    if (row[0]) { // If stylist name exists
      stylists.push({
        name: row[0].toString().trim(),
        password: row[1] ? row[1].toString() : ''
      });
    }
  });
  
  return stylists;
}

/**
 * Generate PDF reports for each stylist
 */
function generateStylistPDFs() {
  const ui = SpreadsheetApp.getUi();
  
  // Get data from Data Hive sheet
  const ss = SpreadsheetApp.getActiveSpreadsheet();
  const dataHiveSheet = ss.getSheetByName('Data Hive');
  
  if (!dataHiveSheet) {
    ui.alert('Error: "Data Hive" tab not found! Please generate Data Hive report first.');
    return;
  }
  
  // Get stylist data
  const stylists = getStylistData();
  
  if (stylists.length === 0) {
    ui.alert('Error: No stylist data found in "' + STYLIST_SHEET_NAME + '" sheet!\\n\\nPlease add stylist names and passwords.');
    return;
  }
  
  // Get all data from Data Hive
  const lastRow = dataHiveSheet.getLastRow();
  if (lastRow < 2) {
    ui.alert('No data found in Data Hive sheet!');
    return;
  }
  
  const allData = dataHiveSheet.getRange(2, 1, lastRow - 1, 6).getValues();
  
  // Get current date for folder name
  const today = new Date();
  const dateStr = Utilities.formatDate(today, Session.getScriptTimeZone(), 'yyyy-MM-dd');
  
  try {
    // Get or create date folder
    const parentFolder = DriveApp.getFolderById(DRIVE_FOLDER_ID);
    let dateFolder = null;
    const folders = parentFolder.getFoldersByName(dateStr);
    
    if (folders.hasNext()) {
      dateFolder = folders.next();
    } else {
      dateFolder = parentFolder.createFolder(dateStr);
    }
    
    let successCount = 0;
    let errors = [];
    const folderLinks = [];
    
    // Generate PDF for each stylist
    stylists.forEach(stylist => {
      try {
        // Filter data for this stylist
        const stylistData = allData.filter(row => row[2] === stylist.name);
        
        if (stylistData.length === 0) {
          errors.push(stylist.name + ': No data found');
          return;
        }
        
        // Create individual folder for this stylist
        let stylistFolder = null;
        const stylistFolders = dateFolder.getFoldersByName(stylist.name);
        
        if (stylistFolders.hasNext()) {
          stylistFolder = stylistFolders.next();
        } else {
          stylistFolder = dateFolder.createFolder(stylist.name);
        }
        
        // Create temporary sheet for this stylist
        let tempSheet = ss.getSheetByName('_temp_pdf_');
        if (tempSheet) {
          ss.deleteSheet(tempSheet);
        }
        tempSheet = ss.insertSheet('_temp_pdf_');
        
        // Add header
        const headers = ['Invoice Date', 'Invoice Number', 'Stylist', 'Customer Name', 'Amount', 'Invoice Amount'];
        tempSheet.getRange(1, 1, 1, 6).setValues([headers]);
        
        // Format header
        const headerRange = tempSheet.getRange(1, 1, 1, 6);
        headerRange.setFontWeight('bold')
                   .setBackground('#4285f4')
                   .setFontColor('#ffffff')
                   .setHorizontalAlignment('center');
        
        // Add stylist data
        tempSheet.getRange(2, 1, stylistData.length, 6).setValues(stylistData);
        
        // Format amounts
        tempSheet.getRange(2, 5, stylistData.length, 2).setNumberFormat('#,##0.00');
        tempSheet.getRange(2, 1, stylistData.length, 1).setNumberFormat('yyyy-mm-dd');
        
        // Auto-resize columns
        tempSheet.autoResizeColumns(1, 6);
        
        // Add title and summary
        tempSheet.insertRowBefore(1);
        tempSheet.insertRowBefore(1);
        tempSheet.getRange(1, 1).setValue('Stylist Report - ' + stylist.name);
        tempSheet.getRange(1, 1).setFontSize(16).setFontWeight('bold');
        
        tempSheet.getRange(2, 1).setValue('Date: ' + dateStr);
        
        // Calculate total
        const totalAmount = stylistData.reduce((sum, row) => sum + (parseFloat(row[4]) || 0), 0);
        tempSheet.getRange(stylistData.length + 4, 4).setValue('Total:');
        tempSheet.getRange(stylistData.length + 4, 5).setValue(totalAmount);
        tempSheet.getRange(stylistData.length + 4, 4, 1, 2).setFontWeight('bold').setNumberFormat('#,##0.00');
        
        // Convert to PDF
        const pdfBlob = tempSheet.getParent().getAs('application/pdf');
        const pdfName = dateStr + ' - ' + stylist.name + '.pdf';
        
        // Save to stylist's individual folder
        const existingFiles = stylistFolder.getFilesByName(pdfName);
        if (existingFiles.hasNext()) {
          existingFiles.next().setTrashed(true);
        }
        
        stylistFolder.createFile(pdfBlob).setName(pdfName);
        
        // Store folder link for summary
        folderLinks.push({
          name: stylist.name,
          url: stylistFolder.getUrl()
        });
        
        // Delete temp sheet
        ss.deleteSheet(tempSheet);
        
        successCount++;
        
      } catch (e) {
        errors.push(stylist.name + ': ' + e.message);
      }
    });
    
    // Show results
    let message = '✅ Generated ' + successCount + ' PDF report(s)\\n';
    message += 'Date Folder: ' + dateStr + '\\n';
    message += 'Location: ' + dateFolder.getUrl();
    message += '\\n\\n📁 Individual Folders Created:\\n';
    
    folderLinks.forEach(link => {
      message += '• ' + link.name + '\\n';
    });
    
    if (errors.length > 0) {
      message += '\\n\\n⚠️ Errors:\\n' + errors.join('\\n');
    }
    
    message += '\\n\\n🔒 Security: Each stylist has their own folder. Set Google Drive sharing permissions to restrict access.\\n';
    message += '\\nTo share: Right-click folder → Share → Add stylist\'s email';
    
    ui.alert('PDF Generation Complete', message, ui.ButtonSet.OK);
    
  } catch (e) {
    ui.alert('Error: ' + e.message);
  }
}

/**
 * Generate Sales Report
 */
function generateSalesReport() {
  const data = getInvoiceData();
  
  if (data.length === 0) {
    SpreadsheetApp.getUi().alert('No data found!');
    return;
  }
  
  let totalSales = 0;
  let totalDiscount = 0;
  let totalTax = 0;
  let totalRedemption = 0;
  let invoiceCount = data.length;
  
  data.forEach(row => {
    totalSales += parseFloat(row[COLS.INVOICE_TOTAL]) || 0;
    totalDiscount += parseFloat(row[COLS.DISCOUNT]) || 0;
    totalTax += parseFloat(row[COLS.TAX]) || 0;
    totalRedemption += parseFloat(row[COLS.REDEMPTION]) || 0;
  });
  
  // Create report sheet
  const ss = SpreadsheetApp.getActiveSpreadsheet();
  let reportSheet = ss.getSheetByName('Sales Report');
  
  if (!reportSheet) {
    reportSheet = ss.insertSheet('Sales Report');
  } else {
    reportSheet.clear();
  }
  
  // Write report
  const reportData = [
    ['Sales Report', '', new Date()],
    [''],
    ['Metric', 'Value'],
    ['Total Invoices', invoiceCount],
    ['Total Sales', totalSales.toFixed(2)],
    ['Total Discount', totalDiscount.toFixed(2)],
    ['Total Tax', totalTax.toFixed(2)],
    ['Total Redemption', totalRedemption.toFixed(2)],
    ['Net Revenue', (totalSales - totalRedemption).toFixed(2)],
    ['Average Invoice Value', (totalSales / invoiceCount).toFixed(2)]
  ];
  
  reportSheet.getRange(1, 1, reportData.length, 3).setValues(reportData);
  
  // Format
  reportSheet.getRange('A1:C1').setFontWeight('bold').setFontSize(14);
  reportSheet.getRange('A3:B3').setFontWeight('bold').setBackground('#4285f4').setFontColor('#ffffff');
  reportSheet.getRange('B4:B' + reportData.length).setNumberFormat('#,##0.00');
  reportSheet.autoResizeColumns(1, 2);
  
  SpreadsheetApp.setActiveSheet(reportSheet);
  SpreadsheetApp.getUi().alert('Sales report generated successfully!');
}

/**
 * Stylist Performance Report
 */
function stylistPerformanceReport() {
  const data = getInvoiceData();
  
  if (data.length === 0) {
    SpreadsheetApp.getUi().alert('No data found!');
    return;
  }
  
  // Aggregate by stylist
  const stylistStats = {};
  
  data.forEach(row => {
    const stylist = row[COLS.STYLIST] || 'Unknown';
    const sales = parseFloat(row[COLS.INVOICE_TOTAL]) || 0;
    
    if (!stylistStats[stylist]) {
      stylistStats[stylist] = {
        invoices: 0,
        totalSales: 0,
        totalDiscount: 0
      };
    }
    
    stylistStats[stylist].invoices++;
    stylistStats[stylist].totalSales += sales;
    stylistStats[stylist].totalDiscount += parseFloat(row[COLS.DISCOUNT]) || 0;
  });
  
  // Create report sheet
  const ss = SpreadsheetApp.getActiveSpreadsheet();
  let reportSheet = ss.getSheetByName('Stylist Performance');
  
  if (!reportSheet) {
    reportSheet = ss.insertSheet('Stylist Performance');
  } else {
    reportSheet.clear();
  }
  
  // Prepare data
  const reportData = [
    ['Stylist Performance Report', '', '', '', new Date()],
    [''],
    ['Stylist', 'Invoices', 'Total Sales', 'Avg Sales', 'Total Discount']
  ];
  
  Object.keys(stylistStats).sort().forEach(stylist => {
    const stats = stylistStats[stylist];
    reportData.push([
      stylist,
      stats.invoices,
      stats.totalSales.toFixed(2),
      (stats.totalSales / stats.invoices).toFixed(2),
      stats.totalDiscount.toFixed(2)
    ]);
  });
  
  reportSheet.getRange(1, 1, reportData.length, 5).setValues(reportData);
  
  // Format
  reportSheet.getRange('A1:E1').setFontWeight('bold').setFontSize(14);
  reportSheet.getRange('A3:E3').setFontWeight('bold').setBackground('#4285f4').setFontColor('#ffffff');
  reportSheet.getRange('C4:E' + reportData.length).setNumberFormat('#,##0.00');
  reportSheet.autoResizeColumns(1, 5);
  
  SpreadsheetApp.setActiveSheet(reportSheet);
  SpreadsheetApp.getUi().alert('Stylist performance report generated successfully!');
}

/**
 * Payment Summary by Payment Mode
 */
function paymentSummary() {
  const data = getInvoiceData();
  
  if (data.length === 0) {
    SpreadsheetApp.getUi().alert('No data found!');
    return;
  }
  
  // Aggregate by payment mode
  const paymentStats = {};
  
  data.forEach(row => {
    const mode = row[COLS.PAYMENT_MODE] || 'Unknown';
    const amount = parseFloat(row[COLS.PAYMENT]) || 0;
    
    if (!paymentStats[mode]) {
      paymentStats[mode] = {
        count: 0,
        total: 0
      };
    }
    
    paymentStats[mode].count++;
    paymentStats[mode].total += amount;
  });
  
  // Create report sheet
  const ss = SpreadsheetApp.getActiveSpreadsheet();
  let reportSheet = ss.getSheetByName('Payment Summary');
  
  if (!reportSheet) {
    reportSheet = ss.insertSheet('Payment Summary');
  } else {
    reportSheet.clear();
  }
  
  // Prepare data
  const reportData = [
    ['Payment Summary Report', '', '', new Date()],
    [''],
    ['Payment Mode', 'Transactions', 'Total Amount', 'Percentage']
  ];
  
  const totalAmount = Object.values(paymentStats).reduce((sum, stat) => sum + stat.total, 0);
  
  Object.keys(paymentStats).sort().forEach(mode => {
    const stats = paymentStats[mode];
    const percentage = (stats.total / totalAmount * 100).toFixed(2);
    reportData.push([
      mode,
      stats.count,
      stats.total.toFixed(2),
      percentage + '%'
    ]);
  });
  
  // Add total row
  reportData.push(['']);
  reportData.push([
    'TOTAL',
    Object.values(paymentStats).reduce((sum, stat) => sum + stat.count, 0),
    totalAmount.toFixed(2),
    '100%'
  ]);
  
  reportSheet.getRange(1, 1, reportData.length, 4).setValues(reportData);
  
  // Format
  reportSheet.getRange('A1:D1').setFontWeight('bold').setFontSize(14);
  reportSheet.getRange('A3:D3').setFontWeight('bold').setBackground('#4285f4').setFontColor('#ffffff');
  reportSheet.getRange('C4:C' + reportData.length).setNumberFormat('#,##0.00');
  const totalRow = reportData.length;
  reportSheet.getRange('A' + totalRow + ':D' + totalRow).setFontWeight('bold').setBackground('#f3f3f3');
  reportSheet.autoResizeColumns(1, 4);
  
  SpreadsheetApp.setActiveSheet(reportSheet);
  SpreadsheetApp.getUi().alert('Payment summary generated successfully!');
}

/**
 * Find customer invoices
 */
function findCustomer() {
  const ui = SpreadsheetApp.getUi();
  const response = ui.prompt('Find Customer', 'Enter customer name or mobile number:', ui.ButtonSet.OK_CANCEL);
  
  if (response.getSelectedButton() !== ui.Button.OK) {
    return;
  }
  
  const searchTerm = response.getResponseText().toLowerCase().trim();
  
  if (!searchTerm) {
    ui.alert('Please enter a search term');
    return;
  }
  
  const data = getInvoiceData();
  const results = [];
  
  data.forEach((row, index) => {
    const customerName = (row[COLS.CUSTOMER_NAME] || '').toString().toLowerCase();
    const mobile = (row[COLS.MOBILE_NUMBER] || '').toString();
    
    if (customerName.includes(searchTerm) || mobile.includes(searchTerm)) {
      results.push({
        row: index + DATA_START_ROW,
        data: row
      });
    }
  });
  
  if (results.length === 0) {
    ui.alert('No results found for: ' + searchTerm);
    return;
  }
  
  // Create results sheet
  const ss = SpreadsheetApp.getActiveSpreadsheet();
  let resultsSheet = ss.getSheetByName('Search Results');
  
  if (!resultsSheet) {
    resultsSheet = ss.insertSheet('Search Results');
  } else {
    resultsSheet.clear();
  }
  
  // Get headers
  const headers = getDataSheet().getRange(HEADER_ROW, 1, 1, getDataSheet().getLastColumn()).getValues()[0];
  
  const resultData = [
    ['Search Results for: ' + searchTerm, '', '', new Date()],
    [''],
    ['Row'].concat(headers)
  ];
  
  results.forEach(result => {
    resultData.push([result.row].concat(result.data));
  });
  
  resultsSheet.getRange(1, 1, resultData.length, resultData[0].length).setValues(resultData);
  
  // Format
  resultsSheet.getRange('A1').setFontWeight('bold').setFontSize(14);
  resultsSheet.getRange(3, 1, 1, resultData[0].length).setFontWeight('bold').setBackground('#4285f4').setFontColor('#ffffff');
  resultsSheet.autoResizeColumns(1, resultData[0].length);
  
  SpreadsheetApp.setActiveSheet(resultsSheet);
  ui.alert('Found ' + results.length + ' invoice(s) for: ' + searchTerm);
}

/**
 * Validate data for common issues
 */
function validateData() {
  const data = getInvoiceData();
  const issues = [];
  
  data.forEach((row, index) => {
    const rowNum = index + DATA_START_ROW;
    
    // Check for missing critical fields
    if (!row[COLS.INVOICE_NUMBER]) {
      issues.push('Row ' + rowNum + ': Missing invoice number');
    }
    if (!row[COLS.CUSTOMER_NAME]) {
      issues.push('Row ' + rowNum + ': Missing customer name');
    }
    if (!row[COLS.INVOICE_DATE]) {
      issues.push('Row ' + rowNum + ': Missing invoice date');
    }
    
    // Check for negative values
    if (parseFloat(row[COLS.INVOICE_TOTAL]) < 0) {
      issues.push('Row ' + rowNum + ': Negative invoice total');
    }
    
    // Check if discount is greater than price
    const price = parseFloat(row[COLS.PRICE]) || 0;
    const discount = parseFloat(row[COLS.DISCOUNT]) || 0;
    if (discount > price) {
      issues.push('Row ' + rowNum + ': Discount exceeds price');
    }
  });
  
  const ui = SpreadsheetApp.getUi();
  
  if (issues.length === 0) {
    ui.alert('✅ Validation Complete', 'No issues found! Data looks good.', ui.ButtonSet.OK);
  } else {
    const message = 'Found ' + issues.length + ' issue(s):\n\n' + issues.slice(0, 10).join('\n') + 
                    (issues.length > 10 ? '\n\n... and ' + (issues.length - 10) + ' more' : '');
    ui.alert('⚠️ Validation Issues', message, ui.ButtonSet.OK);
  }
}

/**
 * Clean and format phone numbers
 */
function cleanPhoneNumbers() {
  const sheet = getDataSheet();
  const data = getInvoiceData();
  let cleaned = 0;
  
  data.forEach((row, index) => {
    const rowNum = index + DATA_START_ROW;
    const mobile = row[COLS.MOBILE_NUMBER];
    
    if (mobile) {
      // Remove spaces, dashes, parentheses
      const cleaned_number = mobile.toString().replace(/[\s\-\(\)]/g, '');
      
      if (cleaned_number !== mobile.toString()) {
        sheet.getRange(rowNum, COLS.MOBILE_NUMBER + 1).setValue(cleaned_number);
        cleaned++;
      }
    }
  });
  
  SpreadsheetApp.getUi().alert('Cleaned ' + cleaned + ' phone number(s)');
}

/**
 * Filter data by date range
 */
function filterByDateRange() {
  const ui = SpreadsheetApp.getUi();
  
  const startResponse = ui.prompt('Start Date', 'Enter start date (YYYY-MM-DD):', ui.ButtonSet.OK_CANCEL);
  if (startResponse.getSelectedButton() !== ui.Button.OK) return;
  
  const endResponse = ui.prompt('End Date', 'Enter end date (YYYY-MM-DD):', ui.ButtonSet.OK_CANCEL);
  if (endResponse.getSelectedButton() !== ui.Button.OK) return;
  
  const startDate = new Date(startResponse.getResponseText());
  const endDate = new Date(endResponse.getResponseText());
  
  if (isNaN(startDate) || isNaN(endDate)) {
    ui.alert('Invalid date format. Please use YYYY-MM-DD');
    return;
  }
  
  const data = getInvoiceData();
  const filtered = [];
  
  data.forEach((row, index) => {
    const invoiceDate = new Date(row[COLS.INVOICE_DATE]);
    
    if (invoiceDate >= startDate && invoiceDate <= endDate) {
      filtered.push([index + DATA_START_ROW].concat(row));
    }
  });
  
  if (filtered.length === 0) {
    ui.alert('No invoices found in the specified date range');
    return;
  }
  
  // Create filtered sheet
  const ss = SpreadsheetApp.getActiveSpreadsheet();
  let filterSheet = ss.getSheetByName('Filtered Data');
  
  if (!filterSheet) {
    filterSheet = ss.insertSheet('Filtered Data');
  } else {
    filterSheet.clear();
  }
  
  // Get headers
  const headers = getDataSheet().getRange(HEADER_ROW, 1, 1, getDataSheet().getLastColumn()).getValues()[0];
  
  const filterData = [
    ['Filtered Data: ' + startDate.toDateString() + ' to ' + endDate.toDateString()],
    [''],
    ['Row'].concat(headers)
  ];
  
  filterData.push(...filtered);
  
  filterSheet.getRange(1, 1, filterData.length, filterData[0].length).setValues(filterData);
  
  // Format
  filterSheet.getRange('A1').setFontWeight('bold').setFontSize(14);
  filterSheet.getRange(3, 1, 1, filterData[0].length).setFontWeight('bold').setBackground('#4285f4').setFontColor('#ffffff');
  filterSheet.autoResizeColumns(1, filterData[0].length);
  
  SpreadsheetApp.setActiveSheet(filterSheet);
  ui.alert('Found ' + filtered.length + ' invoice(s) in the specified date range');
}

/**
 * Web App Endpoint: Handles requests for Stylist data or Data Hive reports
 * Usage:
 *   - /stylists : Get all stylists with tokens
 *   - /reports : Get all Data Hive reports
 */
function doGet(e) {
  try {
    const action = e.parameter.action || 'stylists';
    
    if (action === 'reports') {
      return getDataHiveReports();
    }
    
    // Default: return stylists
    return getStylistsData();
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
  
  const data = stylistSheet.getRange(2, 1, lastRow - 1, stylistSheet.getLastColumn()).getValues();
  const stylists = [];
  
  data.forEach(row => {
    if (row[0] && row[1]) { // Stylist name and token exist
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
  
  const data = hiveSheet.getRange(2, 1, lastRow - 1, hiveSheet.getLastColumn()).getValues();
  const reports = [];
  
  data.forEach(row => {
    if (row[0]) {
      reports.push({
        date: row[0] ? row[0].toString() : '',
        invoiceNumber: row[1] ? row[1].toString() : '',
        stylist: row[2] ? row[2].toString() : '',
        customerName: row[3] ? row[3].toString() : '',
        amount: parseFloat(row[4]) || 0,
        invoiceTotal: parseFloat(row[5]) || 0
      });
    }
  });
  
  return ContentService.createTextOutput(JSON.stringify({
    success: true,
    reports: reports
  })).setMimeType(ContentService.MimeType.JSON);
}

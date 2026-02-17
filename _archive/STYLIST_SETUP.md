# Stylist Sheet Setup Guide

## Sheet Name
Create a new sheet in your Google Spreadsheet and name it exactly: **Stylist**

## Structure

### Row 1 - Headers:
| Column A | Column B |
|----------|----------|
| Stylist Name | Password |

### Row 2 onwards - Data:
| Column A | Column B |
|----------|----------|
| Gufran Mansuri | password123 |
| Shanu Sir (F) | abc456 |
| John Doe | secure789 |

## Important Notes

1. **Exact Match Required**: Stylist names in this sheet must **exactly match** the names in your "Paste Data Here" sheet
   - Case sensitive
   - Include all spaces and special characters
   - Example: "Shanu Sir (F)" not "Shanu Sir"

2. **Password Limitation**: 
   - Passwords are stored but **NOT currently applied** to PDFs
   - Google Apps Script does not support PDF password protection natively
   - You can:
     - Leave passwords blank for now
     - Store them for future use with external services
     - Use them for reference/documentation

3. **No Empty Rows**: Don't leave empty rows between stylist entries

4. **Starting Row**: Data must start at Row 2 (Row 1 is for headers)

## Example Setup

```
     A              B
1  | Stylist Name | Password
2  | Gufran Mansuri | pass123
3  | Shanu Sir (F) | pass456
4  | Amit Kumar | pass789
5  | Priya Singh | pass000
```

## Validation

After setting up, you can verify by:
1. Running the "Generate Stylist PDFs" function
2. Check if all stylists from your data are recognized
3. Errors will show which stylists are missing from the sheet

## Tips

- Keep this sheet updated when new stylists are added
- Passwords can be used for future features or external integrations
- Consider using strong passwords even though they're not currently enforced

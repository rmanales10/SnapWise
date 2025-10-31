# Monthly Reset Implementation

## Overview
This document explains the monthly reset functionality that automatically resets financial data at the start of each month while preserving history.

## What Gets Reset Monthly

### ✅ Resets Every Month (with history preserved):

1. **Income**
   - Current income is reset to 0.0
   - Previous month's income is archived to `incomeHistory` collection
   - User needs to set new income for the month

2. **Expense Totals**
   - Total spent amount resets (calculated dynamically)
   - Individual expense records remain in `expenses` collection for history
   - Monthly totals are archived to `expenseTotalsHistory` collection

3. **Overall Budget**
   - Current overall budget is reset
   - Previous month's budget is archived to `budgetHistory` collection
   - If prediction exists: automatically applies prediction to new month
   - If no prediction: resets to 0.0

4. **Category Budgets**
   - Current category budgets are archived to `budgetHistory`
   - Old budgets remain in `budget` collection for history
   - If prediction exists: automatically creates new category budgets from prediction
   - If no prediction: user sets new budgets manually

### ❌ Does NOT Reset (persists across months):

1. **Favorites**
   - Favorites remain unchanged across months
   - Payment history is preserved

2. **Graph Data**
   - Historical expense records remain for graph visualization
   - Graph shows data from all months

3. **Individual Expense Records**
   - All expense records remain in Firestore for history
   - Can be viewed in transaction history

## How It Works

### Automatic Detection
The system checks for monthly reset when:
- App starts (in `HomeController.onInit()`)
- User logs in

### Reset Process
1. **Archive Current Month Data**
   - Income → `incomeHistory`
   - Expense totals → `expenseTotalsHistory`
   - Budgets → `budgetHistory`

2. **Reset Current Values**
   - Income → 0.0
   - Budgets → 0.0 (or apply prediction)
   - Expense totals → calculated dynamically from current month

3. **Apply Predictions (if saved)**
   - Checks `predictionBudget` collection
   - If prediction exists, automatically sets:
     - Overall budget from prediction
     - Category budgets from prediction
   - If no prediction, values remain at 0

### Firestore Collections

#### History Collections (created by reset):
- `incomeHistory` - Historical income records
- `expenseTotalsHistory` - Monthly expense totals
- `budgetHistory` - Historical budget records (overall + categories)

#### Active Collections (reset but keep history):
- `income` - Current month income
- `expenses` - All expense records (never deleted)
- `overallBudget` - Current overall budget
- `budget` - Current category budgets

#### Persisted Collections (never reset):
- `favorites` - Favorite payments
- `predictionBudget` - Saved predictions

## Implementation Files

1. **lib/services/monthly_reset_service.dart**
   - Main service handling reset logic
   - Archives data to history collections
   - Applies predictions automatically

2. **lib/main.dart**
   - Initializes `MonthlyResetService` at app start

3. **lib/app/home/home_screens/home_controller.dart**
   - Calls reset check on initialization

## Testing

To test the monthly reset:
1. Set some income, budgets, and add expenses
2. Change your device date to the next month
3. Restart the app
4. Check that:
   - Income is reset to 0
   - Budgets are reset (or applied from prediction)
   - Previous month data is archived to history collections
   - Expense records remain visible in history

## Notes

- The reset only runs once per month (tracked in `users` collection)
- If you have a saved prediction, it will automatically apply budgets for the new month
- Expense records are never deleted - they remain for historical viewing
- Favorites continue unchanged across months


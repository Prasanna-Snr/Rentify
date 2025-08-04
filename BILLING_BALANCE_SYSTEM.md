# Enhanced Billing and Payment System with Running Balance

## Overview
This system implements a comprehensive billing and payment tracking mechanism where tenants can pay more or less than the billed amount, with proper advance and due amount tracking.

## Key Features

### 1. Running Balance Tracking
- **TenantBalanceModel**: Maintains current balance per tenant
- **Positive Balance**: Tenant owes money (Due)
- **Negative Balance**: Tenant has advance payment
- **Zero Balance**: All settled

### 2. Bill Generation Logic
```dart
// When generating a new bill:
1. Get current tenant balance (carry-forward amount)
2. Calculate current month charges (rent + utilities)
3. Total bill = Current charges + Carry-forward balance
4. Update tenant balance with new charges
```

### 3. Payment Processing Logic
```dart
// When recording a payment:
1. Get current tenant balance
2. Subtract payment amount from balance
3. Update tenant balance
4. Determine payment status (Paid/Partial/Advance)
```

## Data Models

### TenantBalanceModel
```dart
class TenantBalanceModel {
  final String tenantId;
  final double currentBalance; // +ve = Due, -ve = Advance
  final DateTime lastUpdated;
  final String lastTransactionType; // 'bill' or 'payment'
  
  // Helper methods
  bool get hasDue => currentBalance > 0;
  bool get hasAdvance => currentBalance < 0;
  String get formattedBalance; // "₹500 Due" or "₹200 Advance"
}
```

### Enhanced BillModel
```dart
class BillModel {
  // ... existing fields
  final double carryForwardAmount; // From previous balance
  final double totalAmount; // Base charges + carry-forward
}
```

## Service Methods

### BillingService Enhanced Methods

#### getTenantBalance(String tenantId)
- Returns current balance for a tenant
- Used for displaying balance status

#### generateBill(...)
- Allows unlimited bill generation (no monthly restrictions)
- Gets current balance as carry-forward
- Calculates total with carry-forward
- Updates tenant balance with new charges

#### addPayment(...)
- Records payment against tenant
- Updates tenant balance (reduces due/increases advance)
- Handles bill-specific payments
- Determines payment status automatically

#### _updateTenantBalance(...)
- Internal method to update balance
- Tracks transaction type and ID
- Maintains audit trail

## UI Enhancements

### 1. Current Balance Card (Bill Section)
- Shows tenant's current balance with color coding:
  - **Red**: Due amount (tenant owes money)
  - **Green**: Advance amount (tenant paid extra)
  - **Blue**: Balanced (no dues/advance)

### 2. Home Screen Tenant Cards
- Display balance status on each tenant card
- Color-coded indicators for quick overview
- Shows formatted balance amount

### 3. Payment History Section
- Enhanced summary cards with accurate balance calculation
- Real-time balance updates after payments
- Improved ledger display with balance context

## Usage Examples

### Scenario 1: Tenant Pays Less Than Bill
```
Bill Amount: ₹5000
Payment: ₹3000
Result: ₹2000 Due (will be added to next bill)
```

### Scenario 2: Tenant Pays More Than Bill
```
Bill Amount: ₹5000
Payment: ₹6000
Result: ₹1000 Advance (will be deducted from next bill)
```

### Scenario 3: Next Bill Generation with Advance
```
Previous Balance: -₹1000 (Advance)
Current Month Charges: ₹5000
Total Bill: ₹4000 (₹5000 - ₹1000)
```

### Scenario 4: Next Bill Generation with Due
```
Previous Balance: +₹2000 (Due)
Current Month Charges: ₹5000
Total Bill: ₹7000 (₹5000 + ₹2000)
```

## Database Structure

### Firestore Collections
```
users/{userId}/
├── tenants/{tenantId}/
│   ├── bills/{billId}
│   └── payments/{paymentId}
└── tenant_balances/{tenantId}
```

### tenant_balances Document
```json
{
  "id": "tenant_id",
  "tenantId": "tenant_id",
  "tenantName": "John Doe",
  "currentBalance": -500.0,
  "lastUpdated": 1640995200000,
  "lastTransactionType": "payment",
  "lastTransactionId": "payment_id"
}
```

## Benefits

1. **Accurate Balance Tracking**: No manual calculations needed
2. **Automatic Carry-Forward**: Previous dues/advances automatically included
3. **Visual Indicators**: Color-coded UI for quick status understanding
4. **Audit Trail**: Complete transaction history with balance updates
5. **Flexible Payments**: Supports partial, full, and advance payments
6. **Data Consistency**: Single source of truth for tenant balances
7. **Unlimited Bill Generation**: No restrictions on bill frequency

## Implementation Notes

- Balance calculations are performed server-side for consistency
- UI updates reflect real-time balance changes
- Error handling for edge cases (duplicate bills, invalid payments)
- Recalculation method available for data correction
- Initialization method for new tenants

## Future Enhancements

1. **Payment Reminders**: Based on due amounts
2. **Balance Alerts**: Notifications for high due amounts
3. **Payment Plans**: Installment tracking for large dues
4. **Reporting**: Balance summary reports
5. **Bulk Operations**: Mass payment processing
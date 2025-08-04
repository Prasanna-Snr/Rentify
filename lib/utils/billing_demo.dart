/// Demo utility to showcase the billing and balance system
/// This file demonstrates how the enhanced billing system works
import '../models/tenant_model.dart';
import '../services/billing_service.dart';

class BillingDemo {
  final BillingService _billingService = BillingService();

  /// Demonstrates a complete billing cycle with various payment scenarios
  Future<void> demonstrateBillingCycle(TenantModel tenant) async {
    print('=== BILLING SYSTEM DEMO ===');
    print('Tenant: ${tenant.displayName}');
    print('Monthly Rent: ₹${tenant.roomRent}');
    print('');

    // Initialize tenant balance
    await _billingService.initializeTenantBalance(tenant.id, tenant.tenantName);
    await _printCurrentBalance(tenant.id);

    // Scenario 1: Generate first bill
    print('--- Scenario 1: Generate First Bill ---');
    await _billingService.generateBill(
      tenant: tenant,
      billDate: DateTime(2024, 1, 1),
      includeWater: tenant.hasWaterBill,
      waterAmount: tenant.waterBillAmount,
      includeGarbage: tenant.hasGarbageBill,
      garbageAmount: tenant.garbageBillAmount,
      includeElectricity: tenant.hasElectricityBill,
      electricityAmount: tenant.hasElectricityBill ? 500.0 : null, // Example electricity bill
    );
    await _printCurrentBalance(tenant.id);

    // Scenario 1.1: Generate another bill for same month (now allowed)
    print('--- Scenario 1.1: Generate Another Bill (Same Month) ---');
    await _billingService.generateBill(
      tenant: tenant,
      billDate: DateTime(2024, 1, 15), // Same month, different date
      includeWater: false,
      includeGarbage: false,
      includeElectricity: tenant.hasElectricityBill,
      electricityAmount: tenant.hasElectricityBill ? 200.0 : null, // Additional electricity bill
    );
    await _printCurrentBalance(tenant.id);

    // Scenario 2: Tenant pays less than bill amount (creates due)
    print('--- Scenario 2: Partial Payment (Creates Due) ---');
    await _billingService.addPayment(
      tenant: tenant,
      amount: tenant.roomRent - 1000, // Pay ₹1000 less
      paymentType: 'Cash',
      paymentDate: DateTime(2024, 1, 15),
      notes: 'Partial payment - will pay remaining next month',
    );
    await _printCurrentBalance(tenant.id);

    // Scenario 3: Generate second bill (includes previous due)
    print('--- Scenario 3: Generate Second Bill (With Previous Due) ---');
    await _billingService.generateBill(
      tenant: tenant,
      billDate: DateTime(2024, 2, 1),
      includeWater: tenant.hasWaterBill,
      waterAmount: tenant.waterBillAmount,
      includeGarbage: tenant.hasGarbageBill,
      garbageAmount: tenant.garbageBillAmount,
      includeElectricity: tenant.hasElectricityBill,
      electricityAmount: tenant.hasElectricityBill ? 600.0 : null,
    );
    await _printCurrentBalance(tenant.id);

    // Scenario 4: Tenant pays more than bill amount (creates advance)
    print('--- Scenario 4: Overpayment (Creates Advance) ---');
    final balance = await _billingService.getTenantBalance(tenant.id);
    final overpaymentAmount = (balance?.currentBalance ?? 0) + 2000; // Pay ₹2000 extra
    
    await _billingService.addPayment(
      tenant: tenant,
      amount: overpaymentAmount,
      paymentType: 'Bank Transfer',
      paymentDate: DateTime(2024, 2, 15),
      notes: 'Full payment plus advance for next month',
    );
    await _printCurrentBalance(tenant.id);

    // Scenario 5: Generate third bill (with advance deduction)
    print('--- Scenario 5: Generate Third Bill (With Advance Deduction) ---');
    await _billingService.generateBill(
      tenant: tenant,
      billDate: DateTime(2024, 3, 1),
      includeWater: tenant.hasWaterBill,
      waterAmount: tenant.waterBillAmount,
      includeGarbage: tenant.hasGarbageBill,
      garbageAmount: tenant.garbageBillAmount,
      includeElectricity: tenant.hasElectricityBill,
      electricityAmount: tenant.hasElectricityBill ? 450.0 : null,
    );
    await _printCurrentBalance(tenant.id);

    print('=== DEMO COMPLETED ===');
    print('');
  }

  /// Helper method to print current balance status
  Future<void> _printCurrentBalance(String tenantId) async {
    final balance = await _billingService.getTenantBalance(tenantId);
    if (balance != null) {
      print('Current Balance: ${balance.formattedBalance}');
      if (balance.hasDue) {
        print('  → Tenant owes ₹${balance.dueAmount.toStringAsFixed(0)}');
        print('  → This will be added to the next bill');
      } else if (balance.hasAdvance) {
        print('  → Tenant has ₹${balance.advanceAmount.toStringAsFixed(0)} advance');
        print('  → This will be deducted from the next bill');
      } else {
        print('  → All payments are up to date');
      }
    } else {
      print('Current Balance: No balance data found');
    }
    print('');
  }

  /// Demonstrates different payment scenarios
  Future<void> demonstratePaymentScenarios(TenantModel tenant) async {
    print('=== PAYMENT SCENARIOS DEMO ===');
    
    // Reset balance
    await _billingService.initializeTenantBalance(tenant.id, tenant.tenantName);
    
    // Generate a bill first
    await _billingService.generateBill(
      tenant: tenant,
      billDate: DateTime.now(),
      includeWater: tenant.hasWaterBill,
      waterAmount: tenant.waterBillAmount,
      includeGarbage: tenant.hasGarbageBill,
      garbageAmount: tenant.garbageBillAmount,
      includeElectricity: tenant.hasElectricityBill,
      electricityAmount: tenant.hasElectricityBill ? 500.0 : null,
    );

    final bills = await _billingService.getTenantBills(tenant.id);
    final currentBill = bills.first;
    final billAmount = currentBill.totalAmount;

    print('Generated Bill: ₹${billAmount.toStringAsFixed(0)}');
    print('');

    // Scenario A: Exact payment
    print('--- Scenario A: Exact Payment ---');
    print('Payment: ₹${billAmount.toStringAsFixed(0)} (Exact amount)');
    await _billingService.addPayment(
      tenant: tenant,
      amount: billAmount,
      paymentType: 'Cash',
      paymentDate: DateTime.now(),
      billId: currentBill.id,
    );
    await _printCurrentBalance(tenant.id);

    // Reset for next scenario
    await _billingService.recalculateTenantBalance(tenant.id, tenant.tenantName);

    // Scenario B: Partial payment
    print('--- Scenario B: Partial Payment ---');
    final partialAmount = billAmount * 0.7; // 70% of bill
    print('Payment: ₹${partialAmount.toStringAsFixed(0)} (70% of bill)');
    await _billingService.addPayment(
      tenant: tenant,
      amount: partialAmount,
      paymentType: 'Bank Transfer',
      paymentDate: DateTime.now(),
      billId: currentBill.id,
    );
    await _printCurrentBalance(tenant.id);

    // Scenario C: Overpayment
    print('--- Scenario C: Overpayment ---');
    final remainingAmount = billAmount - partialAmount;
    final overpayment = remainingAmount + 1500; // Pay remaining + ₹1500 extra
    print('Payment: ₹${overpayment.toStringAsFixed(0)} (Remaining + ₹1500 advance)');
    await _billingService.addPayment(
      tenant: tenant,
      amount: overpayment,
      paymentType: 'UPI',
      paymentDate: DateTime.now(),
      billId: currentBill.id,
    );
    await _printCurrentBalance(tenant.id);

    print('=== PAYMENT SCENARIOS COMPLETED ===');
  }

  /// Shows how balance affects next bill generation
  Future<void> demonstrateBalanceCarryForward(TenantModel tenant) async {
    print('=== BALANCE CARRY-FORWARD DEMO ===');
    
    // Initialize
    await _billingService.initializeTenantBalance(tenant.id, tenant.tenantName);
    
    // Create a due scenario
    await _billingService.generateBill(
      tenant: tenant,
      billDate: DateTime(2024, 1, 1),
      includeWater: false,
      includeGarbage: false,
      includeElectricity: false,
    );
    
    // Partial payment creating due
    await _billingService.addPayment(
      tenant: tenant,
      amount: tenant.roomRent - 2000, // ₹2000 short
      paymentType: 'Cash',
      paymentDate: DateTime(2024, 1, 15),
    );
    
    print('After partial payment:');
    await _printCurrentBalance(tenant.id);
    
    // Generate next bill - should include the due amount
    print('Generating next month bill...');
    await _billingService.generateBill(
      tenant: tenant,
      billDate: DateTime(2024, 2, 1),
      includeWater: false,
      includeGarbage: false,
      includeElectricity: false,
    );
    
    final bills = await _billingService.getTenantBills(tenant.id);
    final latestBill = bills.first;
    
    print('New Bill Details:');
    print('  Base Rent: ₹${tenant.roomRent}');
    print('  Carry-forward Due: ₹${latestBill.carryForwardAmount}');
    print('  Total Bill: ₹${latestBill.totalAmount}');
    print('');
    
    // Now create advance scenario
    await _billingService.addPayment(
      tenant: tenant,
      amount: latestBill.totalAmount + 3000, // Pay bill + ₹3000 advance
      paymentType: 'Bank Transfer',
      paymentDate: DateTime(2024, 2, 15),
    );
    
    print('After overpayment:');
    await _printCurrentBalance(tenant.id);
    
    // Generate next bill - should deduct advance
    print('Generating next month bill with advance...');
    await _billingService.generateBill(
      tenant: tenant,
      billDate: DateTime(2024, 3, 1),
      includeWater: false,
      includeGarbage: false,
      includeElectricity: false,
    );
    
    final finalBills = await _billingService.getTenantBills(tenant.id);
    final finalBill = finalBills.first;
    
    print('Final Bill Details:');
    print('  Base Rent: ₹${tenant.roomRent}');
    print('  Carry-forward Advance: ₹${finalBill.carryForwardAmount}');
    print('  Total Bill: ₹${finalBill.totalAmount}');
    
    await _printCurrentBalance(tenant.id);
    
    print('=== CARRY-FORWARD DEMO COMPLETED ===');
  }

  /// Demonstrates unlimited bill generation capability
  Future<void> demonstrateUnlimitedBillGeneration(TenantModel tenant) async {
    print('=== UNLIMITED BILL GENERATION DEMO ===');
    
    // Initialize
    await _billingService.initializeTenantBalance(tenant.id, tenant.tenantName);
    
    // Generate multiple bills for the same month
    print('Generating multiple bills for January 2024...');
    
    // Bill 1: Monthly rent
    print('--- Bill 1: Monthly Rent ---');
    await _billingService.generateBill(
      tenant: tenant,
      billDate: DateTime(2024, 1, 1),
      includeWater: false,
      includeGarbage: false,
      includeElectricity: false,
    );
    await _printCurrentBalance(tenant.id);
    
    // Bill 2: Water bill (mid-month)
    print('--- Bill 2: Water Bill (Mid-Month) ---');
    await _billingService.generateBill(
      tenant: tenant,
      billDate: DateTime(2024, 1, 15),
      includeWater: tenant.hasWaterBill,
      waterAmount: tenant.waterBillAmount,
      includeGarbage: false,
      includeElectricity: false,
    );
    await _printCurrentBalance(tenant.id);
    
    // Bill 3: Electricity bill (end of month)
    print('--- Bill 3: Electricity Bill (End of Month) ---');
    await _billingService.generateBill(
      tenant: tenant,
      billDate: DateTime(2024, 1, 30),
      includeWater: false,
      includeGarbage: false,
      includeElectricity: tenant.hasElectricityBill,
      electricityAmount: tenant.hasElectricityBill ? 800.0 : 0.0,
    );
    await _printCurrentBalance(tenant.id);
    
    // Bill 4: Additional charges (same day as previous)
    print('--- Bill 4: Additional Charges (Same Day) ---');
    await _billingService.generateBill(
      tenant: tenant,
      billDate: DateTime(2024, 1, 30), // Same date as previous bill
      includeWater: false,
      includeGarbage: tenant.hasGarbageBill,
      garbageAmount: tenant.garbageBillAmount,
      includeElectricity: false,
    );
    await _printCurrentBalance(tenant.id);
    
    // Show all bills generated
    final bills = await _billingService.getTenantBills(tenant.id);
    print('--- Total Bills Generated: ${bills.length} ---');
    for (int i = 0; i < bills.length; i++) {
      final bill = bills[i];
      print('Bill ${i + 1}: ₹${bill.totalAmount.toStringAsFixed(0)} on ${bill.billDate.day}/${bill.billDate.month}/${bill.billDate.year}');
    }
    
    // Make a payment to clear some dues
    print('--- Making Payment to Clear Some Dues ---');
    await _billingService.addPayment(
      tenant: tenant,
      amount: tenant.roomRent * 2, // Pay equivalent of 2 months rent
      paymentType: 'Bank Transfer',
      paymentDate: DateTime(2024, 2, 1),
      notes: 'Partial payment towards multiple bills',
    );
    await _printCurrentBalance(tenant.id);
    
    print('=== UNLIMITED BILL GENERATION DEMO COMPLETED ===');
    print('Key Points:');
    print('• Generated ${bills.length} bills without any restrictions');
    print('• Multiple bills can be created for the same month');
    print('• Multiple bills can be created on the same date');
    print('• Balance tracking works correctly with unlimited bills');
    print('• Each bill adds to the running balance automatically');
    print('');
  }
}
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/bill_model.dart';
import '../models/payment_model.dart';
import '../models/tenant_model.dart';
import '../models/tenant_balance_model.dart';
import '../utils/tenant_balance_migration.dart';

class BillingService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Get current user ID
  String? get _currentUserId => _auth.currentUser?.uid;

  // Get current tenant balance from the balance tracking system
  Future<TenantBalanceModel?> getTenantBalance(String tenantId) async {
    try {
      if (_currentUserId == null) return null;

      final doc = await _firestore
          .collection('users')
          .doc(_currentUserId)
          .collection('tenants')
          .doc(tenantId)
          .collection('tenant_balances')
          .doc('current_balance')
          .get();

      if (doc.exists) {
        return TenantBalanceModel.fromMap(doc.data()!);
      }
      return null;
    } catch (e) {
      print('Error getting tenant balance: $e');
      return null;
    }
  }

  // Update tenant balance after bill generation or payment
  Future<void> _updateTenantBalance({
    required String tenantId,
    required String tenantName,
    required double balanceChange,
    required String transactionType,
    required String transactionId,
  }) async {
    try {
      if (_currentUserId == null) return;

      final balanceRef = _firestore
          .collection('users')
          .doc(_currentUserId)
          .collection('tenants')
          .doc(tenantId)
          .collection('tenant_balances')
          .doc('current_balance');

      // Get current balance or create new one
      final currentBalanceDoc = await balanceRef.get();
      double currentBalance = 0.0;

      if (currentBalanceDoc.exists) {
        final balanceModel = TenantBalanceModel.fromMap(currentBalanceDoc.data()!);
        currentBalance = balanceModel.currentBalance;
      }

      // Calculate new balance
      final newBalance = currentBalance + balanceChange;

      final updatedBalance = TenantBalanceModel(
        id: 'current_balance',
        tenantId: tenantId,
        tenantName: tenantName,
        currentBalance: newBalance,
        lastUpdated: DateTime.now(),
        lastTransactionType: transactionType,
        lastTransactionId: transactionId,
      );

      await balanceRef.set(updatedBalance.toMap());
    } catch (e) {
      print('Error updating tenant balance: $e');
    }
  }

  // Calculate carry-forward amount from tenant balance
  Future<double> _getCarryForwardAmount(String tenantId) async {
    try {
      final balance = await getTenantBalance(tenantId);
      return balance?.currentBalance ?? 0.0;
    } catch (e) {
      print('Error getting carry-forward amount: $e');
      return 0.0;
    }
  }



  // Generate a new bill with proper balance tracking (no monthly restrictions)
  Future<String> generateBill({
    required TenantModel tenant,
    required DateTime billDate,
    required bool includeWater,
    double? waterAmount,
    required bool includeGarbage,
    double? garbageAmount,
    required bool includeElectricity,
    double? electricityAmount,
  }) async {
    try {
      if (_currentUserId == null) return 'User not authenticated';

      // Use electricity amount directly if provided
      double? finalElectricityAmount;
      if (includeElectricity && electricityAmount != null) {
        finalElectricityAmount = electricityAmount;
      }

      // Get current tenant balance (carry-forward amount)
      double carryForwardAmount = await _getCarryForwardAmount(tenant.id);

      // Calculate base bill amount (current charges only)
      double baseAmount = tenant.roomRent;
      if (includeWater && waterAmount != null) baseAmount += waterAmount;
      if (includeGarbage && garbageAmount != null) baseAmount += garbageAmount;
      if (finalElectricityAmount != null) baseAmount += finalElectricityAmount;

      // Total amount includes carry-forward
      double totalAmount = baseAmount + carryForwardAmount;

      // Create bill with unique ID and timestamp-based month identifier
      final billId = _firestore.collection('bills').doc().id;
      final billMonth = '${billDate.year}-${billDate.month.toString().padLeft(2, '0')}';
      
      final bill = BillModel(
        id: billId,
        tenantId: tenant.id,
        tenantName: tenant.tenantName,
        billDate: billDate,
        billMonth: billMonth,
        roomRent: tenant.roomRent,
        includeWater: includeWater,
        waterAmount: waterAmount,
        includeGarbage: includeGarbage,
        garbageAmount: garbageAmount,
        includeElectricity: includeElectricity,
        electricityAmount: finalElectricityAmount,
        carryForwardAmount: carryForwardAmount,
        totalAmount: totalAmount,
        balanceAmount: totalAmount, // Initially, full amount is due
        createdAt: DateTime.now(),
      );

      // Save bill to Firestore (no duplicate check - allows multiple bills)
      await _firestore
          .collection('users')
          .doc(_currentUserId)
          .collection('tenants')
          .doc(tenant.id)
          .collection('bills')
          .doc(billId)
          .set(bill.toMap());

      // Update tenant balance: Add the base amount to balance
      // (carry-forward was already included, so we only add new charges)
      await _updateTenantBalance(
        tenantId: tenant.id,
        tenantName: tenant.tenantName,
        balanceChange: baseAmount,
        transactionType: 'bill',
        transactionId: billId,
      );

      return 'success';
    } catch (e) {
      return 'Error generating bill: ${e.toString()}';
    }
  }

  // Get bills for a tenant
  Future<List<BillModel>> getTenantBills(String tenantId) async {
    try {
      if (_currentUserId == null) return [];

      final querySnapshot = await _firestore
          .collection('users')
          .doc(_currentUserId)
          .collection('tenants')
          .doc(tenantId)
          .collection('bills')
          .orderBy('billDate', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => BillModel.fromMap(doc.data()))
          .toList();
    } catch (e) {
      return [];
    }
  }



  // Add payment with proper balance tracking
  Future<String> addPayment({
    required TenantModel tenant,
    required double amount,
    required String paymentType,
    required DateTime paymentDate,
    String? billId,
    String? notes,
  }) async {
    try {
      if (_currentUserId == null) return 'User not authenticated';

      if (amount <= 0) return 'Payment amount must be greater than zero';

      final paymentId = _firestore.collection('payments').doc().id;
      
      // Get current tenant balance
      final currentBalance = await getTenantBalance(tenant.id);
      double tenantCurrentBalance = currentBalance?.currentBalance ?? 0.0;

      // Determine payment status based on current balance and payment amount
      String status;
      String description = 'Payment received';
      
      if (tenantCurrentBalance > 0) {
        // Tenant has due amount
        if (amount >= tenantCurrentBalance) {
          // Payment covers all dues and possibly creates advance
          status = amount == tenantCurrentBalance ? 'Paid' : 'Advance';
          description = amount == tenantCurrentBalance 
              ? 'Payment cleared all dues' 
              : 'Payment cleared dues with advance';
        } else {
          // Partial payment, still has dues
          status = 'Partial';
          description = 'Partial payment towards dues';
        }
      } else if (tenantCurrentBalance < 0) {
        // Tenant already has advance
        status = 'Advance';
        description = 'Additional advance payment';
      } else {
        // Tenant balance is zero
        status = 'Advance';
        description = 'Advance payment';
      }

      // Handle specific bill payment if provided
      if (billId != null) {
        final billDoc = await _firestore
            .collection('users')
            .doc(_currentUserId)
            .collection('tenants')
            .doc(tenant.id)
            .collection('bills')
            .doc(billId)
            .get();

        if (billDoc.exists) {
          final bill = BillModel.fromMap(billDoc.data()!);
          description = 'Payment for ${bill.formattedBillMonth}';
          
          // Update bill's paid amount and status
          final newPaidAmount = bill.paidAmount + amount;
          final newBalanceAmount = bill.totalAmount - newPaidAmount;
          
          String billStatus;
          if (newPaidAmount >= bill.totalAmount) {
            billStatus = 'Paid';
          } else if (newPaidAmount > 0) {
            billStatus = 'Partial';
          } else {
            billStatus = 'Unpaid';
          }

          await _firestore
              .collection('users')
              .doc(_currentUserId)
              .collection('tenants')
              .doc(tenant.id)
              .collection('bills')
              .doc(billId)
              .update({
            'paidAmount': newPaidAmount,
            'balanceAmount': newBalanceAmount,
            'status': billStatus,
            'updatedAt': DateTime.now().millisecondsSinceEpoch,
          });
        }
      }

      // Create payment record
      final payment = PaymentModel(
        id: paymentId,
        tenantId: tenant.id,
        tenantName: tenant.tenantName,
        billId: billId,
        paymentDate: paymentDate,
        amount: amount,
        paymentType: paymentType,
        description: description,
        status: status,
        balanceAmount: 0.0, // Will be calculated from tenant balance
        notes: notes,
        createdAt: DateTime.now(),
      );

      // Save payment to Firestore
      await _firestore
          .collection('users')
          .doc(_currentUserId)
          .collection('tenants')
          .doc(tenant.id)
          .collection('payments')
          .doc(paymentId)
          .set(payment.toMap());

      // Update tenant balance: Subtract payment amount (reduces due or increases advance)
      await _updateTenantBalance(
        tenantId: tenant.id,
        tenantName: tenant.tenantName,
        balanceChange: -amount, // Negative because payment reduces balance
        transactionType: 'payment',
        transactionId: paymentId,
      );

      return 'success';
    } catch (e) {
      return 'Error adding payment: ${e.toString()}';
    }
  }

  // Get payments for a tenant
  Future<List<PaymentModel>> getTenantPayments(String tenantId) async {
    try {
      if (_currentUserId == null) return [];

      final querySnapshot = await _firestore
          .collection('users')
          .doc(_currentUserId)
          .collection('tenants')
          .doc(tenantId)
          .collection('payments')
          .orderBy('paymentDate', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => PaymentModel.fromMap(doc.data()))
          .toList();
    } catch (e) {
      return [];
    }
  }

  // Get all tenant balances for dashboard display
  Future<List<TenantBalanceModel>> getAllTenantBalances() async {
    try {
      if (_currentUserId == null) return [];

      // Get all tenants first
      final tenantsSnapshot = await _firestore
          .collection('users')
          .doc(_currentUserId)
          .collection('tenants')
          .get();

      List<TenantBalanceModel> balances = [];

      // For each tenant, get their balance
      for (final tenantDoc in tenantsSnapshot.docs) {
        final balanceDoc = await _firestore
            .collection('users')
            .doc(_currentUserId)
            .collection('tenants')
            .doc(tenantDoc.id)
            .collection('tenant_balances')
            .doc('current_balance')
            .get();

        if (balanceDoc.exists) {
          balances.add(TenantBalanceModel.fromMap(balanceDoc.data()!));
        }
      }

      return balances;
    } catch (e) {
      print('Error getting all tenant balances: $e');
      return [];
    }
  }

  // Initialize tenant balance (useful when adding new tenant)
  Future<void> initializeTenantBalance(String tenantId, String tenantName) async {
    try {
      if (_currentUserId == null) return;

      final balance = TenantBalanceModel(
        id: 'current_balance',
        tenantId: tenantId,
        tenantName: tenantName,
        currentBalance: 0.0,
        lastUpdated: DateTime.now(),
        lastTransactionType: 'initialization',
        lastTransactionId: null,
      );

      await _firestore
          .collection('users')
          .doc(_currentUserId)
          .collection('tenants')
          .doc(tenantId)
          .collection('tenant_balances')
          .doc('current_balance')
          .set(balance.toMap());
    } catch (e) {
      print('Error initializing tenant balance: $e');
    }
  }

  // Get ledger entries (bills and payments combined) with running balance
  Future<List<Map<String, dynamic>>> getTenantLedger(String tenantId) async {
    try {
      final bills = await getTenantBills(tenantId);
      final payments = await getTenantPayments(tenantId);
      final currentBalance = await getTenantBalance(tenantId);

      List<Map<String, dynamic>> ledgerEntries = [];

      // Add bills
      for (final bill in bills) {
        ledgerEntries.add({
          'type': 'bill',
          'date': bill.billDate,
          'description': 'Bill for ${bill.formattedBillMonth}',
          'amount': bill.totalAmount,
          'status': bill.status,
          'balance': bill.balanceAmount,
          'data': bill,
        });
      }

      // Add payments
      for (final payment in payments) {
        ledgerEntries.add({
          'type': 'payment',
          'date': payment.paymentDate,
          'description': payment.description,
          'amount': payment.amount,
          'status': payment.status,
          'balance': payment.balanceAmount,
          'data': payment,
        });
      }

      // Sort by date (newest first)
      ledgerEntries.sort((a, b) => b['date'].compareTo(a['date']));

      // Add current balance info at the top
      if (currentBalance != null) {
        ledgerEntries.insert(0, {
          'type': 'balance',
          'date': currentBalance.lastUpdated,
          'description': 'Current Balance',
          'amount': currentBalance.currentBalance,
          'status': currentBalance.balanceStatus,
          'balance': currentBalance.currentBalance,
          'data': currentBalance,
        });
      }

      return ledgerEntries;
    } catch (e) {
      return [];
    }
  }

  // Recalculate tenant balance (useful for data correction)
  Future<String> recalculateTenantBalance(String tenantId, String tenantName) async {
    try {
      if (_currentUserId == null) return 'User not authenticated';

      final bills = await getTenantBills(tenantId);
      final payments = await getTenantPayments(tenantId);

      double totalBillAmount = 0.0;
      double totalPaidAmount = 0.0;

      // Calculate total bill amounts
      for (final bill in bills) {
        totalBillAmount += bill.totalAmount;
      }

      // Calculate total paid amounts
      for (final payment in payments) {
        totalPaidAmount += payment.amount;
      }

      // Calculate correct balance
      final correctBalance = totalBillAmount - totalPaidAmount;

      // Update tenant balance
      final balance = TenantBalanceModel(
        id: 'current_balance',
        tenantId: tenantId,
        tenantName: tenantName,
        currentBalance: correctBalance,
        lastUpdated: DateTime.now(),
        lastTransactionType: 'recalculation',
        lastTransactionId: null,
      );

      await _firestore
          .collection('users')
          .doc(_currentUserId)
          .collection('tenants')
          .doc(tenantId)
          .collection('tenant_balances')
          .doc('current_balance')
          .set(balance.toMap());

      return 'Balance recalculated successfully';
    } catch (e) {
      return 'Error recalculating balance: ${e.toString()}';
    }
  }

  // Migration methods
  Future<String> migrateTenantBalances() async {
    final migration = TenantBalanceMigration();
    return await migration.migrateTenantBalances();
  }

  Future<String> cleanupOldBalances() async {
    final migration = TenantBalanceMigration();
    return await migration.cleanupOldBalances();
  }

  Future<String> verifyMigration() async {
    final migration = TenantBalanceMigration();
    return await migration.verifyMigration();
  }
}
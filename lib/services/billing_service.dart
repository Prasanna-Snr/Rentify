import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/bill_model.dart';
import '../models/payment_model.dart';
import '../models/tenant_model.dart';

class BillingService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Get current user ID
  String? get _currentUserId => _auth.currentUser?.uid;

  // Generate a new bill
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

      // Calculate total
      double totalAmount = tenant.roomRent;
      if (includeWater && waterAmount != null) totalAmount += waterAmount;
      if (includeGarbage && garbageAmount != null) totalAmount += garbageAmount;
      if (finalElectricityAmount != null) totalAmount += finalElectricityAmount;

      // Create bill
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
        totalAmount: totalAmount,
        balanceAmount: totalAmount,
        createdAt: DateTime.now(),
      );

      await _firestore
          .collection('users')
          .doc(_currentUserId)
          .collection('tenants')
          .doc(tenant.id)
          .collection('bills')
          .doc(billId)
          .set(bill.toMap());

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



  // Add payment
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

      final paymentId = _firestore.collection('payments').doc().id;
      
      // Determine payment status and balance
      String status = 'Paid';
      double balanceAmount = 0.0;
      String description = 'Payment received';

      if (billId != null) {
        // Payment against specific bill
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
          final remainingAmount = bill.totalAmount - bill.paidAmount;
          
          if (amount == remainingAmount) {
            status = 'Paid';
            balanceAmount = 0.0;
          } else if (amount < remainingAmount) {
            status = 'Due';
            balanceAmount = remainingAmount - amount;
          } else {
            status = 'Advance';
            balanceAmount = amount - remainingAmount;
          }

          description = 'Payment for ${bill.formattedBillMonth}';

          // Update bill
          await _firestore
              .collection('users')
              .doc(_currentUserId)
              .collection('tenants')
              .doc(tenant.id)
              .collection('bills')
              .doc(billId)
              .update({
            'paidAmount': bill.paidAmount + amount,
            'balanceAmount': bill.totalAmount - (bill.paidAmount + amount),
            'status': amount >= remainingAmount ? 'Paid' : 'Partial',
            'updatedAt': DateTime.now().millisecondsSinceEpoch,
          });
        }
      }

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
        balanceAmount: balanceAmount,
        notes: notes,
        createdAt: DateTime.now(),
      );

      await _firestore
          .collection('users')
          .doc(_currentUserId)
          .collection('tenants')
          .doc(tenant.id)
          .collection('payments')
          .doc(paymentId)
          .set(payment.toMap());

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

  // Get ledger entries (bills and payments combined)
  Future<List<Map<String, dynamic>>> getTenantLedger(String tenantId) async {
    try {
      final bills = await getTenantBills(tenantId);
      final payments = await getTenantPayments(tenantId);

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

      return ledgerEntries;
    } catch (e) {
      return [];
    }
  }
}
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/tenant_model.dart';
import '../models/tenant_balance_model.dart';

class TenantService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Get current user ID
  String? get currentUserId => _auth.currentUser?.uid;

  // Get all tenants for current user
  Future<List<TenantModel>> getUserTenants() async {
    try {
      if (currentUserId == null) return [];

      QuerySnapshot snapshot = await _firestore
          .collection('users')
          .doc(currentUserId)
          .collection('tenants')
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => TenantModel.fromMap(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('Error getting tenants: $e');
      return [];
    }
  }

  // Add new tenant
  Future<String?> addTenant(TenantModel tenant) async {
    try {
      if (currentUserId == null) return 'User not authenticated';

      // Create tenant with current user as owner
      String tenantId = _firestore.collection('users').doc(currentUserId).collection('tenants').doc().id;
      TenantModel newTenant = tenant.copyWith(
        id: tenantId,
        ownerId: currentUserId!,
        createdAt: DateTime.now(),
      );

      // Use batch to create tenant and initialize balance atomically
      WriteBatch batch = _firestore.batch();

      // Add tenant document
      DocumentReference tenantRef = _firestore
          .collection('users')
          .doc(currentUserId)
          .collection('tenants')
          .doc(tenantId);
      batch.set(tenantRef, newTenant.toMap());

      // Initialize tenant balance
      final balance = TenantBalanceModel(
        id: 'current_balance',
        tenantId: tenantId,
        tenantName: newTenant.tenantName,
        currentBalance: 0.0,
        lastUpdated: DateTime.now(),
        lastTransactionType: 'initialization',
        lastTransactionId: null,
      );

      DocumentReference balanceRef = _firestore
          .collection('users')
          .doc(currentUserId)
          .collection('tenants')
          .doc(tenantId)
          .collection('tenant_balances')
          .doc('current_balance');
      batch.set(balanceRef, balance.toMap());

      // Commit the batch
      await batch.commit();

      return 'success';
    } catch (e) {
      print('Error adding tenant: $e');
      return 'Failed to add tenant: ${e.toString()}';
    }
  }

  // Update tenant
  Future<String?> updateTenant(TenantModel tenant) async {
    try {
      if (currentUserId == null) return 'User not authenticated';

      // Update tenant with current timestamp
      TenantModel updatedTenant = tenant.copyWith(
        updatedAt: DateTime.now(),
      );

      await _firestore
          .collection('users')
          .doc(currentUserId)
          .collection('tenants')
          .doc(tenant.id)
          .update(updatedTenant.toMap());

      return 'success';
    } catch (e) {
      print('Error updating tenant: $e');
      return 'Failed to update tenant: ${e.toString()}';
    }
  }

  // Delete tenant
  Future<String?> deleteTenant(String tenantId) async {
    try {
      if (currentUserId == null) return 'User not authenticated';

      // Use batch to delete tenant and all related data
      WriteBatch batch = _firestore.batch();

      // Delete tenant document
      DocumentReference tenantRef = _firestore
          .collection('users')
          .doc(currentUserId)
          .collection('tenants')
          .doc(tenantId);
      batch.delete(tenantRef);

      // Delete tenant balance
      DocumentReference balanceRef = _firestore
          .collection('users')
          .doc(currentUserId)
          .collection('tenants')
          .doc(tenantId)
          .collection('tenant_balances')
          .doc('current_balance');
      batch.delete(balanceRef);

      // Note: Bills and payments subcollections will need to be deleted separately
      // as Firestore doesn't cascade delete subcollections
      
      await batch.commit();

      // Clean up subcollections (bills and payments)
      await _deleteSubcollections(tenantId);

      return 'success';
    } catch (e) {
      print('Error deleting tenant: $e');
      return 'Failed to delete tenant: ${e.toString()}';
    }
  }

  // Helper method to delete subcollections
  Future<void> _deleteSubcollections(String tenantId) async {
    try {
      // Delete bills
      final billsSnapshot = await _firestore
          .collection('users')
          .doc(currentUserId)
          .collection('tenants')
          .doc(tenantId)
          .collection('bills')
          .get();

      for (final doc in billsSnapshot.docs) {
        await doc.reference.delete();
      }

      // Delete payments
      final paymentsSnapshot = await _firestore
          .collection('users')
          .doc(currentUserId)
          .collection('tenants')
          .doc(tenantId)
          .collection('payments')
          .get();

      for (final doc in paymentsSnapshot.docs) {
        await doc.reference.delete();
      }
    } catch (e) {
      print('Error deleting subcollections: $e');
    }
  }

  // Get tenant by ID
  Future<TenantModel?> getTenantById(String tenantId) async {
    try {
      if (currentUserId == null) return null;

      DocumentSnapshot doc = await _firestore
          .collection('users')
          .doc(currentUserId)
          .collection('tenants')
          .doc(tenantId)
          .get();

      if (doc.exists) {
        return TenantModel.fromMap(doc.data() as Map<String, dynamic>);
      }
      return null;
    } catch (e) {
      print('Error getting tenant: $e');
      return null;
    }
  }



  // Get tenants stream for real-time updates
  Stream<List<TenantModel>> getUserTenantsStream() {
    if (currentUserId == null) {
      return Stream.value([]);
    }

    return _firestore
        .collection('users')
        .doc(currentUserId)
        .collection('tenants')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => TenantModel.fromMap(doc.data()))
            .toList());
  }
}
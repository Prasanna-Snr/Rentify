import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/tenant_model.dart';

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

      await _firestore
          .collection('users')
          .doc(currentUserId)
          .collection('tenants')
          .doc(tenantId)
          .set(newTenant.toMap());

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

      await _firestore
          .collection('users')
          .doc(currentUserId)
          .collection('tenants')
          .doc(tenantId)
          .delete();

      return 'success';
    } catch (e) {
      print('Error deleting tenant: $e');
      return 'Failed to delete tenant: ${e.toString()}';
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
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/tenant_balance_model.dart';

class TenantBalanceMigration {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? get _currentUserId => _auth.currentUser?.uid;

  // Migrate tenant balances from old structure to new structure
  Future<String> migrateTenantBalances() async {
    try {
      if (_currentUserId == null) return 'User not authenticated';

      print('Starting tenant balance migration...');

      // Get all tenant balances from old structure
      final oldBalancesSnapshot = await _firestore
          .collection('users')
          .doc(_currentUserId)
          .collection('tenant_balances')
          .get();

      if (oldBalancesSnapshot.docs.isEmpty) {
        return 'No tenant balances found to migrate';
      }

      int migratedCount = 0;
      List<String> errors = [];

      for (final balanceDoc in oldBalancesSnapshot.docs) {
        try {
          final balanceData = balanceDoc.data();
          final balance = TenantBalanceModel.fromMap(balanceData);

          // Check if tenant exists
          final tenantDoc = await _firestore
              .collection('users')
              .doc(_currentUserId)
              .collection('tenants')
              .doc(balance.tenantId)
              .get();

          if (!tenantDoc.exists) {
            errors.add('Tenant ${balance.tenantId} not found, skipping balance migration');
            continue;
          }

          // Create balance in new structure
          await _firestore
              .collection('users')
              .doc(_currentUserId)
              .collection('tenants')
              .doc(balance.tenantId)
              .collection('tenant_balances')
              .doc('current_balance')
              .set(balance.copyWith(id: 'current_balance').toMap());

          migratedCount++;
          print('Migrated balance for tenant: ${balance.tenantName}');

        } catch (e) {
          errors.add('Error migrating balance for doc ${balanceDoc.id}: $e');
        }
      }

      String result = 'Migration completed. Migrated $migratedCount balances.';
      if (errors.isNotEmpty) {
        result += '\nErrors: ${errors.join(', ')}';
      }

      print(result);
      return result;

    } catch (e) {
      return 'Migration failed: ${e.toString()}';
    }
  }

  // Clean up old tenant_balances collection after successful migration
  Future<String> cleanupOldBalances() async {
    try {
      if (_currentUserId == null) return 'User not authenticated';

      final oldBalancesSnapshot = await _firestore
          .collection('users')
          .doc(_currentUserId)
          .collection('tenant_balances')
          .get();

      int deletedCount = 0;
      for (final doc in oldBalancesSnapshot.docs) {
        await doc.reference.delete();
        deletedCount++;
      }

      return 'Cleaned up $deletedCount old balance records';
    } catch (e) {
      return 'Cleanup failed: ${e.toString()}';
    }
  }

  // Verify migration by comparing old and new structures
  Future<String> verifyMigration() async {
    try {
      if (_currentUserId == null) return 'User not authenticated';

      // Get old balances
      final oldBalancesSnapshot = await _firestore
          .collection('users')
          .doc(_currentUserId)
          .collection('tenant_balances')
          .get();

      // Get new balances
      final tenantsSnapshot = await _firestore
          .collection('users')
          .doc(_currentUserId)
          .collection('tenants')
          .get();

      int newBalancesCount = 0;
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
          newBalancesCount++;
        }
      }

      return 'Verification: Old balances: ${oldBalancesSnapshot.docs.length}, New balances: $newBalancesCount';
    } catch (e) {
      return 'Verification failed: ${e.toString()}';
    }
  }
}
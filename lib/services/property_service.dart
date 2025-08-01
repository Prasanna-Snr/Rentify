import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/property_model.dart';

class PropertyService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Get current user ID
  String? get currentUserId => _auth.currentUser?.uid;

  // Get all properties for current user
  Future<List<PropertyModel>> getUserProperties() async {
    try {
      if (currentUserId == null) return [];

      QuerySnapshot snapshot = await _firestore
          .collection('users')
          .doc(currentUserId)
          .collection('properties')
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => PropertyModel.fromMap(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('Error getting properties: $e');
      return [];
    }
  }

  // Add new property
  Future<String?> addProperty(PropertyModel property) async {
    try {
      if (currentUserId == null) return 'User not authenticated';

      // Create property with current user as owner
      String propertyId = _firestore.collection('users').doc(currentUserId).collection('properties').doc().id;
      PropertyModel newProperty = property.copyWith(
        id: propertyId,
        ownerId: currentUserId!,
        createdAt: DateTime.now(),
      );

      await _firestore
          .collection('users')
          .doc(currentUserId)
          .collection('properties')
          .doc(propertyId)
          .set(newProperty.toMap());

      return 'success';
    } catch (e) {
      print('Error adding property: $e');
      return 'Failed to add property: ${e.toString()}';
    }
  }

  // Update property
  Future<String?> updateProperty(PropertyModel property) async {
    try {
      if (currentUserId == null) return 'User not authenticated';

      // Update property with current timestamp
      PropertyModel updatedProperty = property.copyWith(
        updatedAt: DateTime.now(),
      );

      await _firestore
          .collection('users')
          .doc(currentUserId)
          .collection('properties')
          .doc(property.id)
          .update(updatedProperty.toMap());

      return 'success';
    } catch (e) {
      print('Error updating property: $e');
      return 'Failed to update property: ${e.toString()}';
    }
  }

  // Delete property
  Future<String?> deleteProperty(String propertyId) async {
    try {
      if (currentUserId == null) return 'User not authenticated';

      await _firestore
          .collection('users')
          .doc(currentUserId)
          .collection('properties')
          .doc(propertyId)
          .delete();

      return 'success';
    } catch (e) {
      print('Error deleting property: $e');
      return 'Failed to delete property: ${e.toString()}';
    }
  }

  // Get property by ID
  Future<PropertyModel?> getPropertyById(String propertyId) async {
    try {
      if (currentUserId == null) return null;

      DocumentSnapshot doc = await _firestore
          .collection('users')
          .doc(currentUserId)
          .collection('properties')
          .doc(propertyId)
          .get();

      if (doc.exists) {
        return PropertyModel.fromMap(doc.data() as Map<String, dynamic>);
      }
      return null;
    } catch (e) {
      print('Error getting property: $e');
      return null;
    }
  }



  // Get properties stream for real-time updates
  Stream<List<PropertyModel>> getUserPropertiesStream() {
    if (currentUserId == null) {
      return Stream.value([]);
    }

    return _firestore
        .collection('users')
        .doc(currentUserId)
        .collection('properties')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => PropertyModel.fromMap(doc.data()))
            .toList());
  }
}
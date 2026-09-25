import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../exceptions/app_exceptions.dart';
import '../models/user_model.dart';

/// Customer Profile Management Service.
/// Handles reading, updating customer profile information, and changing passwords.
class UserService {
  final FirebaseAuth? _customAuth;
  final FirebaseFirestore? _customFirestore;

  UserService({
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
  })  : _customAuth = auth,
        _customFirestore = firestore;

  FirebaseAuth get _auth => _customAuth ?? FirebaseAuth.instance;
  FirebaseFirestore get _firestore => _customFirestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _usersRef =>
      _firestore.collection('users');

  /// Helper to get current authenticated user or throw AuthException if not logged in.
  User _requireCurrentUser() {
    final user = _auth.currentUser;
    if (user == null) {
      throw const AuthException(
        'User is not authenticated. Please log in first.',
        code: 'not-authenticated',
      );
    }
    return user;
  }

  /// Get profile of a customer by UID.
  Future<UserModel?> getCustomerProfile(String uid) async {
    try {
      final doc = await _usersRef.doc(uid).get();
      if (!doc.exists) return null;
      return UserModel.fromFirestore(doc);
    } on FirebaseException catch (e) {
      throw ProfileException('Error fetching customer profile: ${e.message}', code: e.code);
    } catch (e) {
      throw ProfileException('Unexpected error fetching profile: $e');
    }
  }

  /// Get profile of the currently logged in customer.
  Future<UserModel?> getCurrentUserProfile() async {
    final user = _auth.currentUser;
    if (user == null) return null;
    return getCustomerProfile(user.uid);
  }

  /// Real-time stream of the current customer's profile.
  Stream<UserModel?> currentUserProfileStream() {
    final user = _auth.currentUser;
    if (user == null) {
      return Stream.value(null);
    }
    return _usersRef.doc(user.uid).snapshots().map((snapshot) {
      if (!snapshot.exists) return null;
      return UserModel.fromFirestore(snapshot);
    });
  }

  /// Update customer profile details in Firestore.
  /// Any non-null parameter provided will be updated.
  Future<void> updateCustomerProfile({
    String? name,
    String? phone,
    String? address,
  }) async {
    final user = _requireCurrentUser();
    final Map<String, dynamic> updates = {};

    if (name != null) {
      final trimmedName = name.trim();
      if (trimmedName.isEmpty) {
        throw const ProfileException('Name cannot be empty.', code: 'invalid-name');
      }
      updates['name'] = trimmedName;
      updates['Name'] = trimmedName;
      // Also update Firebase Auth displayName
      await user.updateDisplayName(trimmedName);
    }

    if (phone != null) {
      final trimmedPhone = phone.trim();
      if (trimmedPhone.isEmpty) {
        throw const ProfileException('Phone number cannot be empty.', code: 'invalid-phone');
      }
      updates['phone'] = trimmedPhone;
      updates['Phone'] = trimmedPhone;
    }

    if (address != null) {
      final trimmedAddress = address.trim();
      if (trimmedAddress.isEmpty) {
        throw const ProfileException('Address cannot be empty.', code: 'invalid-address');
      }
      updates['address'] = trimmedAddress;
      updates['Address'] = trimmedAddress;
    }

    if (updates.isEmpty) return;

    try {
      await _usersRef.doc(user.uid).update(updates);
    } on FirebaseException catch (e) {
      throw ProfileException('Failed to update profile: ${e.message}', code: e.code);
    } catch (e) {
      throw ProfileException('Unexpected error updating profile: $e');
    }
  }

  /// Update customer's full name.
  Future<void> updateName(String name) async {
    await updateCustomerProfile(name: name);
  }

  /// Update customer's mobile phone number.
  Future<void> updatePhone(String phone) async {
    await updateCustomerProfile(phone: phone);
  }

  /// Update customer's delivery/residential address.
  Future<void> updateAddress(String address) async {
    await updateCustomerProfile(address: address);
  }

  /// Change customer password securely with optional re-authentication.
  ///
  /// If [currentPassword] is provided, it re-authenticates the user with
  /// Firebase Auth first to prevent `requires-recent-login` errors.
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final user = _requireCurrentUser();

    if (newPassword.length < 6) {
      throw const AuthException(
        'New password must be at least 6 characters.',
        code: 'weak-password',
      );
    }

    if (user.email == null) {
      throw const AuthException(
        'User email is missing for password update.',
        code: 'missing-email',
      );
    }

    try {
      // 1. Re-authenticate user with current password
      final credential = EmailAuthProvider.credential(
        email: user.email!,
        password: currentPassword,
      );
      await user.reauthenticateWithCredential(credential);

      // 2. Update password
      await user.updatePassword(newPassword);
    } on FirebaseAuthException catch (e) {
      throw AuthException.fromFirebaseCode(e.code, e.message);
    } catch (e) {
      if (e is AuthException) rethrow;
      throw AuthException('Failed to change password: $e');
    }
  }

  /// Signs out the customer.
  Future<void> logout() async {
    await _auth.signOut();
  }
}

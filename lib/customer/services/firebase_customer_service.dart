import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/customer_order.dart';
import '../models/customer_profile.dart';
import 'customer_codec.dart';

/// All customer documents are scoped to the verified Firebase Auth UID.
class FirebaseCustomerService {
  FirebaseCustomerService(this.auth, this.database);
  final FirebaseAuth auth;
  final FirebaseFirestore database;
  String get uid {
    final value = auth.currentUser?.uid;
    if (value == null) throw StateError('Please sign in again.');
    return value;
  }

  DocumentReference<Map<String, dynamic>> get account =>
      database.collection('users').doc(uid);

  Future<CustomerProfile> register(
    CustomerProfile profile,
    String password,
  ) async {
    final credential = await auth.createUserWithEmailAndPassword(
      email: profile.email,
      password: password,
    );
    try {
      await account.set({
        ...CustomerCodec.profile(profile),
        'role': 'customer',
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (_) {
      // Never report signup success if its Firestore profile was not saved.
      try {
        await credential.user?.delete();
      } catch (_) {
        await auth.signOut();
      }
      rethrow;
    }
    return profile;
  }

  Future<CustomerProfile> signIn(String email, String password) async {
    await auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    try {
      return await loadProfile();
    } catch (_) {
      await auth.signOut();
      rethrow;
    }
  }

  Future<CustomerProfile> loadProfile() async {
    final data = (await account.get(const GetOptions(source: Source.server)))
        .data();
    if (data == null) {
      throw StateError(
        'Your customer profile is missing. Contact support to restore it.',
      );
    }
    if (data['role'] != 'customer') {
      throw StateError('This app is for customer accounts only.');
    }
    return CustomerCodec.readProfile(data);
  }

  Future<void> saveProfile(CustomerProfile profile) async {
    if (profile.email != auth.currentUser!.email) {
      throw StateError(
        'Use your existing sign-in email. Email changes require a separate verification flow.',
      );
    }
    await account.update(CustomerCodec.profile(profile));
  }

  Future<void> resetPassword(String email) =>
      auth.sendPasswordResetEmail(email: email.trim());
  Future<void> changePassword(String current, String next) async {
    final user = auth.currentUser;
    if (user?.email == null) throw StateError('Please sign in again.');
    await user!.reauthenticateWithCredential(
      EmailAuthProvider.credential(email: user.email!, password: current),
    );
    await user.updatePassword(next);
  }

  Future<Map<String, dynamic>> loadPreferences() async =>
      (await account.collection('private').doc('preferences').get()).data() ??
      {};
  Future<void> savePreferences(Map<String, dynamic> value) => account
      .collection('private')
      .doc('preferences')
      .set(value, SetOptions(merge: true));
  Stream<List<CustomerOrder>> watchOrders() =>
      account.collection('orders').snapshots().map((snapshot) {
        final orders = snapshot.docs
            .map((doc) => CustomerCodec.readOrder(doc.data()))
            .toList();
        orders.sort((a, b) => b.date.compareTo(a.date));
        return orders;
      });
  String newOrderId() => account.collection('orders').doc().id;
  Future<void> saveOrder(CustomerOrder order) =>
      account.collection('orders').doc(order.id).set({
        ...CustomerCodec.order(order),
        'customerId': uid,
        'createdAt': FieldValue.serverTimestamp(),
      });
  Future<void> updatePickup(
    CustomerOrder order,
    String farmerId,
    String? slot,
  ) async {
    final ref = account.collection('orders').doc(order.id);
    await database.runTransaction((transaction) async {
      final snapshot = await transaction.get(ref);
      final data = snapshot.data();
      if (data == null || ['Completed', 'Cancelled'].contains(data['status'])) {
        throw StateError('This order can no longer be changed.');
      }
      final pickups = Map<String, String>.from(data['pickups'] as Map? ?? {});
      if (slot == null) {
        pickups.remove(farmerId);
      } else {
        pickups[farmerId] = slot;
      }
      transaction.update(ref, {'pickups': pickups});
    });
  }

  Future<void> sendFeedback(
    String name,
    String email,
    String subject,
    String message,
  ) => account.collection('feedback').add({
    'name': name,
    'email': email,
    'subject': subject,
    'message': message,
    'createdAt': FieldValue.serverTimestamp(),
  });

  static String errorMessage(Object error) {
    if (error is FirebaseAuthException) {
      return switch (error.code) {
        'email-already-in-use' =>
          'This email already has an account. Please sign in.',
        'invalid-credential' ||
        'wrong-password' ||
        'user-not-found' => 'The email or password is incorrect.',
        'weak-password' => 'Choose a stronger password.',
        'too-many-requests' => 'Too many attempts. Please try again later.',
        'network-request-failed' =>
          'Check your internet connection and try again.',
        'operation-not-allowed' =>
          'Email/password sign-in is not enabled for this Firebase project.',
        'user-disabled' => 'This account has been disabled.',
        _ => 'Authentication failed (${error.code}). Please try again.',
      };
    }
    if (error is FirebaseException) {
      return switch (error.code) {
        'permission-denied' => 'Firebase denied access. Check the project and customer Firestore rules.',
        'unavailable' =>
          'Firebase is unavailable. Check your connection and try again.',
        'not-found' => 'The Firebase database or document was not found.',
        _ => 'Data could not be saved (${error.code}). Please try again.',
      };
    }
    if (error is StateError) return error.message;
    return 'The request failed. Please check your connection and try again.';
  }
}

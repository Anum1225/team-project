import 'package:cloud_firestore/cloud_firestore.dart';

/// Centralized Firestore collections helper and references for HarvestHub.
abstract final class FirebaseCollections {
  static const String users = 'users';
  static const String farms = 'farms';
  static const String products = 'products';
  static const String categories = 'categories';
  static const String orders = 'orders';
  static const String checkoutRequests = 'checkoutRequests';
  static const String feedback = 'feedback';
  static const String adminActivityLogs = 'adminActivityLogs';

  static CollectionReference<Map<String, dynamic>> usersRef([
    FirebaseFirestore? db,
  ]) => (db ?? FirebaseFirestore.instance).collection(users);

  static CollectionReference<Map<String, dynamic>> farmsRef([
    FirebaseFirestore? db,
  ]) => (db ?? FirebaseFirestore.instance).collection(farms);

  static CollectionReference<Map<String, dynamic>> productsRef([
    FirebaseFirestore? db,
  ]) => (db ?? FirebaseFirestore.instance).collection(products);

  static CollectionReference<Map<String, dynamic>> categoriesRef([
    FirebaseFirestore? db,
  ]) => (db ?? FirebaseFirestore.instance).collection(categories);

  static CollectionReference<Map<String, dynamic>> ordersRef([
    FirebaseFirestore? db,
  ]) => (db ?? FirebaseFirestore.instance).collection(orders);

  static CollectionReference<Map<String, dynamic>> checkoutRequestsRef([
    FirebaseFirestore? db,
  ]) => (db ?? FirebaseFirestore.instance).collection(checkoutRequests);

  static CollectionReference<Map<String, dynamic>> feedbackRef([
    FirebaseFirestore? db,
  ]) => (db ?? FirebaseFirestore.instance).collection(feedback);

  static CollectionReference<Map<String, dynamic>> adminActivityLogsRef([
    FirebaseFirestore? db,
  ]) => (db ?? FirebaseFirestore.instance).collection(adminActivityLogs);

  static DocumentReference<Map<String, dynamic>> userDoc(
    String uid, [
    FirebaseFirestore? db,
  ]) => usersRef(db).doc(uid);

  static DocumentReference<Map<String, dynamic>> orderDoc(
    String id, [
    FirebaseFirestore? db,
  ]) => ordersRef(db).doc(id);
}

import 'dart:convert';

import '../shared/forms/phone_validation.dart';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Spark-plan persistence: all authorization is enforced again by Firestore rules.
class SparkBackend {
  SparkBackend(this.db, this.auth);
  final FirebaseFirestore db;
  final FirebaseAuth auth;
  String get uid => auth.currentUser!.uid;
  static String categoryId(String name) =>
      base64Url.encode(utf8.encode(name.toLowerCase())).replaceAll('=', '');
  FieldValue get stamp => FieldValue.serverTimestamp();
  Never fail(String message) => throw StateError(message);
  String text(dynamic value, {int max = 500, bool optional = false}) {
    if (value is! String ||
        value.trim().length > max ||
        (!optional && value.trim().isEmpty)) {
      fail('Check the entered details.');
    }
    return value.trim();
  }

  Future<Map<String, dynamic>> call(
    String name,
    Map<String, dynamic> data,
  ) async {
    switch (name) {
      case 'registerProfile':
        final batch = db.batch();
        final name = text(data['name']);
        batch.set(db.doc('users/$uid'), {
          'name': name,
          'email': auth.currentUser!.email,
          'role': data['role'],
          'phone': normalizePhoneNumber(text(data['phone'])),
          'address': text(data['address'], optional: true),
          'active': true,
          'createdAt': stamp,
        });
        if (data['role'] == 'farmer') {
          batch.set(db.doc('farms/$uid'), {
            'name': name,
            'owner': uid,
            'location': '',
            'market': '',
            'description': '',
            'image': '',
            'active': true,
            'createdAt': stamp,
          });
        }
        await batch.commit();
        return {'id': uid};
      case 'mutate':
        return mutate(
          data['action'] as String,
          Map<String, dynamic>.from(data['value']),
        );
      case 'checkout':
        return checkout(data);
      case 'platformReport':
        return report(data['days'] as int);
      case 'submitFeedback':
        await db.collection('feedback').add({
          'userId': uid,
          'email': text(data['email']),
          'message': text(data['message'], max: 5000),
          'createdAt': stamp,
          'read': false,
        });
        return {'ok': true};
      default:
        fail('Unknown operation.');
    }
  }

  Future<Map<String, dynamic>> mutate(
    String action,
    Map<String, dynamic> v,
  ) async {
    // Discover candidate products before the transaction. The category count is
    // checked inside it; concurrent membership changes force retry/reload.
    List<QueryDocumentSnapshot<Map<String, dynamic>>> assigned = [];
    if (action == 'saveCategory' && v['previous'] != null) {
      assigned =
          (await db
                  .collection('products')
                  .where('category', isEqualTo: v['previous'])
                  .where('archived', isEqualTo: false)
                  .limit(400)
                  .get())
              .docs;
      if (assigned.length >= 400) {
        fail('Reassign products in smaller groups before renaming.');
      }
    }
    return db.runTransaction((tx) async {
      final actor = (await tx.get(db.doc('users/$uid'))).data()!;
      final admin = actor['role'] == 'admin';
      if (actor['active'] != true) fail('This account is suspended.');
      if (action == 'saveAccount' || action == 'toggleAccount') {
        final ref = db.doc('users/${v['id']}');
        final target = (await tx.get(ref)).data();
        if (target == null || (!admin && v['id'] != uid)) {
          fail('Access denied.');
        }
        if (action == 'toggleAccount') {
          if (!admin || target['role'] == 'admin' || v['id'] == uid) {
            fail('Administrator accounts cannot be suspended here.');
          }
          final farm = await tx.get(db.doc('farms/${v['id']}'));
          tx.update(ref, {'active': v['active'], 'updatedAt': stamp});
          if (farm.exists) {
            tx.update(farm.reference, {
              'active': v['active'],
              'updatedAt': stamp,
            });
          }
        } else {
          tx.update(ref, {
            'name': text(v['name']),
            'phone': normalizePhoneNumber(text(v['phone'])),
            'address': text(v['address'], optional: true),
            'avatar': text(v['avatar'] ?? '', max: 140000, optional: true),
            'updatedAt': stamp,
          });
        }
      } else if (action == 'saveFarm') {
        final ref = db.doc('farms/${v['id']}');
        final farm = (await tx.get(ref)).data();
        if (farm == null ||
            (!admin && (actor['role'] != 'farmer' || farm['owner'] != uid))) {
          fail('You can only edit your own farm.');
        }
        tx.update(ref, {
          'name': text(v['name']),
          'location': text(v['location'], optional: true),
          'market': text(v['market'], optional: true),
          'description': text(v['description'], optional: true, max: 5000),
          if (v.containsKey('image'))
            'image': text(v['image'], optional: true, max: 140000),
          'pickupSlots': (v['pickupSlots'] as List? ?? [])
              .map((s) => text(s, max: 160))
              .toSet()
              .toList(),
          'lat': v['lat'],
          'lng': v['lng'],
          'updatedAt': stamp,
        });
      } else if (action == 'saveCategory' || action == 'deleteCategory') {
        if (!admin) fail('Administrator access required.');
        final name = text(v['name'], max: 100);
        final previous = v['previous'] ?? name;
        final ref = db.doc('categories/${categoryId(previous)}');
        final dest = db.doc('categories/${categoryId(name)}');
        final old = await tx.get(ref);
        final next = dest.path == ref.path ? old : await tx.get(dest);
        if (action == 'deleteCategory') {
          if (!old.exists || (old.data()!['productCount'] ?? 0) != 0) {
            fail(
              'Move or archive assigned products before deleting this category.',
            );
          }
          tx.delete(ref);
        } else {
          if ((v['previous'] == null || ref.path != dest.path) && next.exists) {
            fail('This category already exists.');
          }
          if (v['previous'] != null &&
              (!old.exists || old.data()!['productCount'] != assigned.length)) {
            fail('Category changed. Refresh and retry.');
          }
          final current = <DocumentSnapshot<Map<String, dynamic>>>[];
          for (final p in assigned) {
            current.add(await tx.get(p.reference));
          }
          if (current.any(
            (p) =>
                p.data()?['category'] != previous ||
                p.data()?['archived'] != false,
          )) {
            fail('Category changed. Refresh and retry.');
          }
          tx.set(dest, {
            'name': name,
            'productCount': assigned.length,
            'createdAt': old.data()?['createdAt'] ?? stamp,
            'updatedAt': stamp,
          });
          if (ref.path != dest.path && v['previous'] != null) tx.delete(ref);
          for (final p in current) {
            tx.update(p.reference, {
              'category': name,
              'categoryId': dest.id,
              'updatedAt': stamp,
            });
          }
        }
      } else if (action == 'saveProduct' || action == 'deleteProduct') {
        final ref = db.doc('products/${v['id']}');
        final old = await tx.get(ref);
        final existing = old.data();
        final deleting = action == 'deleteProduct';
        final farmId = deleting ? (existing?['farmId']) : v['farmId'];
        if (farmId == null || existing?['archived'] == true) {
          fail('Product no longer available.');
        }
        final farm = (await tx.get(db.doc('farms/$farmId'))).data();
        if (farm == null ||
            (!admin && (farm['owner'] != uid || actor['role'] != 'farmer'))) {
          fail('Choose a farm you manage.');
        }
        final category = deleting
            ? existing!['category']
            : text(v['category'], max: 100);
        final catRef = db.doc('categories/${categoryId(category)}');
        final cat = await tx.get(catRef);
        if (!cat.exists) fail('Choose an existing category.');
        final oldRef = existing != null && existing['category'] != category
            ? db.doc('categories/${categoryId(existing['category'])}')
            : null;
        final oldCat = oldRef == null ? null : await tx.get(oldRef);
        if (deleting) {
          tx.update(ref, {'archived': true, 'stock': 0, 'updatedAt': stamp});
          tx.update(catRef, {
            'productCount': (cat.data()!['productCount'] as int) - 1,
            'lastProductId': ref.id,
          });
        } else {
          if (v['price'] is! int ||
              v['stock'] is! int ||
              v['price'] < 0 ||
              v['stock'] < 0) {
            fail('Price and stock must be non-negative.');
          }
          tx.set(ref, {
            'name': text(v['name']),
            'farmId': farmId,
            'farmName': farm['name'],
            'category': category,
            'categoryId': catRef.id,
            'price': v['price'],
            'stock': v['stock'],
            'image': v['image'] ?? '',
            'unit': text(v['unit'], max: 60),
            'description': text(v['description'], optional: true, max: 5000),
            'archived': false,
            'createdAt': existing?['createdAt'] ?? stamp,
            'updatedAt': stamp,
          });
          tx.update(catRef, {
            'productCount':
                (cat.data()!['productCount'] as int) +
                (existing == null || oldRef != null ? 1 : 0),
            'lastProductId': ref.id,
          });
          if (oldCat?.exists == true) {
            tx.update(oldRef!, {
              'productCount': (oldCat!.data()!['productCount'] as int) - 1,
              'lastProductId': ref.id,
            });
          }
        }
      } else if (action == 'updateStatus') {
        final ref = db.doc('orders/${v['id']}');
        final order = (await tx.get(ref)).data();
        if (order == null) fail('Order no longer exists.');
        const next = {
          'pending': 'confirmed',
          'confirmed': 'ready',
          'ready': 'completed',
        };
        if (!next.containsKey(order['status']) ||
            (v['status'] != 'cancelled' &&
                next[order['status']] != v['status'])) {
          fail('Choose the next status. Closed orders cannot change.');
        }
        final products = <DocumentSnapshot<Map<String, dynamic>>>[];
        if (v['status'] == 'cancelled') {
          for (final line in order['items']) {
            products.add(await tx.get(db.doc('products/${line['productId']}')));
          }
        }
        for (var i = 0; i < products.length; i++) {
          final p = products[i];
          if (p.exists && p.data()!['archived'] == false) {
            tx.update(p.reference, {
              'stock': p.data()!['stock'] + order['items'][i]['quantity'],
              'updatedAt': stamp,
            });
          }
        }
        tx.update(ref, {'status': v['status'], 'updatedAt': stamp});
      } else {
        fail('Unknown operation.');
      }
      if (admin) {
        tx.set(db.collection('adminActivityLogs').doc(), {
          'adminId': uid,
          'action': action,
          'entityId': v['id'] ?? v['name'] ?? '',
          'createdAt': stamp,
        });
      }
      return {'ok': true};
    });
  }

  Future<Map<String, dynamic>> checkout(Map<String, dynamic> d) async {
    final items = (d['items'] as List);
    if (items.isEmpty || items.length > 3) {
      fail('Choose up to 3 different products per checkout.');
    }
    if (items.map((i) => i['id']).toSet().length != items.length) {
      fail('Duplicate basket item.');
    }
    final address = text(d['address']);
    final recipientName = text(d['recipientName'], max: 500);
    final phone = text(d['phone'], max: 40);
    final note = text(d['note'] ?? '', max: 1000, optional: true);
    final pickupSlot = text(d['pickupSlot'] ?? '', max: 160, optional: true);
    return db.runTransaction((tx) async {
      final actor = (await tx.get(db.doc('users/$uid'))).data()!;
      final receipt = db.doc('checkoutRequests/${uid}_${d['requestId']}');
      final prior = await tx.get(receipt);
      if (prior.exists) return prior.data()!;
      final products = <DocumentSnapshot<Map<String, dynamic>>>[];
      final farms = <String, Map<String, dynamic>>{};
      for (final item in items) {
        products.add(await tx.get(db.doc('products/${item['id']}')));
      }
      for (final p in products) {
        if (!p.exists) fail('An item is no longer available.');
        final id = p.data()!['farmId'] as String;
        if (!farms.containsKey(id)) {
          farms[id] = (await tx.get(db.doc('farms/$id'))).data()!;
        }
      }
      final ids = <String>[];
      for (var i = 0; i < products.length; i++) {
        final snap = products[i];
        final p = snap.data()!;
        final f = farms[p['farmId']]!;
        if (pickupSlot.isNotEmpty &&
            !(f['pickupSlots'] as List? ?? []).contains(pickupSlot)) {
          fail(
            'A farm changed its pickup windows. Choose an available time or arrange pickup later.',
          );
        }
        final q = items[i]['quantity'];
        if (q is! int ||
            q <= 0 ||
            q > p['stock'] ||
            p['archived'] != false ||
            f['active'] != true) {
          fail('An item is no longer available. Refresh your basket.');
        }
        final ref = db.collection('orders').doc();
        ids.add(ref.id);
        tx.set(ref, {
          'customerId': uid,
          'customerName': actor['name'],
          'recipientName': recipientName,
          'phone': phone,
          'note': note,
          'paymentMethod': 'cashOnDelivery',
          'farmId': p['farmId'],
          'farmerId': f['owner'],
          'farmName': f['name'],
          'market': f['market'],
          'items': [
            {
              'productId': snap.id,
              'name': p['name'],
              'image': p['image'],
              'unit': p['unit'],
              'price': p['price'],
              'quantity': q,
            },
          ],
          'total': p['price'] * q,
          'address': address,
          'status': 'pending',
          'createdAt': stamp,
        });
        if (pickupSlot.isNotEmpty) {
          tx.set(db.doc('users/$uid/pickups/${ref.id}'), {
            'slot': pickupSlot,
            'updatedAt': stamp,
          });
        }
        tx.update(snap.reference, {
          'stock': p['stock'] - q,
          'lastOrderId': ref.id,
          'updatedAt': stamp,
        });
      }
      tx.set(receipt, {'orderIds': ids, 'createdAt': stamp, 'userId': uid});
      return {'orderIds': ids};
    });
  }

  Future<Map<String, dynamic>> report(int days) async {
    final actor = (await db.doc('users/$uid').get()).data()!;
    final admin = actor['role'] == 'admin';
    final now = DateTime.now().toUtc();
    final start = DateTime.utc(
      now.year,
      now.month,
      now.day,
    ).subtract(Duration(days: days - 1));
    Query<Map<String, dynamic>> query = db.collection('orders');
    if (!admin) query = query.where('farmerId', isEqualTo: uid);
    query = query
        .where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
        .orderBy('createdAt');
    final orders = <Map<String, dynamic>>[];
    DocumentSnapshot? cursor;
    do {
      final page =
          await (cursor == null ? query : query.startAfterDocument(cursor))
              .limit(500)
              .get();
      orders.addAll(page.docs.map((d) => d.data()));
      cursor = page.size == 500 ? page.docs.last : null;
    } while (cursor != null);
    Future<int> count(Query<Map<String, dynamic>> q) async =>
        (await q.count().get()).count ?? 0;
    Query<Map<String, dynamic>> products = db
        .collection('products')
        .where('archived', isEqualTo: false);
    if (!admin) {
      final farmerFarms =
          (await db.collection('farms').where('owner', isEqualTo: uid).get())
              .docs
              .map((d) => d.id)
              .toList();
      if (farmerFarms.isNotEmpty) {
        products = products.where(
          'farmId',
          whereIn: farmerFarms.take(10).toList(),
        );
      } else {
        products = products.where('farmId', isEqualTo: uid);
      }
    }
    final r = <String, dynamic>{
      'products': await count(products),
      'outOfStock': await count(products.where('stock', isEqualTo: 0)),
      'categories': await count(db.collection('categories')),
      'totalOrders': orders.length,
      'orderValue': 0,
      'completedValue': 0,
    };
    if (admin) {
      r['users'] = await count(db.collection('users'));
      r['customers'] = await count(
        db.collection('users').where('role', isEqualTo: 'customer'),
      );
      r['farmerCount'] = await count(
        db.collection('users').where('role', isEqualTo: 'farmer'),
      );
      r['activeFarmers'] = await count(
        db
            .collection('users')
            .where('role', isEqualTo: 'farmer')
            .where('active', isEqualTo: true),
      );
    }
    final statuses = {
      for (final s in [
        'pending',
        'confirmed',
        'ready',
        'completed',
        'cancelled',
      ])
        s: 0,
    };
    final trend = List<int>.filled(days == 36500 ? 0 : days, 0);
    final farmers = <String, Map<String, dynamic>>{},
        markets = <String, Map<String, dynamic>>{};
    for (final o in orders) {
      final total = o['total'] as int;
      r['orderValue'] += total;
      statuses[o['status']] = (statuses[o['status']] ?? 0) + 1;
      if (o['status'] == 'completed') r['completedValue'] += total;
      final day = (o['createdAt'] as Timestamp)
          .toDate()
          .toUtc()
          .difference(start)
          .inDays;
      if (day >= 0 && day < trend.length) trend[day] += total;
      final f = farmers.putIfAbsent(
        o['farmId'],
        () => {
          'id': o['farmId'],
          'name': o['farmName'],
          'orders': 0,
          'completed': 0,
          'value': 0,
        },
      );
      final m = markets.putIfAbsent(
        o['market'] ?? 'Unassigned market',
        () => {
          'name': o['market'] ?? 'Unassigned market',
          'orders': 0,
          'completed': 0,
          'value': 0,
        },
      );
      for (final group in [f, m]) {
        group['orders']++;
        group['value'] += total;
        if (o['status'] == 'completed') group['completed']++;
      }
    }
    final ranked = farmers.values.toList()
      ..sort((a, b) => (b['orders'] as int).compareTo(a['orders'] as int));
    return {
      ...r,
      'statuses': statuses,
      'trend': trend,
      'farmers': ranked.take(20).toList(),
      'markets': markets.values.toList(),
    };
  }
}

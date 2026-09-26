import 'notifications.dart';
import 'dart:async';
import 'dart:convert';

import 'package:image/image.dart' as imaging;

import 'spark_backend.dart';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import 'models.dart';
import 'store.dart';

String serviceError(Object e) {
  debugPrint('HarvestHub service failure: $e');
  if (e is StateError) return e.message;
  if (e is FirebaseException) {
    return switch (e.code) {
      'permission-denied' =>
        'You do not have permission to perform this action.',
      'invalid-credential' ||
      'wrong-password' ||
      'user-not-found' => 'Email or password is incorrect.',
      'email-already-in-use' =>
        'An account already uses this email. Please sign in.',
      'weak-password' => 'Use a stronger password with at least 8 characters.',
      'too-many-requests' ||
      'resource-exhausted' => 'Too many requests. Please try again later.',
      'unavailable' ||
      'network-request-failed' ||
      'deadline-exceeded' => 'Connection unavailable. Please retry.',
      'user-disabled' =>
        'This account is suspended. Contact the administrator.',
      _ => 'The service could not complete this request. Please retry.',
    };
  }
  return 'The record could not be processed. Refresh and try again.';
}

/// One session-owned data adapter. Widgets never construct Firestore queries.
class FirebaseStore extends HarvestStore {
  FirebaseStore({FirebaseAuth? auth, FirebaseFirestore? firestore})
    : _auth = auth ?? FirebaseAuth.instance,
      _db = firestore ?? FirebaseFirestore.instance {
    categories.clear();
    loading = true;
    _authSubscription = _auth.authStateChanges().listen(
      _session,
      onError: _error,
    );
  }
  final FirebaseAuth _auth;
  final FirebaseFirestore _db;
  StreamSubscription<User?>? _authSubscription;
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>?
  _profileSubscription;
  final List<StreamSubscription> _subscriptions = [];
  Account? _account;
  bool _disposed = false;
  int _generation = 0;
  int _limit = 100;
  final Set<String> _more = {};
  String? _checkoutKey;
  bool _authenticating = false;
  @override
  bool get live => true;
  @override
  bool get authenticated => _account?.active == true;
  @override
  Account get account => _account!;
  @override
  bool get hasMore => _more.isNotEmpty;
  @override
  void chooseRole(UserRole value) {
    /* Role is exclusively profile-derived. */
  }
  @override
  Farm farm(String id) =>
      farms.where((f) => f.id == id).firstOrNull ??
      Farm(
        id: id,
        name: 'Farm details unavailable',
        active: false,
        owner: '',
        location: '',
        market: '',
        description: '',
        image: '',
      );
  @override
  Farm get ownFarm =>
      farms.where((f) => f.owner == _auth.currentUser?.uid).firstOrNull ??
      farm(_auth.currentUser?.uid ?? '');
  @override
  void notifyListeners() {
    if (!_disposed) super.notifyListeners();
  }

  void _error(Object e) {
    error = serviceError(e);
    loading = false;
    notifyListeners();
  }

  void _clear() {
    accounts.clear();
    farms.clear();
    products.clear();
    orders.clear();
    categories.clear();
    categoryCounts.clear();
    basket.clear();
    saved.clear();
    followed.clear();
    pickupSlots.clear();
    recentSearches.clear();
    feedback.clear();
    report = null;
    _more.clear();
    _checkoutKey = null;
  }

  Future<void> _cancelData() async {
    for (final s in _subscriptions) {
      await s.cancel();
    }
    _subscriptions.clear();
  }

  Future<void> _session(User? user) async {
    if (_authenticating) return;
    final generation = ++_generation;
    await _profileSubscription?.cancel();
    await _cancelData();
    if (generation != _generation || _disposed) return;
    _account = null;
    _clear();
    error = null;
    loading = user != null;
    notifyListeners();
    if (user == null) return;
    _profileSubscription = _db.doc('users/${user.uid}').snapshots().listen((
      doc,
    ) async {
      if (generation != _generation) return;
      try {
        if (!doc.exists) {
          _account = null;
          await _cancelData();
          _clear();
          error = 'Your account profile is missing. Contact the administrator.';
          loading = false;
          notifyListeners();
          return;
        }
        final a = readAccount(doc);
        if (!a.active) {
          await signOut();
          error = 'This account is suspended. Contact the administrator.';
          notifyListeners();
          return;
        }
        final reload = _account == null || role != a.role;
        _account = a;
        role = a.role;
        if (reload) {
          await refresh();
          unawaited(HarvestNotifications.restore().catchError((Object _) {}));
        } else {
          notifyListeners();
        }
      } catch (e) {
        _error(e);
      }
    }, onError: _error);
  }

  @override
  Future<void> refresh() async {
    if (!authenticated) return;
    await _cancelData();
    loading = true;
    error = null;
    _more.clear();
    notifyListeners();
    final generation = _generation;
    final pending = <String>{
      'users',
      'farms',
      'products',
      'categories',
      'orders',
    };
    void watch(
      String name,
      Query<Map<String, dynamic>> query,
      void Function(List<QueryDocumentSnapshot<Map<String, dynamic>>>) apply,
    ) {
      _subscriptions.add(
        query.limit(_limit).snapshots().listen((s) {
          if (generation != _generation || !authenticated) return;
          try {
            apply(s.docs);
            if (s.size == _limit) {
              _more.add(name);
            } else {
              _more.remove(name);
            }
            pending.remove(name);
            loading = pending.isNotEmpty;
            notifyListeners();
          } catch (e) {
            _error(e);
          }
        }, onError: _error),
      );
    }

    final uid = _auth.currentUser!.uid;
    Query<Map<String, dynamic>> userQuery = _db.collection('users');
    if (role != UserRole.admin) {
      userQuery = userQuery.where(FieldPath.documentId, isEqualTo: uid);
    }
    watch('users', userQuery.orderBy(FieldPath.documentId), (d) {
      accounts
        ..clear()
        ..addAll(d.map(readAccount));
    });
    watch('farms', _db.collection('farms').orderBy(FieldPath.documentId), (d) {
      farms
        ..clear()
        ..addAll(d.map(readFarm));
    });
    Query<Map<String, dynamic>> pq = _db
        .collection('products')
        .where('archived', isEqualTo: false);
    watch('products', pq.orderBy(FieldPath.documentId), (d) {
      products
        ..clear()
        ..addAll(d.map(readProduct));
    });
    watch(
      'categories',
      _db.collection('categories').orderBy(FieldPath.documentId),
      (d) {
        categories
          ..clear()
          ..addAll(d.map((x) => x.data()['name'] as String));
        categoryCounts
          ..clear()
          ..addEntries(
            d.map(
              (x) => MapEntry(
                x.data()['name'] as String,
                (x.data()['productCount'] as num?)?.toInt() ?? 0,
              ),
            ),
          );
      },
    );
    Query<Map<String, dynamic>> oq = _db.collection('orders');
    if (role == UserRole.customer) oq = oq.where('customerId', isEqualTo: uid);
    if (role == UserRole.farmer) oq = oq.where('farmerId', isEqualTo: uid);
    watch('orders', oq.orderBy('createdAt', descending: true), (d) {
      final previous = {for (final o in orders) o.id: o};
      orders
        ..clear()
        ..addAll(
          d.map((x) {
            final o = readOrder(x);
            final old = previous[o.id];
            if (old != null) {
              old.status = o.status;
              return old;
            }
            return o;
          }),
        );
    });
    if (role == UserRole.customer) {
      _subscriptions.add(
        _db.doc('users/$uid/private/preferences').snapshots().listen((doc) {
          if (generation != _generation || !authenticated) return;
          if (doc.exists) {
            final d = doc.data();
            if (d != null) {
              final s = (d['saved'] as List?)?.cast<String>() ?? [];
              final f = (d['followed'] as List?)?.cast<String>() ?? [];
              saved
                ..clear()
                ..addAll(s);
              followed
                ..clear()
                ..addAll(f);
              notifyListeners();
            }
          }
        }, onError: _error),
      );
      _subscriptions.add(
        _db.collection('users/$uid/pickups').snapshots().listen((snap) {
          if (generation != _generation || !authenticated) return;
          pickupSlots.clear();
          for (final doc in snap.docs) {
            final slot = doc.data()['slot'] as String?;
            if (slot != null && slot.isNotEmpty) {
              pickupSlots[doc.id] = slot;
            }
          }
          notifyListeners();
        }, onError: _error),
      );
    }
    if (role == UserRole.admin) {
      pending.add('feedback');
      watch(
        'feedback',
        _db.collection('feedback').orderBy('createdAt', descending: true),
        (d) {
          feedback
            ..clear()
            ..addAll(
              d.map((x) {
                final data = x.data();
                return FeedbackItem(
                  id: x.id,
                  email: data['email'] as String? ?? 'Anonymous',
                  message: data['message'] as String? ?? '',
                  date: _date(data['createdAt']) ?? DateTime.now(),
                  read: data['read'] == true,
                );
              }),
            );
        },
      );
    }
    if (role != UserRole.customer) unawaited(loadReport(36500));
  }

  @override
  Future<void> loadMore() async {
    if (loading || !hasMore) return;
    _limit += 100;
    await refresh();
  }

  @override
  Future<void> loadReport(int days) async {
    final generation = _generation;
    final requestedRole = role;
    try {
      final data = await _call('platformReport', {'days': days});
      if (authenticated && generation == _generation && role == requestedRole) {
        report = data;
        notifyListeners();
      }
    } catch (e) {
      _error(e);
    }
  }

  @override
  Future<Map<String, dynamic>> fetchReport(int days) =>
      _call('platformReport', {'days': days});
  Future<Map<String, dynamic>> _call(
    String name,
    Map<String, dynamic> data,
  ) async {
    return SparkBackend(_db, _auth).call(name, data);
  }

  @override
  Future<String?> signIn(String email, String password) async {
    _authenticating = true;
    try {
      final result = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      final doc = await _db
          .doc('users/${result.user!.uid}')
          .get(const GetOptions(source: Source.server));
      final account = doc.exists ? readAccount(doc) : null;
      if (!doc.exists || account == null || !account.active) {
        await _auth.signOut();
        return 'This account is unavailable or has been suspended.';
      }
      return null;
    } catch (e) {
      await _auth.signOut();
      return serviceError(e);
    } finally {
      _authenticating = false;
      await _session(_auth.currentUser);
    }
  }

  @override
  Future<String?> register(
    String email,
    String password,
    String name,
    String phone,
    String address,
    UserRole selected,
  ) async {
    if (selected == UserRole.admin) {
      return 'Administrator accounts are provisioned privately.';
    }
    _authenticating = true;
    try {
      await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      await _call('registerProfile', {
        'name': name.trim(),
        'phone': phone.trim(),
        'address': address.trim(),
        'role': selected.name,
      });
      return null;
    } catch (e) {
      return serviceError(e);
    } finally {
      _authenticating = false;
      await _session(_auth.currentUser);
    }
  }

  @override
  Future<void> signOut() async {
    try {
      await HarvestNotifications.unregister();
    } catch (_) {
      /* Sign-out still proceeds offline. */
    }
    ++_generation;
    _account = null;
    _clear();
    loading = false;
    notifyListeners();
    await _profileSubscription?.cancel();
    await _cancelData();
    await _auth.signOut();
  }

  Future<String?> _operation(Future<void> Function() action) async {
    if (busy) return 'An update is already in progress.';
    busy = true;
    notifyListeners();
    try {
      await action();
      return null;
    } catch (e) {
      return serviceError(e);
    } finally {
      busy = false;
      notifyListeners();
    }
  }

  Future<String?> _mutate(String action, Map<String, dynamic> value) =>
      _operation(() async {
        await _call('mutate', {'action': action, 'value': value});
        if (role != UserRole.customer) unawaited(loadReport(36500));
      });
  @override
  Future<String?> saveCategory(String value, {String? previous}) =>
      _mutate('saveCategory', {'name': value.trim(), 'previous': ?previous});
  @override
  Future<String?> deleteCategory(String value) =>
      _mutate('deleteCategory', {'name': value});
  @override
  Future<String?> toggleAccount(Account value) =>
      _mutate('toggleAccount', {'id': value.id, 'active': !value.active});
  @override
  Future<String?> saveAccount(Account value) => _mutate('saveAccount', {
    'id': value.id,
    'name': value.name,
    'phone': value.phone,
    'address': value.address,
    'avatar': value.avatar,
  });
  @override
  Future<String?> saveFarm(Farm value) => _mutate('saveFarm', {
    'id': value.id,
    'name': value.name,
    'location': value.location,
    'market': value.market,
    'description': value.description,
    'pickupSlots': value.pickupSlots,
    'lat': value.latitude,
    'lng': value.longitude,
  });
  @override
  Future<String?> deleteProduct(Product value) =>
      _mutate('deleteProduct', {'id': value.id});
  @override
  Future<String?> updateStatus(HarvestOrder order, OrderStatus status) =>
      _mutate('updateStatus', {'id': order.id, 'status': status.name});
  @override
  Future<String?> saveProduct(Product value) => _operation(() async {
    String url = value.image;
    if (value.photo != null) {
      final job = await compute(_compressPhoto, value.photo!);
      if (job.error != null) throw StateError(job.error!);
      url = job.dataUrl!;
    }
    try {
      await _call('mutate', {
        'action': 'saveProduct',
        'value': {
          'id': value.id,
          'name': value.name,
          'category': value.category,
          'farmId': value.farmId,
          'price': value.price,
          'stock': value.stock,
          'image': url,
          'unit': value.unit,
          'description': value.description,
        },
      });
    } catch (e) {
      // Preserve the form on a failed transaction so it can be retried.
      rethrow;
    }
    if (role != UserRole.customer) unawaited(loadReport(36500));
  });
  @override
  String? setQuantity(String id, int quantity) {
    final p = product(id);
    if (role != UserRole.customer || !authenticated) {
      return 'Sign in as a customer.';
    }
    if (quantity <= 0) {
      basket.remove(id);
      _checkoutKey = null;
      notifyListeners();
      return null;
    }
    if (p == null || quantity > p.stock) return 'This quantity is unavailable.';
    basket[id] = quantity;
    _checkoutKey = null;
    notifyListeners();
    return null;
  }

  @override
  void toggleSaved(String id) {
    if (role != UserRole.customer || !authenticated) return;
    if (saved.contains(id)) {
      saved.remove(id);
    } else {
      saved.add(id);
    }
    notifyListeners();
    final uid = _auth.currentUser?.uid;
    if (uid != null) {
      unawaited(
        _db
            .doc('users/$uid/private/preferences')
            .set({
              'saved': saved.toList(),
              'followed': followed.toList(),
            }, SetOptions(merge: true))
            .catchError((Object e) {
              _error(e);
            }),
      );
    }
  }

  @override
  void toggleFollowed(String farmId) {
    if (role != UserRole.customer || !authenticated) return;
    if (followed.contains(farmId)) {
      followed.remove(farmId);
    } else {
      followed.add(farmId);
    }
    notifyListeners();
    final uid = _auth.currentUser?.uid;
    if (uid != null) {
      unawaited(
        _db
            .doc('users/$uid/private/preferences')
            .set({
              'saved': saved.toList(),
              'followed': followed.toList(),
            }, SetOptions(merge: true))
            .catchError((Object e) {
              _error(e);
            }),
      );
    }
  }

  @override
  Future<String?> updatePickupSlot(String orderId, String? slot) async {
    if (role != UserRole.customer || !authenticated) {
      return 'Only customers manage pickup bookings.';
    }
    final uid = _auth.currentUser?.uid;
    if (uid == null) return 'Please sign in.';
    try {
      await _db.doc('users/$uid/pickups/$orderId').set({
        'slot': slot == null || slot.trim().isEmpty ? null : slot.trim(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      if (slot == null || slot.trim().isEmpty) {
        pickupSlots.remove(orderId);
      } else {
        pickupSlots[orderId] = slot.trim();
      }
      notifyListeners();
      return null;
    } catch (e) {
      return serviceError(e);
    }
  }

  @override
  Future<List<HarvestOrder>> checkout(
    String address, {
    String? pickupSlot,
  }) async {
    if (busy) throw StateError('An order is already being submitted.');
    busy = true;
    notifyListeners();
    try {
      _checkoutKey ??= _db.collection('checkoutRequests').doc().id;
      final result = await _call('checkout', {
        'requestId': _checkoutKey,
        'address': address,
        'pickupSlot': pickupSlot?.trim() ?? '',
        'items': basket.entries
            .map((x) => {'id': x.key, 'quantity': x.value})
            .toList(),
      });
      final orderIds = (result['orderIds'] as List).cast<String>();
      final docs = await Future.wait(
        orderIds.map((id) => _db.doc('orders/$id').get()),
      );
      if (pickupSlot != null && pickupSlot.trim().isNotEmpty) {
        for (final id in orderIds) {
          pickupSlots[id] = pickupSlot.trim();
        }
        notifyListeners();
      }
      basket.clear();
      _checkoutKey = null;
      return docs.map(readOrder).toList();
    } catch (e) {
      throw StateError(serviceError(e));
    } finally {
      busy = false;
      notifyListeners();
    }
  }

  @override
  Future<String?> resetPassword(String email) =>
      _operation(() => _auth.sendPasswordResetEmail(email: email.trim()));
  @override
  Future<String?> changePassword(String old, String password) =>
      _operation(() async {
        final u = _auth.currentUser!;
        await u.reauthenticateWithCredential(
          EmailAuthProvider.credential(email: u.email!, password: old),
        );
        await u.updatePassword(password);
      });
  @override
  Future<String?> sendFeedback(String email, String message) =>
      _operation(() async {
        await _call('submitFeedback', {'email': email, 'message': message});
      });
  @override
  void dispose() {
    _disposed = true;
    ++_generation;
    _authSubscription?.cancel();
    _profileSubscription?.cancel();
    for (final s in _subscriptions) {
      s.cancel();
    }
    super.dispose();
  }
}

/// Runs in a worker isolate: decode/copyResize/encodeJpg are CPU-heavy and
/// must never touch the UI thread.
({String? dataUrl, String? error}) _compressPhoto(Uint8List raw) {
  final decoded = imaging.decodeImage(raw);
  if (decoded == null) {
    return (dataUrl: null, error: 'Choose a JPEG or PNG image.');
  }
  final resized = imaging.copyResize(
    decoded,
    width: decoded.width > 700 ? 700 : decoded.width,
  );
  var bytes = imaging.encodeJpg(resized, quality: 70);
  if (bytes.length > 100000) {
    bytes = imaging.encodeJpg(
      imaging.copyResize(resized, width: 400),
      quality: 50,
    );
  }
  if (bytes.length > 100000) {
    return (dataUrl: null, error: 'Choose a smaller image.');
  }
  return (
    dataUrl: 'data:image/jpeg;base64,${base64Encode(bytes)}',
    error: null,
  );
}

String _s(Map<String, dynamic> d, String k, [String fallback = '']) =>
    d[k] is String ? d[k] as String : fallback;
int _n(Map<String, dynamic> d, String k) {
  final v = d[k];
  if (v is! int || v < 0) throw FormatException('Invalid $k');
  return v;
}

DateTime? _date(dynamic v) => v is Timestamp ? v.toDate() : null;
Account readAccount(DocumentSnapshot<Map<String, dynamic>> doc) {
  final d = doc.data()!;
  final r = UserRole.values.where((r) => r.name == d['role']).firstOrNull;
  if (r == null) throw const FormatException('Invalid account role');
  return Account(
    id: doc.id,
    name: _s(d, 'name', 'Unnamed account').isEmpty
        ? 'Unnamed account'
        : _s(d, 'name', 'Unnamed account'),
    email: _s(d, 'email'),
    role: r,
    phone: _s(d, 'phone'),
    address: _s(d, 'address'),
    avatar: _s(d, 'avatar'),
    active: d['active'] == true,
    createdAt: _date(d['createdAt']),
  );
}

Farm readFarm(DocumentSnapshot<Map<String, dynamic>> doc) {
  final d = doc.data()!;
  return Farm(
    id: doc.id,
    name: _s(d, 'name', 'Unnamed farm'),
    owner: _s(d, 'owner'),
    location: _s(d, 'location'),
    market: _s(d, 'market'),
    description: _s(d, 'description'),
    image: _s(d, 'image'),
    pickupSlots: (d['pickupSlots'] as List? ?? []).whereType<String>().toList(),
    latitude: (d['lat'] as num?)?.toDouble(),
    longitude: (d['lng'] as num?)?.toDouble(),
    active: d['active'] == true,
  );
}

Product readProduct(DocumentSnapshot<Map<String, dynamic>> doc) {
  final d = doc.data()!;
  return Product(
    id: doc.id,
    name: _s(d, 'name', 'Unnamed product'),
    category: _s(d, 'category'),
    farmId: _s(d, 'farmId'),
    price: _n(d, 'price'),
    stock: _n(d, 'stock'),
    image: _s(d, 'image'),
    unit: _s(d, 'unit', 'kg'),
    description: _s(d, 'description'),
  );
}

HarvestOrder readOrder(DocumentSnapshot<Map<String, dynamic>> doc) {
  final d = doc.data()!;
  final status = OrderStatus.values
      .where((s) => s.name == d['status'])
      .firstOrNull;
  if (status == null || d['items'] is! List || _date(d['createdAt']) == null) {
    throw const FormatException('Invalid order');
  }
  return HarvestOrder(
    id: doc.id,
    customerId: _s(d, 'customerId'),
    customerName: _s(d, 'customerName'),
    farmId: _s(d, 'farmId'),
    farmName: _s(d, 'farmName'),
    date: _date(d['createdAt'])!,
    address: _s(d, 'address'),
    status: status,
    items: (d['items'] as List).map((raw) {
      final x = Map<String, dynamic>.from(raw as Map);
      return OrderLine(
        productId: _s(x, 'productId'),
        name: _s(x, 'name'),
        image: _s(x, 'image'),
        unit: _s(x, 'unit'),
        price: _n(x, 'price'),
        quantity: _n(x, 'quantity'),
      );
    }).toList(),
  );
}

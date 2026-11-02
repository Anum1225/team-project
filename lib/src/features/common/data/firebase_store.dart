import '../notifications/notifications.dart';
import '../../authentication/email_security.dart';
import '../shared/forms/phone_validation.dart';

import 'dart:async';
import 'dart:convert';

import 'package:image/image.dart' as imaging;

import 'spark_backend.dart';
import 'trusted_backend.dart';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'models.dart';
import 'store.dart';

String serviceError(Object e) {
  debugPrint('HarvestHub service failure: $e');
  if (e is StateError) return e.message;
  if (e is FormatException) return e.message;
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
    _authSubscription = _auth.idTokenChanges().listen(
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
  int _reportRequest = 0;
  int _limit = 100;
  final Set<String> _more = {};
  bool _recoveringCatalog = false;
  String? _checkoutKey;
  bool _authenticating = false;
  Future<void>? _signOutOperation;
  bool _emailVerificationPending = false;
  final Map<String, bool> _pendingFollows = {};
  Future<void> _basketWrite = Future<void>.value();
  String _basketKey(String uid) => 'harvesthub_basket_$uid';

  Future<void> _restoreBasket(String uid) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_basketKey(uid));
    if (raw == null) return;
    try {
      final saved = jsonDecode(raw) as Map<String, dynamic>;
      basket
        ..clear()
        ..addEntries(
          saved.entries
              .where((e) => e.value is int && e.value > 0)
              .map((e) => MapEntry(e.key, e.value as int)),
        );
      notifyListeners();
    } catch (_) {
      // An invalid local cart cannot prevent the account from opening.
    }
  }

  void _saveBasket() {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;
    final value = jsonEncode(basket);
    _basketWrite = _basketWrite.then((_) async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_basketKey(uid), value);
    });
  }

  @override
  bool get emailVerificationPending => _emailVerificationPending;
  @override
  bool get live => true;
  @override
  bool get authenticated => _account?.active == true;
  @override
  // Screens can rebuild for a frame while the profile is (re)loading; return a
  // placeholder instead of throwing "Null check operator used on a null value".
  Account get account =>
      _account ??
      Account(
        id: _auth.currentUser?.uid ?? '',
        name: '',
        email: _auth.currentUser?.email ?? '',
        role: role,
        active: false,
      );
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
    _pendingFollows.clear();
    pickupSlots.clear();
    recentSearches.clear();
    feedback.clear();
    report = null;
    reportLoading = false;
    ++_reportRequest;
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
    if (_signOutOperation != null && user != null) return;
    final generation = ++_generation;
    await _profileSubscription?.cancel();
    await _cancelData();
    if (generation != _generation || _disposed) return;
    _account = null;
    _emailVerificationPending = false;
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
        // Enrollment changes the profile before its custom token reaches the
        // phone. Wait for that exchange so a temporary gate cannot send a new
        // code and replace the one currently being verified.
        await EmailSecurityApi.waitForVerification();
        if (generation != _generation || _disposed) return;
        final proof = await hasEmailSecurityProof(user, doc.data()!);
        if (generation != _generation || _disposed) return;
        if (!proof) {
          _account = null;
          await _cancelData();
          _clear();
          _emailVerificationPending = true;
          loading = false;
          notifyListeners();
          return;
        }
        _emailVerificationPending = false;
        final reload = _account == null || role != a.role;
        _account = a;
        role = a.role;
        if (reload) {
          if (a.role == UserRole.customer) await _restoreBasket(user.uid);
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
    _recoveringCatalog = false;
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
      void Function(List<QueryDocumentSnapshot<Map<String, dynamic>>>) apply, {
      void Function(Object)? onFailure,
    }) {
      _subscriptions.add(
        query
            .limit(_limit)
            .snapshots()
            .listen(
              (s) {
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
              },
              onError: (Object e) {
                if (onFailure != null) {
                  onFailure(e);
                } else {
                  _error(e);
                }
              },
            ),
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
        ..addAll(_parse(d, readAccount));
    });
    watch('farms', _db.collection('farms').orderBy(FieldPath.documentId), (d) {
      farms
        ..clear()
        ..addAll(_parse(d, readFarm));
    });
    Query<Map<String, dynamic>> pq = _db.collection('products');
    if (role != UserRole.admin) {
      pq = pq.where('archived', isEqualTo: false);
    }
    watch(
      'products',
      pq.orderBy(FieldPath.documentId),
      (d) {
        products
          ..clear()
          ..addAll(_parse(d, readProduct));
        if (products.isEmpty) unawaited(_restorePublicCatalog(generation));
      },
      onFailure: (e) {
        debugPrint('HarvestHub product stream failure: $e');
        pending.remove('products');
        loading = pending.isNotEmpty;
        notifyListeners();
        unawaited(_restorePublicCatalog(generation));
      },
    );
    watch(
      'categories',
      _db.collection('categories').orderBy(FieldPath.documentId),
      (d) {
        // Skip category docs without a name instead of failing the whole load.
        final named = d.where((x) => x.data()['name'] is String);
        categories
          ..clear()
          ..addAll(named.map((x) => x.data()['name'] as String));
        categoryCounts
          ..clear()
          ..addEntries(
            named.map(
              (x) => MapEntry(
                x.data()['name'] as String,
                (x.data()['productCount'] as num?)?.toInt() ?? 0,
              ),
            ),
          );
        if (named.isEmpty) _seedDefaultCategories();
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
          _parse(d, readOrder).map((o) {
            final old = previous[o.id];
            if (old != null) {
              old.status = o.status;
              old.approvalStatus = o.approvalStatus;
              return old;
            }
            return o;
          }),
        );
    });
    {
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
              for (final entry in _pendingFollows.entries) {
                entry.value
                    ? followed.add(entry.key)
                    : followed.remove(entry.key);
              }
              notifyListeners();
            }
          }
        }, onError: _error),
      );
    }
    if (role == UserRole.customer) {
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
    // The public endpoint has a smaller paged response and can populate the
    // published catalog while a signed-in Firestore stream is still starting.
    unawaited(_restorePublicCatalog(generation));
    if (role != UserRole.customer) unawaited(loadReport(36500));
  }

  Future<void> _restorePublicCatalog(int generation) async {
    if (_recoveringCatalog || products.isNotEmpty) return;
    _recoveringCatalog = true;
    try {
      final recovered = <Product>[];
      final recoveredFarms = <Farm>[];
      Map<String, dynamic> cursors = {};
      for (var page = 0; page < 100; page++) {
        final data = await TrustedBackend.publicCatalog(cursors);
        for (final value in data['products'] as List? ?? const []) {
          final row = Map<String, dynamic>.from(value as Map);
          recovered.add(
            Product(
              id: row['id'] as String? ?? '',
              name: row['name'] as String? ?? '',
              category: row['category'] as String? ?? '',
              farmId: row['farmId'] as String? ?? '',
              price: (row['price'] as num? ?? 0).toInt(),
              stock: (row['stock'] as num? ?? 0).toInt(),
              image: row['image'] as String? ?? '',
              unit: row['unit'] as String? ?? 'kg',
              description: row['description'] as String? ?? '',
            ),
          );
        }
        for (final value in data['farms'] as List? ?? const []) {
          final row = Map<String, dynamic>.from(value as Map);
          recoveredFarms.add(
            Farm(
              id: row['id'] as String? ?? '',
              name: row['name'] as String? ?? '',
              owner: '',
              location: row['location'] as String? ?? '',
              market: row['market'] as String? ?? '',
              description: row['description'] as String? ?? '',
              image: row['image'] as String? ?? '',
            ),
          );
        }
        cursors = Map<String, dynamic>.from(data['cursors'] as Map? ?? {});
        if (cursors['products'] == null) break;
      }
      if (generation != _generation || _disposed || products.isNotEmpty) return;
      if (farms.isEmpty) farms.addAll(recoveredFarms);
      products.addAll(recovered);
      notifyListeners();
    } catch (e) {
      debugPrint('HarvestHub catalog recovery failed: $e');
      if (generation == _generation && !_disposed && products.isEmpty) {
        error = 'Could not load products. Check your connection and retry.';
        notifyListeners();
      }
    } finally {
      _recoveringCatalog = false;
    }
  }

  @override
  Future<void> loadMore() async {
    if (loading || !hasMore) return;
    _limit += 100;
    await refresh();
  }

  @override
  Future<void> loadReport(int days) async {
    final request = ++_reportRequest;
    final generation = _generation;
    final requestedRole = role;
    reportLoading = true;
    notifyListeners();
    try {
      final data = await _call('platformReport', {'days': days});
      if (!_disposed &&
          request == _reportRequest &&
          authenticated &&
          generation == _generation &&
          role == requestedRole) {
        report = data;
        notifyListeners();
      }
    } catch (e) {
      if (!_disposed &&
          request == _reportRequest &&
          generation == _generation) {
        _error(e);
      }
    } finally {
      if (!_disposed &&
          request == _reportRequest &&
          generation == _generation) {
        reportLoading = false;
        notifyListeners();
      }
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
    await _signOutOperation;
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
        return account?.approvalStatus == 'pending'
            ? 'Your account is awaiting administrator approval.'
            : 'This account is unavailable or has been suspended.';
      }
      if (TrustedBackend.enabled && result.user?.email != account.email) {
        await TrustedBackend.call('syncEmail');
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
    await _signOutOperation;
    if (selected == UserRole.admin) {
      return 'Administrator accounts are provisioned privately.';
    }
    _authenticating = true;
    try {
      final normalizedPhone = normalizePhoneNumber(phone);
      var createdHere = false;
      try {
        await _auth.createUserWithEmailAndPassword(
          email: email.trim(),
          password: password,
        );
        createdHere = true;
      } on FirebaseAuthException catch (e) {
        if (e.code != 'email-already-in-use') rethrow;
        // Recover an Auth account left without a Firestore profile by an
        // earlier failed registration, using the same email and password.
        final existing = await _auth.signInWithEmailAndPassword(
          email: email.trim(),
          password: password,
        );
        final profile = await _db.doc('users/${existing.user!.uid}').get();
        if (profile.exists) {
          await _auth.signOut();
          return 'An account already uses this email. Please sign in.';
        }
      }
      try {
        await _call('registerProfile', {
          'name': name.trim(),
          'phone': normalizedPhone,
          'address': address.trim(),
          'role': selected.name,
        });
      } catch (_) {
        // A failed profile write must not leave an Auth account that cannot
        // register again with the same email address.
        if (createdHere) {
          try {
            await _auth.currentUser?.delete();
          } catch (_) {
            await _auth.signOut();
          }
        }
        rethrow;
      }
      await _auth.signOut();
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
  Future<void> signOut() => _signOutOperation ??= _finishSignOut().whenComplete(
    () => _signOutOperation = null,
  );

  Future<void> _finishSignOut() async {
    ++_generation;
    _account = null;
    _emailVerificationPending = false;
    _clear();
    loading = false;
    error = null;
    notifyListeners();
    try {
      await HarvestNotifications.unregister().timeout(
        const Duration(seconds: 3),
      );
    } catch (_) {
      /* Sign-out still proceeds offline. */
    }
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
        _syncNotifications();
        if (role != UserRole.customer) unawaited(loadReport(36500));
      });

  bool _seededCategories = false;

  /// Temporary dummy categories; created once by an admin when none exist.
  void _seedDefaultCategories() {
    if (_seededCategories || role != UserRole.admin) return;
    _seededCategories = true;
    for (final name in const [
      'Grains',
      'Dairy',
      'Nuts',
      'Vegetables',
      'Fruits',
      'Pulses',
    ]) {
      saveCategory(name);
    }
  }

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
  Future<String?> decideApproval(String type, String id, bool approve) =>
      _mutate('decideApproval', {'type': type, 'id': id, 'approve': approve});
  @override
  Future<String?> saveAccount(Account value) async {
    try {
      return await _mutate('saveAccount', {
        'id': value.id,
        'name': value.name,
        'phone': normalizePhoneNumber(value.phone),
        'address': value.address,
        'avatar': value.avatar,
      });
    } on FormatException catch (error) {
      return error.message;
    }
  }

  @override
  Future<String?> saveFarm(Farm value) => _operation(() async {
    var image = value.image;
    if (value.photo != null) {
      final result = await compute(_compressPhoto, value.photo!);
      if (result.error != null) throw StateError(result.error!);
      image = result.dataUrl!;
    }
    await _call('mutate', {
      'action': 'saveFarm',
      'value': {
        'id': value.id,
        'name': value.name,
        'location': value.location,
        'market': value.market,
        'description': value.description,
        'image': image,
        'pickupSlots': value.pickupSlots,
        'lat': value.latitude,
        'lng': value.longitude,
      },
    });
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
      _syncNotifications();
    } catch (e) {
      // Preserve the form on a failed transaction so it can be retried.
      rethrow;
    }
    if (role != UserRole.customer) unawaited(loadReport(36500));
  });

  void _syncNotifications() {
    if (TrustedBackend.enabled) {
      unawaited(
        Future<void>.delayed(const Duration(seconds: 2), () async {
          try {
            await TrustedBackend.call('syncNotifications');
          } catch (_) {
            /* The scheduled sender retries. */
          }
        }),
      );
    }
  }

  @override
  String? setQuantity(String id, int quantity) {
    final p = product(id);
    if (role != UserRole.customer || !authenticated) {
      return 'Sign in as a customer.';
    }
    if (quantity <= 0) {
      basket.remove(id);
      _checkoutKey = null;
      _saveBasket();
      notifyListeners();
      return null;
    }
    if (p == null || quantity > p.stock) return 'This quantity is unavailable.';
    basket[id] = quantity;
    _checkoutKey = null;
    _saveBasket();
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
              'saved': saved.contains(id)
                  ? FieldValue.arrayUnion([id])
                  : FieldValue.arrayRemove([id]),
            }, SetOptions(merge: true))
            .catchError((Object e) {
              _error(e);
            }),
      );
    }
  }

  @override
  Future<String?> toggleFollowed(String farmId) async {
    if (!authenticated) return 'Sign in to follow a farm.';
    if (_pendingFollows.containsKey(farmId)) {
      return 'Please wait for this follow update.';
    }
    final uid = _auth.currentUser?.uid;
    if (uid == null) return 'Sign in to follow a farm.';
    final wasFollowed = followed.contains(farmId);
    final generation = _generation;
    _pendingFollows[farmId] = !wasFollowed;
    wasFollowed ? followed.remove(farmId) : followed.add(farmId);
    notifyListeners();
    try {
      await _db.doc('users/$uid/private/preferences').set({
        'followed': wasFollowed
            ? FieldValue.arrayRemove([farmId])
            : FieldValue.arrayUnion([farmId]),
      }, SetOptions(merge: true));
      return null;
    } catch (e) {
      if (generation == _generation) {
        wasFollowed ? followed.add(farmId) : followed.remove(farmId);
      }
      return serviceError(e);
    } finally {
      if (generation == _generation) {
        _pendingFollows.remove(farmId);
        notifyListeners();
      }
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
      _syncNotifications();
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
    String? recipientName,
    String? phone,
    String note = '',
  }) async {
    if (busy) throw StateError('An order is already being submitted.');
    final contactPhone = normalizePhoneNumber(phone ?? account.phone);
    busy = true;
    notifyListeners();
    try {
      _checkoutKey ??= _db.collection('checkoutRequests').doc().id;
      final result = await _call('checkout', {
        'requestId': _checkoutKey,
        'address': address,
        'recipientName': recipientName?.trim() ?? account.name,
        'phone': contactPhone,
        'note': note.trim(),
        'pickupSlot': pickupSlot?.trim() ?? '',
        'items': basket.entries
            .map((x) => {'id': x.key, 'quantity': x.value})
            .toList(),
      });
      final orderIds = (result['orderIds'] as List).cast<String>();
      _syncNotifications();
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
      _saveBasket();
      return docs.map(readOrder).toList();
    } catch (e) {
      throw StateError(serviceError(e));
    } finally {
      busy = false;
      notifyListeners();
    }
  }

  @override
  Future<String?> resetPassword(String email) => _operation(() async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
    } on FirebaseAuthException catch (e) {
      if (e.code != 'user-not-found') rethrow;
    }
  });
  @override
  Future<String?> changePassword(String old, String password) async {
    _authenticating = true;
    try {
      return await _operation(
        () => EmailSecurityApi.changePassword(_auth, old, password),
      );
    } finally {
      _authenticating = false;
      if (_auth.currentUser == null) await _session(null);
    }
  }

  @override
  Future<String?> changeEmail(String password, String email) async {
    _authenticating = true;
    try {
      return await _operation(
        () => EmailSecurityApi.changeEmail(_auth, password, email),
      );
    } finally {
      _authenticating = false;
      if (_auth.currentUser == null) await _session(null);
    }
  }

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
  // Accept whole-number doubles (e.g. 150.0) written by other clients.
  if (v is num && v >= 0 && v == v.roundToDouble()) return v.toInt();
  throw FormatException('Invalid $k');
}

/// Parses each document, skipping (and logging) malformed ones so a single bad
/// record cannot break the whole screen after login.
List<T> _parse<T>(
  List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
  T Function(DocumentSnapshot<Map<String, dynamic>>) read,
) {
  final result = <T>[];
  for (final doc in docs) {
    try {
      result.add(read(doc));
    } catch (e) {
      debugPrint('Skipping malformed ${doc.reference.path}: $e');
    }
  }
  return result;
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
    approvalStatus: _s(d, 'approvalStatus', 'approved'),
    createdAt: _date(d['createdAt']),
    updatedAt: _date(d['updatedAt']),
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
    initialStock: _n(d, 'initialStock'),
    image: _s(d, 'image'),
    unit: _s(d, 'unit', 'kg'),
    description: _s(d, 'description'),
    approvalStatus: _s(d, 'approvalStatus', 'approved'),
    archived: d['archived'] == true,
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
    recipientName: _s(d, 'recipientName'),
    phone: _s(d, 'phone'),
    note: _s(d, 'note'),
    paymentMethod: d['paymentMethod'] as String? ?? 'cashOnDelivery',
    farmId: _s(d, 'farmId'),
    farmName: _s(d, 'farmName'),
    date: _date(d['createdAt'])!,
    address: _s(d, 'address'),
    status: status,
    approvalStatus: _s(d, 'approvalStatus', 'approved'),
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

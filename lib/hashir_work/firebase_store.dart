import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';

import 'firebase_collections.dart';
import 'models.dart';
import 'store.dart';

String serviceError(Object e) {
  debugPrint('HarvestHub service failure: $e');
  if (e is StateError) return e.message.toString();
  if (e is FirebaseFunctionsException && e.code == 'not-found') {
    return 'The Firebase backend function was not found. Check that Cloud Functions are deployed to the configured project in us-central1.';
  }
  if (e is FirebaseFunctionsException &&
      [
        'invalid-argument',
        'failed-precondition',
        'already-exists',
        'not-found',
      ].contains(e.code)) {
    return e.message ?? 'Check the entered details.';
  }
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

/// One session-owned data adapter using Firestore collection references.
class FirebaseStore extends HarvestStore {
  FirebaseStore({
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
    FirebaseFunctions? functions,
    FirebaseStorage? storage,
  }) : _auth = auth ?? FirebaseAuth.instance,
       _db = firestore ?? FirebaseFirestore.instance,
       _functions = functions ?? FirebaseFunctions.instance,
       _storage = storage ?? FirebaseStorage.instance {
    categories.clear();
    loading = true;
    _authSubscription = _auth.authStateChanges().listen(
      _session,
      onError: _error,
    );
  }

  final FirebaseAuth _auth;
  final FirebaseFirestore _db;
  final FirebaseFunctions _functions;
  final FirebaseStorage _storage;

  StreamSubscription<User?>? _authSubscription;
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>?
  _profileSubscription;
  final List<StreamSubscription> _subscriptions = [];

  Account? _account;
  bool _disposed = false;
  int _generation = 0;
  int _limit = 100;
  final Set<String> _more = {};
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
  void chooseRole(UserRole value) {}

  @override
  Farm farm(String id) =>
      farms.where((f) => f.id == id).firstOrNull ??
      Farm(
        id: id,
        name: 'Farm $id',
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
    readNotices.clear();
    bookingSlots.clear();
    recentSearches.clear();
    restockAlerts.clear();
    contactInfo.clear();
    report = null;
    _more.clear();
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
    if (user == null) {
      _account = null;
      _clear();
      error = null;
      loading = false;
      notifyListeners();
      return;
    }

    loading = _account == null;
    notifyListeners();

    // _session cancels data listeners even when sign-in already set _account.
    // The first profile snapshot must always restore this session's catalog.
    var firstProfileSnapshot = true;
    _profileSubscription = FirebaseCollections.userDoc(user.uid, _db)
        .snapshots()
        .listen((doc) async {
          if (generation != _generation) return;
          try {
            if (!doc.exists) {
              _account = null;
              await _cancelData();
              _clear();
              error =
                  'Your account profile is missing. Contact the administrator.';
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
            final reload =
                firstProfileSnapshot || _account == null || role != a.role;
            firstProfileSnapshot = false;
            _account = a;
            role = a.role;
            if (reload) {
              await refresh();
            } else {
              loading = false;
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
      FirebaseCollections.users,
      FirebaseCollections.farms,
      FirebaseCollections.products,
      FirebaseCollections.categories,
      FirebaseCollections.orders,
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
    Query<Map<String, dynamic>> userQuery = FirebaseCollections.usersRef(_db);
    if (role != UserRole.admin) {
      userQuery = userQuery.where(FieldPath.documentId, isEqualTo: uid);
    }
    watch(FirebaseCollections.users, userQuery.orderBy(FieldPath.documentId), (
      d,
    ) {
      accounts
        ..clear()
        ..addAll(_parse(d, readAccount));
    });

    watch(
      FirebaseCollections.farms,
      FirebaseCollections.farmsRef(_db).orderBy(FieldPath.documentId),
      (d) {
        farms
          ..clear()
          ..addAll(_parse(d, readFarm));
      },
    );

    Query<Map<String, dynamic>> pq = FirebaseCollections.productsRef(_db)
        .where('archived', isEqualTo: false);
    if (role == UserRole.farmer) pq = pq.where('farmId', isEqualTo: uid);
    watch(FirebaseCollections.products, pq.orderBy(FieldPath.documentId), (d) {
      final previous = {for (final p in products) p.id: p.stock};
      products
        ..clear()
        ..addAll(_parse(d, readProduct));
      if (role == UserRole.customer) {
        for (final a in detectRestocks(previous, products)) {
          pushAlert(a.title, a.message);
        }
      }
    });

    _subscriptions.add(
      _db.collection('appConfig').doc('contact').snapshots().listen((s) {
        if (generation != _generation) return;
        contactInfo
          ..clear()
          ..addEntries(
            (s.data() ?? {}).entries
                .where(
                  (e) => e.value is String && (e.value as String).isNotEmpty,
                )
                .map((e) => MapEntry(e.key, e.value as String)),
          );
        notifyListeners();
      }, onError: (Object e) => debugPrint('Contact details unavailable: $e')),
    );

    watch(
      FirebaseCollections.categories,
      FirebaseCollections.categoriesRef(_db).orderBy(FieldPath.documentId),
      (d) {
        categories
          ..clear()
          ..addAll(d.map((x) => x.data()['name']).whereType<String>());
        categoryCounts
          ..clear()
          ..addEntries(
            d
                .where((x) => x.data()['name'] is String)
                .map(
                  (x) => MapEntry(
                    x.data()['name'] as String,
                    (x.data()['productCount'] as num?)?.toInt() ?? 0,
                  ),
                ),
          );
      },
    );

    if (role == UserRole.customer) {
      unawaited(_registerPush(uid));
      final user = FirebaseCollections.userDoc(uid, _db);
      _subscriptions.add(
        user.collection('private').doc('preferences').snapshots().listen((
          snapshot,
        ) {
          if (_disposed ||
              generation != _generation ||
              _auth.currentUser?.uid != uid) {
            return;
          }
          final data = snapshot.data();
          if (data == null) return;
          saved
            ..clear()
            ..addAll((data['saved'] as List? ?? []).whereType<String>());
          followed
            ..clear()
            ..addAll((data['followed'] as List? ?? []).whereType<String>());
          readNotices
            ..clear()
            ..addAll((data['readNotices'] as List? ?? []).whereType<String>());
          notifyListeners();
        }, onError: _error),
      );
      _subscriptions.add(
        user.collection('pickups').snapshots().listen((snapshot) {
          if (_disposed ||
              generation != _generation ||
              _auth.currentUser?.uid != uid) {
            return;
          }
          bookingSlots
            ..clear()
            ..addEntries(
              snapshot.docs
                  .where((d) => d.data()['slot'] is String)
                  .map((d) => MapEntry(d.id, d.data()['slot'] as String)),
            );
          notifyListeners();
        }, onError: _error),
      );
    }

    Query<Map<String, dynamic>> oq = FirebaseCollections.ordersRef(_db);
    if (role == UserRole.customer) oq = oq.where('customerId', isEqualTo: uid);
    if (role == UserRole.farmer) oq = oq.where('farmerId', isEqualTo: uid);
    watch(
      FirebaseCollections.orders,
      oq.orderBy('createdAt', descending: true),
      (d) {
        final previous = {for (final o in orders) o.id: o};
        orders
          ..clear()
          ..addAll(
            _parse(d, readOrder).map((o) {
              final old = previous[o.id];
              if (old != null) {
                if (old.status != o.status && role == UserRole.customer) {
                  pushAlert(
                    'Order ${o.status.label}',
                    '${o.farmName} · ${o.id}',
                  );
                }
                old.status = o.status;
                return old;
              }
              return o;
            }),
          );
      },
    );

    if (role != UserRole.customer) unawaited(loadReport(36500));
  }

  /// Saves this device's FCM token so the backend can push order-status and
  /// restock alerts while the app is closed. Unsupported platforms are skipped.
  Future<void> _registerPush(String uid) async {
    final supported =
        !kIsWeb &&
        (defaultTargetPlatform == TargetPlatform.android ||
            defaultTargetPlatform == TargetPlatform.iOS ||
            defaultTargetPlatform == TargetPlatform.macOS);
    if (!supported) return;
    try {
      final messaging = FirebaseMessaging.instance;
      final settings = await messaging.requestPermission();
      if (settings.authorizationStatus == AuthorizationStatus.denied) return;
      final token = await messaging.getToken();
      if (token == null || _auth.currentUser?.uid != uid) return;
      await FirebaseCollections.userDoc(
        uid,
        _db,
      ).collection('devices').doc(token).set({
        'platform': defaultTargetPlatform.name,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      _subscriptions.add(
        FirebaseMessaging.onMessage.listen((m) {
          final n = m.notification;
          if (n != null) pushAlert(n.title ?? 'HarvestHub', n.body ?? '');
        }),
      );
    } catch (e) {
      debugPrint('Push registration skipped: $e');
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
    final response = await _functions.httpsCallable(name).call(data);
    return Map<String, dynamic>.from(response.data as Map);
  }

  @override
  Future<String?> signIn(
    String email,
    String password,
    UserRole selected,
  ) async {
    _authenticating = true;
    try {
      final result = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      var doc = await FirebaseCollections.userDoc(
        result.user!.uid,
        _db,
      ).get(const GetOptions(source: Source.server));

      if (!doc.exists) {
        if (selected == UserRole.admin) {
          throw StateError(
            'Your Auth account exists, but its administrator profile is missing from users/${result.user!.uid}. Ask the project owner to provision this UID as an administrator.',
          );
        }
        // Recover an Auth-only signup without allowing public admin creation.
        await _saveRegistration(
          Account(
            id: result.user!.uid,
            name: result.user!.displayName ?? email.trim().split('@').first,
            email: result.user!.email!,
            role: selected,
          ),
        );
        doc = await FirebaseCollections.userDoc(
          result.user!.uid,
          _db,
        ).get(const GetOptions(source: Source.server));
      }
      if (!doc.exists) {
        throw StateError(
          'Your profile has not been saved to the users collection. Please retry sign-in.',
        );
      }

      final acc = readAccount(doc);

      if (!acc.active) {
        await _auth.signOut();
        return 'This account is suspended. Contact the administrator.';
      }

      _account = acc;
      role = acc.role;
      notifyListeners();
      unawaited(refresh());
      return null;
    } catch (e) {
      await _auth.signOut();
      return serviceError(e);
    } finally {
      _authenticating = false;
      await _session(_auth.currentUser);
    }
  }

  Future<void> _saveRegistration(Account value) async {
    if (value.role == UserRole.admin || value.id != _auth.currentUser?.uid) {
      throw StateError('Public administrator registration is not allowed.');
    }
    final ref = FirebaseCollections.userDoc(value.id, _db);
    await _db.runTransaction((transaction) async {
      final existing = await transaction.get(ref);
      if (existing.exists) {
        return; // Never overwrite a role or suspended account.
      }
      transaction.set(ref, {
        ...value.toMap(),
        'createdAt': FieldValue.serverTimestamp(),
      });
      if (value.role == UserRole.farmer) {
        transaction.set(_db.collection('farms').doc(value.id), {
          'name': value.name,
          'owner': value.id,
          'location': '',
          'market': '',
          'description': '',
          'image': '',
          'active': true,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }
    });
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
      final cred = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      await _saveRegistration(
        Account(
          id: cred.user!.uid,
          name: name.trim(),
          email: cred.user!.email!,
          phone: phone.trim(),
          address: address.trim(),
          role: selected,
        ),
      );

      final uid = cred.user!.uid;
      final doc = await FirebaseCollections.userDoc(
        uid,
        _db,
      ).get(const GetOptions(source: Source.server));
      if (!doc.exists) {
        throw StateError(
          'Registration is incomplete: your profile was not saved to users/$uid. Please retry sign-in.',
        );
      }
      final account = readAccount(doc);
      if (account.role != selected || !account.active) {
        throw StateError(
          'The saved profile does not match this registration. Contact the project owner.',
        );
      }
      _account = account;
      role = account.role;
      notifyListeners();
      unawaited(refresh());

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
  Future<void> signOut() async {
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
      _mutate('saveCategory', {'name': value.trim(), 'previous': previous});

  @override
  Future<String?> deleteCategory(String value) =>
      _mutate('deleteCategory', {'name': value});

  @override
  Future<String?> toggleAccount(Account value) =>
      _mutate('toggleAccount', {'id': value.id, 'active': !value.active});

  @override
  Future<String?> saveAccount(Account value) {
    // Own profile: written directly (rules restrict it to name/phone/address).
    if (value.id == _auth.currentUser?.uid) {
      return _operation(() async {
        final name = value.name.trim();
        if (name.isEmpty || name.length > 500) {
          throw StateError('Enter your name.');
        }
        if (value.phone.length > 500 || value.address.length > 500) {
          throw StateError('Check your phone and address.');
        }
        await FirebaseCollections.userDoc(value.id, _db).update({
          'name': name,
          'phone': value.phone.trim(),
          'address': value.address.trim(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      });
    }
    return _mutate('saveAccount', {
      'id': value.id,
      'name': value.name,
      'phone': value.phone,
      'address': value.address,
    });
  }

  @override
  Future<String?> saveFarm(Farm value) {
    if (role == UserRole.farmer && value.owner == _auth.currentUser?.uid) {
      return _operation(() async {
        if (value.name.trim().isEmpty) throw StateError('Enter a farm name.');
        final ref = FirebaseCollections.farmsRef(_db).doc(value.id);
        await ref.update({
          'name': value.name.trim(),
          'location': value.location.trim(),
          'market': value.market.trim(),
          'description': value.description.trim(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
        // Separate write: needs the farm lat/lng/pickupSlots rule (firestore.rules).
        try {
          await ref.update({
            'lat': value.lat,
            'lng': value.lng,
            'pickupSlots': value.pickupSlots.take(20).toList(),
            'updatedAt': FieldValue.serverTimestamp(),
          });
        } on FirebaseException catch (e) {
          if (e.code != 'permission-denied') rethrow;
          throw StateError(
            'Farm details saved, but location and pickup times need the updated Firestore rules to be deployed.',
          );
        }
      });
    }
    return _mutate('saveFarm', {
      'id': value.id,
      'name': value.name,
      'location': value.location,
      'market': value.market,
      'description': value.description,
    });
  }

  @override
  Future<String?> deleteProduct(Product value) =>
      _mutate('deleteProduct', {'id': value.id});

  @override
  Future<String?> updateStatus(HarvestOrder order, OrderStatus status) =>
      _mutate('updateStatus', {'id': order.id, 'status': status.name});

  @override
  Future<String?> saveProduct(Product value) => _operation(() async {
    String url = value.image;
    Reference? upload;
    if (value.photo != null) {
      final bytes = value.photo!;
      final png =
          bytes.length > 8 &&
          bytes[0] == 137 &&
          bytes[1] == 80 &&
          bytes[2] == 78 &&
          bytes[3] == 71;
      final jpeg =
          bytes.length > 3 &&
          bytes[0] == 255 &&
          bytes[1] == 216 &&
          bytes[2] == 255;
      if ((!png && !jpeg) || bytes.length > 8 * 1024 * 1024) {
        throw FirebaseException(plugin: 'storage', code: 'invalid-argument');
      }
      upload = _storage.ref(
        'productImages/${_auth.currentUser!.uid}/${value.id}/${DateTime.now().microsecondsSinceEpoch}.${png ? 'png' : 'jpg'}',
      );
      await upload.putData(
        bytes,
        SettableMetadata(contentType: png ? 'image/png' : 'image/jpeg'),
      );
      url = await upload.getDownloadURL();
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
      notifyListeners();
      return null;
    }
    if (p == null || quantity > p.stock) return 'This quantity is unavailable.';
    basket[id] = quantity;
    notifyListeners();
    return null;
  }

  @override
  Future<List<HarvestOrder>> checkout(
    String address, {
    CheckoutDetails? details,
  }) async {
    if (busy) throw StateError('An order is already being submitted.');
    if (!canShop) throw StateError('This account cannot place orders.');
    final addr = address.trim();
    if (addr.isEmpty || addr.length > 500) {
      throw StateError('Please add your address.');
    }
    if (basket.isEmpty) throw StateError('Your basket is empty.');
    if (basket.length > 30) {
      throw StateError('Choose between 1 and 30 products.');
    }
    busy = true;
    notifyListeners();
    final uid = _auth.currentUser!.uid;
    final placed = <String>[];
    try {
      // The deployed rules accept one product per order, so each basket line
      // becomes its own order + stock decrement in a separate transaction.
      for (final entry in Map<String, int>.from(basket).entries) {
        final id = await _db.runTransaction<String>((tx) async {
          final productRef = FirebaseCollections.productsRef(_db)
              .doc(entry.key);
          final p = (await tx.get(productRef)).data();
          final quantity = entry.value;
          if (p == null ||
              p['archived'] != false ||
              p['stock'] is! int ||
              (p['stock'] as int) < quantity) {
            throw StateError(
              '${p?['name'] ?? 'An item'} is no longer available in that quantity. Update your basket.',
            );
          }
          final farm = (await tx.get(
            FirebaseCollections.farmsRef(_db).doc(p['farmId'] as String),
          )).data();
          if (farm == null || farm['active'] != true) {
            throw StateError('${p['name']}\'s farm is currently unavailable.');
          }
          final price = p['price'] as int;
          final ref = FirebaseCollections.ordersRef(_db).doc();
          // Field values must mirror the product/farm exactly (rules check them).
          tx.set(ref, {
            'customerId': uid,
            'customerName': account.name,
            'farmId': p['farmId'],
            'farmerId': farm['owner'],
            'farmName': farm['name'],
            'market': farm['market'],
            'items': [
              {
                'productId': entry.key,
                'name': p['name'],
                'image': p['image'],
                'unit': p['unit'],
                'price': price,
                'quantity': quantity,
              },
            ],
            'total': price * quantity,
            'address': addr,
            'phone': (details?.phone ?? account.phone).trim(),
            'note': (details?.note ?? '').trim(),
            'paymentMethod':
                (details?.payment ?? PaymentMethod.cashOnDelivery).name,
            'status': OrderStatus.pending.name,
            'createdAt': FieldValue.serverTimestamp(),
          });
          tx.update(productRef, {
            'stock': (p['stock'] as int) - quantity,
            'lastOrderId': ref.id,
            'updatedAt': FieldValue.serverTimestamp(),
          });
          return ref.id;
        });
        placed.add(id);
        basket.remove(entry.key);
      }
      final docs = await Future.wait(
        placed.map((id) => FirebaseCollections.orderDoc(id, _db).get()),
      );
      return docs.map(readOrder).toList();
    } catch (e) {
      final message = serviceError(e);
      throw StateError(
        placed.isEmpty
            ? message
            : '${placed.length} item(s) were ordered; the rest failed: $message',
      );
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
        final mail = email.trim(), text = message.trim();
        if (mail.isEmpty || mail.length > 320) {
          throw StateError('Enter your email.');
        }
        if (text.isEmpty || text.length > 5000) {
          throw StateError('Enter a message up to 5000 characters.');
        }
        await FirebaseCollections.feedbackRef(_db).add({
          'userId': _auth.currentUser!.uid,
          'email': mail,
          'message': text,
          'read': false,
          'createdAt': FieldValue.serverTimestamp(),
        });
      });

  DocumentReference<Map<String, dynamic>> get _preferences =>
      FirebaseCollections.userDoc(
        _auth.currentUser!.uid,
        _db,
      ).collection('private').doc('preferences');
  @override
  void toggleSaved(String id) {
    if (!canShop) return;
    final remove = saved.contains(id);
    final uid = _auth.currentUser!.uid;
    super.toggleSaved(id);
    unawaited(
      _preferences
          .set({
            'saved': remove
                ? FieldValue.arrayRemove([id])
                : FieldValue.arrayUnion([id]),
          }, SetOptions(merge: true))
          .catchError((Object e) {
            if (!_disposed && _auth.currentUser?.uid == uid) {
              remove ? saved.add(id) : saved.remove(id);
              _error(e);
            }
          }),
    );
  }

  @override
  Future<String?> toggleFollow(String id) => _operation(() async {
    if (!canShop) throw StateError('Sign in to follow farms.');
    await _preferences.set({
      'followed': followed.contains(id)
          ? FieldValue.arrayRemove([id])
          : FieldValue.arrayUnion([id]),
    }, SetOptions(merge: true));
  });
  @override
  Future<String?> markNoticesRead() => _operation(() async {
    if (!canShop) throw StateError('Please sign in.');
    await _preferences.set({
      'readNotices': FieldValue.arrayUnion(
        customerNotices.map((n) => n.id).toList(),
      ),
    }, SetOptions(merge: true));
  });
  @override
  Future<String?> savePickup(HarvestOrder order, String? slot) => _operation(
    () async {
      if (!canShop || order.customerId != account.id || !order.status.active) {
        throw StateError('This pickup cannot be changed.');
      }
      final ref = FirebaseCollections.userDoc(
        account.id,
        _db,
      ).collection('pickups').doc(order.id);
      await ref.set({'slot': slot, 'updatedAt': FieldValue.serverTimestamp()});
      if (slot == null) {
        bookingSlots.remove(order.id);
      } else {
        bookingSlots[order.id] = slot;
      }
    },
  );

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

String _s(Map<String, dynamic> d, String k, [String fallback = '']) =>
    d[k] is String ? d[k] as String : fallback;

int _n(Map<String, dynamic> d, String k) {
  final v = d[k];
  if (v is num && v >= 0 && v == v.roundToDouble()) return v.toInt();
  throw FormatException('Invalid $k');
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
    lat: (d['lat'] as num?)?.toDouble(),
    lng: (d['lng'] as num?)?.toDouble(),
    pickupSlots: (d['pickupSlots'] as List? ?? []).whereType<String>().toList(),
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
    image: _s(d, 'image').isNotEmpty
        ? _s(d, 'image')
        : stockPhotoFor(_s(d, 'name')),
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
    phone: _s(d, 'phone'),
    note: _s(d, 'note'),
    payment: PaymentMethodName.parse(d['paymentMethod']),
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

/// Parses each document, skipping (and logging) malformed ones so a single bad
/// record cannot block the whole screen from loading.
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

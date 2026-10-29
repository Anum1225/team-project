import 'dart:async';

import 'package:flutter/foundation.dart';

import 'models.dart';
import 'store.dart';
import 'trusted_backend.dart';

/// Read-only live catalog with session-local customer interactions.
class GuestStore extends HarvestStore {
  GuestStore({
    required this.onSignIn,
    this.loadPage = TrustedBackend.publicCatalog,
  }) {
    accounts.add(
      Account(id: 'guest', name: 'Guest', email: '', role: UserRole.customer),
    );
  }
  final VoidCallback onSignIn;
  final Future<Map<String, dynamic>> Function(Map<String, dynamic>) loadPage;
  bool _disposed = false;
  final _markets = <Map<String, dynamic>>[];
  @override
  bool get isDemo => true;
  @override
  bool get authenticated => false;
  @override
  List<Map<String, dynamic>> get publicMarkets => _markets;
  @override
  void requestSignIn() => onSignIn();
  @override
  void chooseRole(UserRole value) {}
  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  @override
  Future<void> refresh() async {
    if (loading) return;
    loading = true;
    error = null;
    notifyListeners();
    try {
      final rows = {
        for (final key in ['products', 'farms', 'categories', 'markets'])
          key: <Map<String, dynamic>>[],
      };
      var cursors = <String, dynamic>{};
      var page = 0;
      do {
        final data = await loadPage(cursors);
        if (_disposed) return;
        for (final key in rows.keys) {
          rows[key]!.addAll(
            (data[key] as List? ?? []).map(
              (v) => Map<String, dynamic>.from(v as Map),
            ),
          );
        }
        cursors = Map<String, dynamic>.from(data['cursors'] as Map? ?? {});
        if (++page > 100) {
          throw StateError('Catalog is too large to load. Please retry.');
        }
      } while (cursors.values.any((v) => v != null));
      String s(Map<String, dynamic> row, String field) =>
          row[field] as String? ?? '';
      farms
        ..clear()
        ..addAll(
          rows['farms']!.map(
            (r) => Farm(
              id: s(r, 'id'),
              owner: '',
              name: s(r, 'name'),
              location: s(r, 'location'),
              market: s(r, 'market'),
              description: s(r, 'description'),
              image: s(r, 'image'),
              latitude: (r['lat'] as num?)?.toDouble(),
              longitude: (r['lng'] as num?)?.toDouble(),
              pickupSlots: List<String>.from(r['pickupSlots'] as List? ?? []),
            ),
          ),
        );
      final ids = farms.map((f) => f.id).toSet();
      products
        ..clear()
        ..addAll(
          rows['products']!
              .where((r) => ids.contains(r['farmId']))
              .map(
                (r) => Product(
                  id: s(r, 'id'),
                  name: s(r, 'name'),
                  category: s(r, 'category'),
                  farmId: s(r, 'farmId'),
                  price: (r['price'] as num? ?? 0).toInt(),
                  stock: (r['stock'] as num? ?? 0).toInt(),
                  image: s(r, 'image'),
                  unit: s(r, 'unit'),
                  description: s(r, 'description'),
                ),
              ),
        );
      categories
        ..clear()
        ..addAll(
          {
            ...rows['categories']!.map((r) => s(r, 'name')),
            ...products.map((p) => p.category),
          }.where((v) => v.isNotEmpty),
        );
      _markets
        ..clear()
        ..addAll(rows['markets']!.map((row) => {...row, 'active': true}));
      for (final id in basket.keys.toList()) {
        final stock = product(id)?.stock ?? 0;
        if (stock == 0) {
          basket.remove(id);
        } else if (basket[id]! > stock) {
          basket[id] = stock;
        }
      }
    } catch (_) {
      if (!_disposed) {
        error = 'Could not load the live catalog. Check your connection and tap Retry.';
      }
    } finally {
      if (!_disposed) {
        loading = false;
        notifyListeners();
      }
    }
  }

  @override
  String? setQuantity(String id, int quantity) {
    if (quantity <= 0) {
      basket.remove(id);
      changed();
      return null;
    }
    return 'Sign in to add products to your cart.';
  }

  @override
  FutureOr<String?> toggleFollowed(String farmId) {
    followed.contains(farmId) ? followed.remove(farmId) : followed.add(farmId);
    changed();
    return null;
  }

  @override
  FutureOr<List<HarvestOrder>> checkout(
    String address, {
    String? pickupSlot,
    String? recipientName,
    String? phone,
    String note = '',
  }) => throw StateError('Sign in before placing an order.');
  @override
  Future<String?> saveAccount(Account value) async =>
      'Sign in to save account details.';
  @override
  Future<String?> sendFeedback(String email, String message) async =>
      'Sign in to send your message.';
}

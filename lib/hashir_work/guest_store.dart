import 'dart:async';

import 'package:shared_preferences/shared_preferences.dart';

import 'models.dart';
import 'store.dart';
import 'demo_catalog/data/sample_catalog.dart' as sample;

/// Demo data is isolated from live inventory and authenticated accounts.
class GuestStore extends HarvestStore {
  GuestStore(this.authentication) {
    accounts.add(
      Account(id: 'guest', name: 'Guest', email: '', role: UserRole.customer),
    );
    categories.addAll(sample.categories.where((c) => c != 'All'));
    farms.addAll(
      sample.farmers.map(
        (f) => Farm(
          id: f.id,
          name: f.name,
          owner: f.id,
          location: f.location,
          market: f.market,
          description: f.story,
          image: 'farm',
        ),
      ),
    );
    products.addAll(
      sample.products.map(
        (p) => Product(
          id: p.id,
          name: p.name,
          category: p.category,
          farmId: p.farmerId,
          price: p.price * 100,
          stock: p.stock,
          image: 'p_${p.id}',
          unit: p.unit,
          description: p.description,
        ),
      ),
    );
    unawaited(_restore());
  }
  final HarvestStore authentication;
  bool _closed = false, _edited = false;
  Future<void> _restore() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (_closed || _edited) return;
      saved.addAll(
        (prefs.getStringList('harvesthub.guest.saved') ?? []).where(
          (id) => product(id) != null,
        ),
      );
      notifyListeners();
    } catch (_) {
      /* Browsing can continue without a local cache. */
    }
  }

  @override
  bool get isDemo => true;
  @override
  bool get authenticated => false;
  @override
  void chooseRole(UserRole value) {}
  @override
  void toggleSaved(String id) {
    _edited = true;
    super.toggleSaved(id);
    final value = saved.toList();
    unawaited(
      SharedPreferences.getInstance()
          .then((p) => p.setStringList('harvesthub.guest.saved', value))
          .catchError((Object e) {
            if (!_closed) {
              error = 'Favorites could not be saved on this device.';
              notifyListeners();
            }
            return false;
          }),
    );
  }

  @override
  Future<String?> signIn(String email, String password, UserRole selected) =>
      authentication.signIn(email, password, selected);
  @override
  Future<String?> register(
    String email,
    String password,
    String name,
    String phone,
    String address,
    UserRole selected,
  ) => authentication.register(email, password, name, phone, address, selected);
  @override
  Future<String?> resetPassword(String email) =>
      authentication.resetPassword(email);
  @override
  Future<String?> saveAccount(Account value) async =>
      'Sign in to edit your profile.';
  @override
  void dispose() {
    _closed = true;
    super.dispose();
  }
}

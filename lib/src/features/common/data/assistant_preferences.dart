import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Account-scoped preference shared by Home and settings. Unknown stays hidden.
class AssistantPreferences extends ChangeNotifier {
  final _values = <String, bool>{};
  final _loads = <String, Future<void>>{};
  bool _disposed = false;

  bool? enabledFor(String accountId) => _values[accountId];

  Future<void> load(String accountId) => _loads.putIfAbsent(
    accountId,
    () async {
      try {
        final prefs = await SharedPreferences.getInstance();
        if (_disposed || _values.containsKey(accountId)) return;
        _values[accountId] =
            prefs.getBool('harvesthub_assistant_$accountId') ??
            !(prefs.getBool('harvesthub_hide_ola') ?? false);
        notifyListeners();
      } catch (_) {
        // Keep the mascot hidden until storage can be read or the user opts in.
        _loads.remove(accountId);
      }
    },
  );

  Future<bool> setEnabled(String accountId, bool enabled) async {
    final previous = _values[accountId];
    _values[accountId] = enabled;
    if (!_disposed) notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      if (!await prefs.setBool('harvesthub_assistant_$accountId', enabled)) {
        throw StateError('Preference could not be saved');
      }
      return true;
    } catch (_) {
      if (previous == null) {
        _values.remove(accountId);
      } else {
        _values[accountId] = previous;
      }
      if (!_disposed) notifyListeners();
      return false;
    }
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}

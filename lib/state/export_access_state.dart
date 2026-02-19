import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class ExportAccessState extends ChangeNotifier {
  static const _homesKey = 'unlocked_home_ids';
  static const _subExpiryKey = 'subscription_expiry';

  Set<String> _unlockedHomeIds = {};
  DateTime? _subscriptionExpiry;

  bool _devForceUnlock = false;

    void toggleDevForceUnlock() {
      _devForceUnlock = !_devForceUnlock;
      notifyListeners();
    }
  
  bool hasUnlimitedAccess() {
  if (_devForceUnlock) return true;

  if (_subscriptionExpiry == null) return false;
  return DateTime.now().isBefore(_subscriptionExpiry!);
}

  bool isHomeUnlocked(String   homeId) {
    if (hasUnlimitedAccess()) return true;
    return _unlockedHomeIds.contains(homeId);
  }

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();

    final homesJson = prefs.getString(_homesKey);
    if (homesJson != null) {
      _unlockedHomeIds =
          Set<String>.from(jsonDecode(homesJson));
    }

    final expiryString = prefs.getString(_subExpiryKey);
    if (expiryString != null) {
      _subscriptionExpiry = DateTime.parse(expiryString);
    }

    notifyListeners();
  }

  Future<void> unlockHome(String homeId) async {
    _unlockedHomeIds.add(homeId);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _homesKey,
      jsonEncode(_unlockedHomeIds.toList()),
    );

    notifyListeners();
  }

  Future<void> setSubscriptionExpiry(DateTime expiry) async {
    _subscriptionExpiry = expiry;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _subExpiryKey,
      expiry.toIso8601String(),
    );

    notifyListeners();
  }

  DateTime? get subscriptionExpiry => _subscriptionExpiry;
}

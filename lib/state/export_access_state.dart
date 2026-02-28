import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class ExportAccessState extends ChangeNotifier {
  static const _homesKey = 'unlocked_home_ids';
  static const _subExpiryKey = 'subscription_expiry';
  static const _subActiveKey = 'subscription_active';

  Set<String> _unlockedHomeIds = {};
  DateTime? _subscriptionExpiry;
  bool _subscriptionActive = false;

  bool _devForceUnlock = false;

  void toggleDevForceUnlock() {
    _devForceUnlock = !_devForceUnlock;
    notifyListeners();
  }

  bool hasUnlimitedAccess() {
    if (_devForceUnlock) return true;
    if (!_subscriptionActive) return false;
    if (_subscriptionExpiry == null) return false;
    return DateTime.now().isBefore(_subscriptionExpiry!);
  }

  bool isHomeUnlocked(String homeId) {
    if (hasUnlimitedAccess()) return true;
    return _unlockedHomeIds.contains(homeId);
  }

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();

    final homesJson = prefs.getString(_homesKey);
    if (homesJson != null) {
      _unlockedHomeIds = Set<String>.from(jsonDecode(homesJson));
    }

    final expiryString = prefs.getString(_subExpiryKey);
    if (expiryString != null) {
      _subscriptionExpiry = DateTime.parse(expiryString);
    }

    _subscriptionActive = prefs.getBool(_subActiveKey) ?? false;

    // If we have an expiry date but it's already passed, mark inactive
    if (_subscriptionExpiry != null &&
        DateTime.now().isAfter(_subscriptionExpiry!)) {
      _subscriptionActive = false;
      await prefs.setBool(_subActiveKey, false);
    }

    notifyListeners();
  }

  Future<void> unlockHome(String homeId) async {
    _unlockedHomeIds.add(homeId);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_homesKey, jsonEncode(_unlockedHomeIds.toList()));
    notifyListeners();
  }

  /// Called when Apple confirms an active subscription purchase or restore.
  Future<void> activateSubscription(DateTime expiry) async {
    _subscriptionActive = true;
    _subscriptionExpiry = expiry;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_subActiveKey, true);
    await prefs.setString(_subExpiryKey, expiry.toIso8601String());

    notifyListeners();
  }

  /// Called when Apple confirms a subscription has been cancelled/expired.
  Future<void> deactivateSubscription() async {
    _subscriptionActive = false;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_subActiveKey, false);

    notifyListeners();
  }

  Future<void> clearAll() async {
    _unlockedHomeIds = {};
    _subscriptionExpiry = null;
    _subscriptionActive = false;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_homesKey);
    await prefs.remove(_subExpiryKey);
    await prefs.remove(_subActiveKey);
    notifyListeners();
  }

  DateTime? get subscriptionExpiry => _subscriptionExpiry;
  bool get subscriptionActive => _subscriptionActive;
}
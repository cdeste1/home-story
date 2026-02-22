import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/home.dart';

class HomeState extends ChangeNotifier {
  static const _storageKey = 'homes';

  final List<Home> _homes = [];

  List<Home> get homes => List.unmodifiable(_homes);

  /// Returns all home IDs
  List<String> allHomeIds() => _homes.map((h) => h.id).toList();

  /// Load homes from SharedPreferences
  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_storageKey);
    if (jsonString == null) return;

    final List decoded = json.decode(jsonString);
    _homes
      ..clear()
      ..addAll(decoded.map((e) => Home.fromJson(e)));

    notifyListeners();
  }

  /// Add a new home
  void addHome(Home home) {
    _homes.add(home);
    _save();
    notifyListeners();
  }

  /// Update an existing home


    void updateHome(Home updatedHome) {
    final index = _homes.indexWhere((h) => h.id == updatedHome.id);
    if (index != -1) {
      _homes[index] = updatedHome;
      notifyListeners();
    }
  }

  /// Delete an existing home
  void deleteHome(String id) {
    _homes.removeWhere((h) => h.id == id);
    notifyListeners();
  }

  /// Reset all homes (dev / demo only)
  Future<void> clear() async {
    _homes.clear();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_storageKey);
    notifyListeners();
  }

  /// Persist homes to SharedPreferences
  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = json.encode(_homes.map((e) => e.toJson()).toList());
    await prefs.setString(_storageKey, jsonString);
  }
}
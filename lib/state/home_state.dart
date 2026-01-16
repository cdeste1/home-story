import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/home.dart';

class HomeState extends ChangeNotifier {
  static const _storageKey = 'homes';

  final List<Home> _homes = [];

  List<Home> get homes => List.unmodifiable(_homes);

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

  void addHome(Home home) {
    _homes.add(home);
    _save();
    notifyListeners();
  }

    /// 🔥 RESET (dev / demo only)
Future<void> clear() async {
    _homes.clear();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('homes');
    notifyListeners();
  }

  /*Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_storageKey);

    if (jsonString == null) return;

    final List decoded = json.decode(jsonString);
    _homes
      ..clear()
      ..addAll(decoded.map((e) => Home.fromJson(e)));

    notifyListeners();
  }*/

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString =
        json.encode(_homes.map((e) => e.toJson()).toList());
    await prefs.setString(_storageKey, jsonString);
  }
}


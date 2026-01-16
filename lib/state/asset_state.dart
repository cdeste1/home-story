import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/asset.dart';

class AssetState extends ChangeNotifier {
  static const _storageKey = 'assets';

  final List<Asset> _assets = [];

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_storageKey);
    if (jsonString == null) return;

    final List decoded = json.decode(jsonString);
    _assets
      ..clear()
      ..addAll(decoded.map((e) => Asset.fromJson(e)));

    notifyListeners();
  }

  List<Asset> assetsForHome(String homeId) {
    return _assets.where((a) => a.homeId == homeId).toList();
  }

  void addAsset(Asset asset) {
    final index = _assets.indexWhere((a) => a.id == asset.id);
  if (index != -1) {
    // Asset exists → update it
    _assets[index] = asset;
  } else {
    // New asset → insert at top
    _assets.insert(0, asset);
  }
  _save();
  notifyListeners();
}

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString =
        json.encode(_assets.map((e) => e.toJson()).toList());
    await prefs.setString(_storageKey, jsonString);
  }

  void deleteAsset(String assetId) {
    _assets.removeWhere((a) => a.id == assetId);
    notifyListeners();
  }
}

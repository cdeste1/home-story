import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/agent_profile.dart';

class AgentState extends ChangeNotifier {
  static const _storageKey = 'agent_profile';
  AgentState() {
  debugPrint('AgentState instance created: $hashCode');
}

  AgentProfile? _agent;
  AgentProfile? get agent => _agent;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_storageKey);
    if (jsonString == null) return;

    _agent = AgentProfile.fromJson(json.decode(jsonString));
    notifyListeners();
  }

  Future<void> save(AgentProfile agent) async {
    _agent = agent;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_storageKey, json.encode(agent.toJson()));
    notifyListeners();
  }

  /// 🔥 RESET (dev / demo only)
  Future<void> clear() async {
    _agent = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_storageKey);
    notifyListeners();
  }
}

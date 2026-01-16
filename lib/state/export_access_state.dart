import 'package:flutter/material.dart';

class ExportAccessState extends ChangeNotifier {
  bool _unlocked = false;

  bool get isUnlocked => _unlocked;

  void unlock() {
    _unlocked = true;
    notifyListeners();
  }
}
import 'package:flutter/material.dart';

class SleepState extends ChangeNotifier {
  bool _isActive = false;

  bool get isActive => _isActive;

  void startSleep() {
    _isActive = true;
    notifyListeners();
  }

  void stopSleep() {
    _isActive = false;
    notifyListeners();
  }
}
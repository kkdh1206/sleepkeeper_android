import 'package:flutter/cupertino.dart';

class SleepState extends ChangeNotifier {
  bool _isActive = false;

  bool get isActive => _isActive; // _앞에 붙으면 접근모샣서 이걸 써준거임

  void startSleep() {
    _isActive = true;
    notifyListeners();
  }

  void stopSleep() {
    _isActive = false;
    notifyListeners();
  }
}
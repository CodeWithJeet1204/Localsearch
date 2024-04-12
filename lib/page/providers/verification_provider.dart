import 'package:flutter/material.dart';

class VerificationProvider with ChangeNotifier {
  bool _isVerified = false;

  bool get isVerified => _isVerified;

  void verify() {
    _isVerified = true;

    notifyListeners();
  }
}

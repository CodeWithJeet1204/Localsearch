import 'package:flutter/material.dart';

class RegisterDetailsProvider with ChangeNotifier {
  bool _isRegisteredWithDetails = false;

  bool get isRegisteredWithDetails => _isRegisteredWithDetails;

  void registerWithDetails() {
    _isRegisteredWithDetails = true;

    notifyListeners();
  }
}

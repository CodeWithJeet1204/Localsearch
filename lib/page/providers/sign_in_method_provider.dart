import 'package:flutter/material.dart';

class SignInMethodProvider with ChangeNotifier {
  bool _isEmailChosen = false;
  bool _isNumberChosen = false;
  bool _isGoogleChosen = false;

  bool get isEmailChosen => _isEmailChosen;
  bool get isNumberChosen => _isNumberChosen;
  bool get isGoogleChosen => _isGoogleChosen;

  void chooseEmail() {
    _isEmailChosen = true;
    _isNumberChosen = false;
    _isGoogleChosen = false;

    notifyListeners();
  }

  void chooseNumber() {
    _isEmailChosen = false;
    _isNumberChosen = true;
    _isGoogleChosen = false;

    notifyListeners();
  }

  void chooseGoogle() {
    _isEmailChosen = false;
    _isNumberChosen = false;
    _isGoogleChosen = true;

    notifyListeners();
  }
}

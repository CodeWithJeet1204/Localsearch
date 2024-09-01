import 'package:flutter/material.dart';

class ReviewProvider with ChangeNotifier {
  bool _hasAsked = false;
  bool get hasAsked => _hasAsked;

  // REVIEWED
  void reviewed() {
    _hasAsked = true;

    notifyListeners();
  }
}

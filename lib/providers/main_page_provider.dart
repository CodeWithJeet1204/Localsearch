import 'package:flutter/material.dart';

class MainPageProvider with ChangeNotifier {
  int _index = 0;
  int get index => _index;
  final List<int> _loadedPages = [0];
  List<int> get loadedPages => _loadedPages;

  // CHANGE INDEX
  void changeIndex(int newIndex) {
    if (!_loadedPages.contains(newIndex)) {
      _loadedPages.add(newIndex);
    }
    _index = newIndex;

    notifyListeners();
  }

  // GO TO HOME PAGE
  void goToHomePage() {
    _index = 0;

    notifyListeners();
  }
}

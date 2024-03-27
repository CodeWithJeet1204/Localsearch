import 'package:flutter/material.dart';

class RecentProvider with ChangeNotifier {
  bool _showRecent = false;

  bool get isRecent => _showRecent;

  void changeRecent(bool isRecent) {
    _showRecent = isRecent;
  }
}

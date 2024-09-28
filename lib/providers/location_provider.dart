import 'package:flutter/material.dart';

class LocationProvider with ChangeNotifier {
  String? _cityName = 'Your Location';
  double? _cityLatitude;
  double? _cityLongitude;

  String? get cityName => _cityName;
  double? get cityLatitude => _cityLatitude;
  double? get cityLongitude => _cityLongitude;

  // CHANGE CITY
  void changeCity(Map<String, Map<String, dynamic>>? cityInfo) {
    if (cityInfo != null) {
      _cityName = cityInfo.values.toList()[0]['cityName'];
      _cityLatitude = cityInfo.values.toList()[0]['cityLatitude'];
      _cityLongitude = cityInfo.values.toList()[0]['cityLongitude'];
    } else {
      _cityName = null;
      _cityLatitude = null;
      _cityLongitude = null;
    }

    notifyListeners();
  }
}

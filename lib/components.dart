library;

import 'package:flutter/material.dart';
import 'package:materials/materials.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Components {
  static var _setLoading;
  static bgLoading(bool bool) {
    if (_setLoading != null) _setLoading(bool);
  }

  static renderBgLoading(content, isLoading, setLoading) {
    _setLoading = setLoading;
    if (isLoading) {
      return Container(
        width: MediaQuery.of(content).size.width,
        height: MediaQuery.of(content).size.height,
        color: const Color.fromARGB(255, 255, 252, 252).withOpacity(0.5),
        child: Center(child: MyImage(url: 'assets/loader.gif', width: 120)),
      );
    }
    return Container();
  }
}

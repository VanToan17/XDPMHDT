import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';

class UserSession with ChangeNotifier {
  int? userId;
  String? fullName;
  String? email;
  bool isVip = false;
  String? vipEndAt;

  /// Trả về true nếu user đã đăng nhập
  bool get isLoggedIn => userId != null;

  /// Trả về true nếu user là VIP và còn thời hạn VIP
  /*bool get isVipStillValid {
    if (!isVip || vipEndAt == null) return false;

    try {
      final endDate = DateTime.parse(vipEndAt!);
      return endDate.isAfter(DateTime.now());
    } catch (_) {
      return false;
    }
  }*/
  bool get isVipStillValid {
    print("[UserSession] Checking isVipStillValid with isVip: $isVip, vipEndAt: $vipEndAt");
    if (!isVip || vipEndAt == null) return false;
    try {
      final endDate = DateTime.parse(vipEndAt!);
      print("[UserSession] Parsed endDate: $endDate, now: ${DateTime.now()}");
      return endDate.isAfter(DateTime.now());
    } catch (e) {
      print("[UserSession] Error parsing vipEndAt: $e");
      return false;
    }
  }


  /// Gọi khi đăng nhập thành công
  Future<void> setUser({
    required int id,
    String? name,
    required String userEmail,
    required bool vip,
    String? vipEnd,
  }) async {
    userId = id;
    fullName = name;
    email = userEmail;
    isVip = vip;
    vipEndAt = vipEnd;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('userId', id);
    await prefs.setString('email', userEmail);
    await prefs.setBool('isVip', vip);
    if (vipEnd != null) {
      await prefs.setString('vipEndAt', vipEnd);
    } else {
      await prefs.remove('vipEndAt');
    }
    if (name != null) {
      await prefs.setString('fullName', name);
    } else {
      await prefs.remove('fullName');
    }
  }
  Future<void> logout() async {
    userId = null;
    email = null;
    isVip = false;
    vipEndAt = null;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }


  

  /// Gọi khi mở app để khôi phục session
  Future<void> loadSession() async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.containsKey('userId')) {
      userId = prefs.getInt('userId');
      fullName = prefs.getString('fullName');
      email = prefs.getString('email');
      isVip = prefs.getBool('isVip') ?? false;
      vipEndAt = prefs.getString('vipEndAt');
      notifyListeners();
    }
  }

  /// Cho phép gọi nhanh qua UserSession.of(context)
  static UserSession of(BuildContext context, {bool listen = false}) {
    return Provider.of<UserSession>(context, listen: listen);
  }
}

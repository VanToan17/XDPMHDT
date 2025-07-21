import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:project_group_9/widgets/user_session.dart';
import 'package:project_group_9/frame_Screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final emailCtrl = TextEditingController();
  final passwordCtrl = TextEditingController();

  String message = '';
  bool loading = false;

  Future<void> login() async {
    setState(() {
      loading = true;
      message = '';
    });

    try {
      final res = await http.post(
        Uri.parse("http://10.0.2.2:8000/api_handle/login.php"),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          "email": emailCtrl.text.trim(),
          "password": passwordCtrl.text,
        }),
      );

      final data = jsonDecode(res.body);

      if (res.statusCode == 200 && data['success'] == true) {
        final userId = data['user_id'];

        final infoRes = await http.get(
          Uri.parse(
            "http://10.0.2.2:8000/api_handle/vnpay_api_handle/get_user_info.php?id=$userId",
          ),
        );

        if (infoRes.statusCode == 200) {
          final infoData = jsonDecode(infoRes.body);

          if (infoData['success'] == true && infoData['user'] != null) {
            final user = infoData['user'];

            bool isVip = false;
            final vipEndStr = user['vip_end_at'];
            if (vipEndStr != null && vipEndStr.toString().isNotEmpty) {
              try {
                final vipEnd = DateTime.parse(vipEndStr);
                isVip = vipEnd.isAfter(DateTime.now());
              } catch (_) {}
            }

            final session = Provider.of<UserSession>(context, listen: false);
            session.setUser(
              id: data['user_id'],
              name: data['full_name'],
              userEmail: emailCtrl.text.trim(),
              vip: isVip,
              vipEnd: vipEndStr,
            );

            final prefs = await SharedPreferences.getInstance();
            await prefs.setInt('user_id', data['user_id']);

            if (!mounted) return;
            context.goNamed('home');
            return;
          }
        }

        setState(() {
          message =
              'Đăng nhập thành công, nhưng không lấy được thông tin người dùng.';
        });
      } else {
        setState(() {
          message = data['message'] ?? 'Tài khoản hoặc mật khẩu không đúng';
        });
      }
    } catch (e) {
      setState(() {
        message = 'Lỗi kết nối: $e';
      });
    } finally {
      setState(() {
        loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return FrameScreen(
      showAppBar: false,
      showDefaultBottomBar: false,
      body: Container(
        color: Colors.black,
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight:
                    MediaQuery.of(context).size.height -
                    MediaQuery.of(context).padding.top -
                    MediaQuery.of(context).padding.bottom,
              ),
              child: IntrinsicHeight(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 32),
                    const Icon(Icons.movie, color: Colors.white, size: 72),
                    const SizedBox(height: 24),
                    const Text(
                      'Đăng nhập',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 32),
                    TextField(
                      controller: emailCtrl,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: 'Email',
                        hintStyle: const TextStyle(color: Colors.grey),
                        filled: true,
                        fillColor: Colors.grey.shade900,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: passwordCtrl,
                      obscureText: true,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: 'Mật khẩu',
                        hintStyle: const TextStyle(color: Colors.grey),
                        filled: true,
                        fillColor: Colors.grey.shade900,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () {
                          context.goNamed('forgot');
                        },
                        child: const Text(
                          'Quên mật khẩu?',
                          style: TextStyle(color: Colors.white70),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    loading
                        ? const Center(
                            child: CircularProgressIndicator(
                              color: Colors.white,
                            ),
                          )
                        : ElevatedButton(
                            onPressed: login,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text(
                              'Đăng nhập',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.white,
                              ),
                            ),
                          ),
                    const SizedBox(height: 12),
                    if (message.isNotEmpty)
                      Text(
                        message,
                        style: const TextStyle(color: Colors.redAccent),
                        textAlign: TextAlign.center,
                      ),
                    const SizedBox(
                      height: 24,
                    ), // dùng SizedBox thay vì Spacer để kiểm soát khoảng cách
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          'Chưa có tài khoản?',
                          style: TextStyle(color: Colors.white70),
                        ),
                        TextButton(
                          onPressed: () {
                            context.goNamed('register');
                          },
                          child: const Text('Đăng ký ngay'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

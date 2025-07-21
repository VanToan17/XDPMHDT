import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../api_service.dart';
import '../frame_Screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final fullnameCtrl = TextEditingController();
  final emailCtrl = TextEditingController();
  final passwordCtrl = TextEditingController();
  final confirmPasswordCtrl = TextEditingController();
  final otpCtrl = TextEditingController();

  String resultMessage = '';
  bool isLoading = false;

  void setLoading(bool value) {
    setState(() {
      isLoading = value;
    });
  }

  Future<void> register() async {
    setLoading(true);

    if (fullnameCtrl.text.trim().isEmpty ||
        emailCtrl.text.trim().isEmpty ||
        passwordCtrl.text.isEmpty ||
        confirmPasswordCtrl.text.isEmpty) {
      setState(() {
        resultMessage = 'Vui lòng điền đầy đủ thông tin.';
      });
      setLoading(false);
      return;
    }

    if (passwordCtrl.text != confirmPasswordCtrl.text) {
      setState(() {
        resultMessage = 'Mật khẩu xác nhận không khớp.';
      });
      setLoading(false);
      return;
    }

    final response = await ApiService.registerUser(
      fullname: fullnameCtrl.text.trim(),
      email: emailCtrl.text.trim(),
      password: passwordCtrl.text,
      confirmPassword: confirmPasswordCtrl.text,
    );

    setLoading(false);

    if (response['success']) {
      showOtpDialog(emailCtrl.text.trim());
    } else {
      setState(() {
        resultMessage = response['message'] ?? 'Đăng ký thất bại';
      });
    }
  }

  void showOtpDialog(String email) {
    int seconds = 60;
    Timer? timer;
    otpCtrl.clear();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) {
        return StatefulBuilder(
          builder: (dialogContext, setState) {
            timer ??= Timer.periodic(const Duration(seconds: 1), (t) {
              if (seconds > 0) {
                setState(() => seconds--);
              } else {
                t.cancel();
              }
            });

            return AlertDialog(
              title: const Text(
                'Nhập mã OTP đã gửi đến email của bạn',
                style: TextStyle(fontSize: 16),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Hiệu lực: $seconds giây'),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: otpCtrl,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Nhập OTP',
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      ElevatedButton(
                        onPressed: seconds == 0
                            ? () async {
                                final res = await ApiService.resendOtp(email);
                                if (!mounted) return;
                                if (res['success']) {
                                  setState(() => seconds = 60);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Đã gửi lại mã OTP.'),
                                    ),
                                  );
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        res['message'] ??
                                            'Không thể gửi lại OTP',
                                      ),
                                    ),
                                  );
                                }
                              }
                            : null,
                        child: const Text('Gửi lại'),
                      ),
                    ],
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () async {
                    final res = await ApiService.verifyOtp(email, otpCtrl.text);
                    if (!mounted) return;

                    if (res['success']) {
                      timer?.cancel();
                      Navigator.of(dialogContext).pop(); // Đóng OTP dialog

                      // Mở dialog thành công
                      showDialog(
                        context: context,
                        builder: (successDialogContext) => AlertDialog(
                          title: const Text('🎉 Thành công'),
                          content: const Text('Đăng ký thành công!'),
                          actions: [
                            TextButton(
                              onPressed: () {
                                Navigator.of(
                                  successDialogContext,
                                ).pop(); // đóng dialog
                                context.goNamed('login'); // chuyển về login
                              },
                              child: const Text('OK'),
                            ),
                          ],
                        ),
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(res['message'] ?? 'OTP không hợp lệ'),
                        ),
                      );
                    }
                  },
                  child: const Text('Xác nhận'),
                ),
                TextButton(
                  onPressed: () {
                    timer?.cancel();
                    Navigator.of(dialogContext).pop(); // Đóng OTP dialog
                  },
                  child: const Text('Hủy'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return FrameScreen(
      showAppBar: false,
      showDefaultBottomBar: false,
      body: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 24),
        color: Colors.black,
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 60),
              const Icon(Icons.person_add_alt_1, color: Colors.white, size: 72),
              const SizedBox(height: 24),
              const Text(
                'Đăng ký',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 32),
              TextField(
                controller: fullnameCtrl,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Họ và tên',
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
              TextField(
                controller: confirmPasswordCtrl,
                obscureText: true,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Xác nhận mật khẩu',
                  hintStyle: const TextStyle(color: Colors.grey),
                  filled: true,
                  fillColor: Colors.grey.shade900,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              isLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: register,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Đăng ký',
                          style: TextStyle(fontSize: 16, color: Colors.white),
                        ),
                      ),
                    ),
              const SizedBox(height: 12),
              if (resultMessage.isNotEmpty)
                Text(
                  resultMessage,
                  style: const TextStyle(color: Colors.redAccent),
                ),
              const SizedBox(height: 32),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'Đã có tài khoản?',
                    style: TextStyle(color: Colors.white70),
                  ),
                  TextButton(
                    onPressed: () {
                      context.goNamed('login');
                    },
                    child: const Text('Đăng nhập'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

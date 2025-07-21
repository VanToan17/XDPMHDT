import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../api_service.dart';
import '../frame_Screen.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final emailCtrl = TextEditingController();
  final otpCtrl = TextEditingController();
  final newPasswordCtrl = TextEditingController();
  final confirmCtrl = TextEditingController();

  int seconds = 60;
  Timer? timer;
  String message = '';
  bool loading = false;

  Future<void> sendOtp() async {
    setState(() {
      loading = true;
      message = '';
    });

    final res = await ApiService.sendForgotPasswordOtp(emailCtrl.text.trim());

    setState(() => loading = false);

    if (res['success']) {
      showOtpDialog();
    } else {
      setState(() => message = res['message'] ?? 'Lỗi gửi OTP');
    }
  }

  Future<void> resendOtp() async {
    final res = await ApiService.resendForgotOtp(emailCtrl.text.trim());
    if (res['success']) {
      setState(() => seconds = 60);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đã gửi lại mã OTP mới, hiệu lực 60s')),
      );
    }
  }

  void showOtpDialog() {
    seconds = 60;
    otpCtrl.clear();

    late void Function(void Function()) localSetState;

    timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) {
        t.cancel();
        return;
      }
      if (seconds > 0) {
        seconds--;
        localSetState(() {});
      } else {
        t.cancel();
      }
    });

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            localSetState = setStateDialog;
            return AlertDialog(
              title: const Text('Nhập mã OTP đã gửi đến email (hiệu lực 60s)'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: otpCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Mã OTP'),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(child: Text('Còn $seconds giây')),
                      TextButton(
                        onPressed: seconds == 0 ? resendOtp : null,
                        child: const Text('Gửi lại'),
                      ),
                    ],
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () async {
                    final res = await ApiService.verifyForgotOtp(
                      emailCtrl.text.trim(),
                      otpCtrl.text,
                    );
                    if (!mounted) return;

                    if (res['success']) {
                      Navigator.pop(context);
                      timer?.cancel();
                      showResetPasswordDialog();
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(res['message'] ?? 'OTP sai')),
                      );
                    }
                  },
                  child: const Text('Xác nhận'),
                ),
                TextButton(
                  onPressed: () {
                    timer?.cancel();
                    Navigator.pop(context);
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

  void showResetPasswordDialog() {
    newPasswordCtrl.clear();
    confirmCtrl.clear();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: const Text('Tạo mật khẩu mới'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: newPasswordCtrl,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Mật khẩu mới'),
            ),
            TextField(
              controller: confirmCtrl,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Xác nhận mật khẩu'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () async {
              final res = await ApiService.updateNewPassword(
                email: emailCtrl.text.trim(),
                password: newPasswordCtrl.text,
                confirm: confirmCtrl.text,
              );

              if (!mounted) return;

              if (res['success']) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Đặt lại mật khẩu thành công')),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(res['message'] ?? 'Lỗi đổi mật khẩu')),
                );
              }
            },
            child: const Text('Đổi mật khẩu'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    timer?.cancel();
    emailCtrl.dispose();
    otpCtrl.dispose();
    newPasswordCtrl.dispose();
    confirmCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FrameScreen(
      showAppBar: false,
      showDefaultBottomBar: false,
      body: SafeArea(
        child: Container(
          color: Colors.black,
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Center(
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.lock_reset, color: Colors.white, size: 72),
                  const SizedBox(height: 24),
                  const Text(
                    'Khôi phục mật khẩu',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 32),
                  TextField(
                    controller: emailCtrl,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'Email của bạn',
                      hintStyle: const TextStyle(color: Colors.grey),
                      filled: true,
                      fillColor: Colors.grey.shade900,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  loading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: sendOtp,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text(
                              'Gửi mã OTP',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.white,
                              ),
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
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        'Đã nhớ mật khẩu?',
                        style: TextStyle(color: Colors.white70),
                      ),
                      TextButton(
                        onPressed: () => context.goNamed('login'),
                        child: const Text('Đăng nhập'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

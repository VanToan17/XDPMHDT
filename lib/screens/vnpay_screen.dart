import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import 'package:go_router/go_router.dart';
import 'package:project_group_9/widgets/user_session.dart';
import 'package:project_group_9/frame_Screen.dart';
import 'package:android_intent_plus/android_intent.dart';
import 'package:flutter/services.dart';

class PaymentPage extends StatefulWidget {
  const PaymentPage({super.key});

  @override
  State<PaymentPage> createState() => _PaymentPageState();
}

class _PaymentPageState extends State<PaymentPage> {
  bool _loading = false;
  String? _errorMessage;
  final int amount = 100000;

  @override
  void initState() {
    super.initState();

    Future.microtask(() async {
      final session = UserSession.of(context);
      if (session.userId == null) {
        context.goNamed("login");
        return;
      }
      await checkVipStatus();
    });
  }

  Future<void> checkVipStatus() async {
    final session = UserSession.of(context);
    if (session.userId == null) return;

    try {
      final url = Uri.parse(
        "http://10.0.2.2:8000/api_handle/vnpay_api_handle/get_user_info.php?id=${session.userId}",
      );
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true && data['user'] != null) {
          final isVip = data['user']['vip'] == true;
          if (isVip) {
            context.goNamed('success');
          }
        }
      }
    } catch (_) {}
  }

  // ✅ Mở URL bằng Chrome nếu có, fallback nếu không
  Future<void> _openUrlWithChrome(String url) async {
    final uri = Uri.parse(url);

    if (Platform.isAndroid) {
      try {
        final intent = AndroidIntent(
          action: 'android.intent.action.VIEW',
          data: url,
          package: 'com.android.chrome',
        );
        await intent.launch();
        return;
      } catch (e) {
        print("⚠️ Chrome không có sẵn, fallback sang trình duyệt mặc định...");
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        } else {
          setState(() {
            _errorMessage = "Không thể mở trình duyệt nào.";
          });
        }
      }
    } else {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        setState(() {
          _errorMessage = "Không thể mở trình duyệt.";
        });
      }
    }
  }

  Future<void> _createPayment() async {
    final session = UserSession.of(context);
    if (session.userId == null) return;

    setState(() {
      _loading = true;
      _errorMessage = null;
    });

    try {
      final url = Uri.parse(
        "http://10.0.2.2:8000/api_handle/vnpay_api_handle/create_payment.php",
      );
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"userId": session.userId, "amount": amount}),
      );

      final data = jsonDecode(response.body);
      if (response.statusCode == 200 &&
          data['code'] == '00' &&
          data['paymentUrl'] != null) {
        final paymentUrl = data['paymentUrl'];
        print("🔗 URL thanh toán: $paymentUrl");
        await _openUrlWithChrome(paymentUrl);
      } else {
        throw Exception(data['message'] ?? "Không thể tạo thanh toán");
      }
    } catch (e) {
      setState(() {
        _errorMessage = "❌ Lỗi: ${e.toString()}";
      });
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final session = UserSession.of(context);
    final amountFormatted =
        "${amount.toString().replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (match) => '.')} đ";

    return FrameScreen(
      title: "Thanh toán VIP",
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Center(
          child: _loading
              ? const CircularProgressIndicator()
              : Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text("🔒 Bạn sắp thanh toán gói VIP với giá:"),
                    const SizedBox(height: 12),
                    Text(
                      amountFormatted,
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.payment),
                      label: const Text("Tiến hành thanh toán"),
                      onPressed: _createPayment,
                    ),
                    const SizedBox(height: 24),
                    const Divider(),
                    // Text("🆔 ID: ${session.userId ?? 'null'}"),
                    Text("📧 Email: ${session.email ?? 'null'}"),
                    if (_errorMessage != null) ...[
                      const SizedBox(height: 20),
                      Text(
                        _errorMessage!,
                        style: const TextStyle(color: Colors.red),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ],
                ),
        ),
      ),
    );
  }
}

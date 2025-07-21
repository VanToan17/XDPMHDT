import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class PaymentSuccessScreen extends StatelessWidget {
  const PaymentSuccessScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Thanh toán thành công")),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                "🎉 Bạn đã nâng cấp VIP thành công!",
                style: TextStyle(fontSize: 24, color: Colors.green),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              ElevatedButton.icon(
                icon: const Icon(Icons.home),
                label: const Text("Quay về trang chủ"),
                onPressed: () {
                  context.goNamed("home"); // 🔁 Tên route bạn đã đặt cho trang chủ
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

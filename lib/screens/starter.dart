import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class StarterScreen extends StatefulWidget {
  const StarterScreen({super.key});

  @override
  State<StarterScreen> createState() => _StarterScreenState();
}

class _StarterScreenState extends State<StarterScreen> {
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        context.go('/home');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Ảnh nền toàn màn hình
          SizedBox(
            width: size.width,
            height: size.height,
            child: Image.asset('assets/intro.gif', fit: BoxFit.cover),
          ),
          // Overlay loading và text
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              // children: const [
              //   CircularProgressIndicator(color: Colors.white),
              //   SizedBox(height: 20),
              //   Text(
              //     'Đang khởi động...',
              //     style: TextStyle(
              //       fontSize: 16,
              //       color: Colors.white, // cho nổi bật trên nền ảnh
              //       fontWeight: FontWeight.bold,
              //     ),
              //   ),
              // ],
            ),
          ),
        ],
      ),
    );
  }
}

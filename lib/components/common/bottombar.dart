import '/app.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class BottomBar extends StatelessWidget {
  final int currentIndex; // ĐÃ THÊM

  const BottomBar({
    super.key,
    required this.currentIndex, // ĐÃ THÊM
  });

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: currentIndex, // ĐÃ THÊM
      backgroundColor: Colors.black,
      selectedItemColor: const Color(0xFF7fff00),
      unselectedItemColor: Colors.white54,
      onTap: (index) {
        switch (index) {
          case 0:
            context.go('/');
            break;
          case 1:
            context.go('/search');
            break;
          case 2:
            context.go('/profile');
            break;
        }
      },
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Trang chủ'),
        BottomNavigationBarItem(icon: Icon(Icons.search), label: 'Tìm kiếm'),
        BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Tài khoản'),
      ],
    );
  }
}

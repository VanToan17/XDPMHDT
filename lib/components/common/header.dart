import 'package:flutter/material.dart';

PreferredSizeWidget header({required String title, List<Widget>? actions,}) {
  return AppBar(
    backgroundColor: Colors.black,
    elevation: 0,
    title: Text(
      title,
      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
    ),
    actions: actions ?? [
      IconButton(
        icon: const Icon(Icons.search, color: Colors.white),
        onPressed: () {
          // Mở trang tìm kiếm
        },
      ),
      IconButton(
        icon: const Icon(Icons.person, color: Colors.white),
        onPressed: () {
          // Mở profile người dùng
        },
      )
    ],
  );
}

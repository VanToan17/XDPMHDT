import 'package:flutter/material.dart';

Drawer sidebar() {
  return Drawer(
    backgroundColor: Colors.black,
    child: ListView(
      padding: EdgeInsets.zero,
      children: const [
        DrawerHeader(
          decoration: BoxDecoration(color: Colors.amber),
          child: Text(
            'Movie App',
            style: TextStyle(color: Colors.black, fontSize: 24),
          ),
        ),
        ListTile(
          leading: Icon(Icons.home, color: Colors.white),
          title: Text('Trang chủ', style: TextStyle(color: Colors.white)),
        ),
        ListTile(
          leading: Icon(Icons.settings, color: Colors.white),
          title: Text('Cài đặt', style: TextStyle(color: Colors.white)),
        ),
      ],
    ),
  );
}

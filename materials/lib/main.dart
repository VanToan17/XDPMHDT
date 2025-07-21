import 'package:flutter/material.dart';
import 'package:materials/materials.dart';
import 'package:materials/_button/document.dart';
import 'package:materials/_form/document.dart';
import 'package:materials/_image/document.dart';

void main() {
  runApp(const MyDocThemeScreen());
}

class MyDocThemeScreen extends StatelessWidget {
  const MyDocThemeScreen({super.key});
  
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ListView(children: const [
        MyButtonDoc(),
        MyFormDoc(),
        MyImageDoc(),
      ]),
    );
  }
}


import 'package:flutter/material.dart';
import 'package:materials/materials.dart';

class MyImageDoc extends StatelessWidget {
  const MyImageDoc({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MyCodeBlock(
      code: [
        const Text('Images', style: TextStyle(color: Colors.black)),
        MyImage(url: 'assets/images/logo.jpg'),
      ],
    );
  }
}

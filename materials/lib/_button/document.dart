import 'package:flutter/material.dart';
import 'package:materials/materials.dart';

class MyButtonDoc extends StatelessWidget {
  const MyButtonDoc({super.key});
  
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Text('Buttons'),
        MyButton(onPressed: (){}, text: 'Button'),
      ],
    );
  }
}


import 'package:flutter/material.dart';
import 'package:materials/materials.dart';

class MyFormDoc extends StatelessWidget {
  const MyFormDoc({super.key});
  
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return const Column(
      children: [
        Text('Inputs'),
        MyTextField(hintText: 'Input something'),
        Text('Image Picker'),
        MyImageField(width: 50,height: 50),
        Text('Images Picker'),
        MyImagesField(width: 50,height: 50),
      ],
    );
  }
}


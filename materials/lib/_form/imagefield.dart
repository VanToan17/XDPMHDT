// ignore_for_file: prefer_typing_uninitialized_variables

import 'package:flutter/material.dart';
import 'package:materials/materials.dart';

class MyImageField extends StatelessWidget {
  final void Function(String)? onChanged;
  
  final double width;
  final double height;
  final dynamic value;
  const MyImageField(
      {
        super.key,
        this.width = 100,
        this.height = 100,
        this.value,
        this.onChanged,
      });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey)
      ),
      child: MouseRegion(cursor: SystemMouseCursors.click,child: GestureDetector(
        onTap: (){

        },
        child: MyImage(url: value ?? 'placeholder/image.png'),
      ),),
    );
  }
}
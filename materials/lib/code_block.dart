import 'package:flutter/material.dart';
import 'package:materials/materials.dart';

class MyCodeBlock extends StatefulWidget {
  const MyCodeBlock({
    super.key,
    required this.code,
  });
  final List<Widget> code;
  @override
  State<MyCodeBlock> createState() => _MyCodeBlockState();
}
class _MyCodeBlockState extends State<MyCodeBlock> {
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(flex: 1,child: Column(
          children: [
            for(var code in widget.code) 
              Text(code.toString())
          ],
        )),
        Expanded(flex: 1,child: Column(
          children: widget.code.toList(),
        )),
      ],
    );
  }
}


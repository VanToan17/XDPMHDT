import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hexcolor/hexcolor.dart';

class MyImage extends StatefulWidget {
  final Function()? onPressed;
  final String url;
  final double height;
  final double width;
  const MyImage(
      {
        super.key, 
        required this.url,
        this.width = 0,
        this.height = 0, 
        this.onPressed,
      });
  @override
  State<MyImage> createState() =>
      _MyImageState();
}

class _MyImageState  extends State<MyImage>{
  
  @override
  Widget build(BuildContext context) {
    if(Uri.parse(widget.url).isAbsolute){
      return Image.network(
        widget.url,
        width: widget.width > 0 ? widget.width : null,
        height: widget.height > 0 ? widget.height : null,
        errorBuilder: (context, error, stackTrace) {
        // print(error);
        return const Text('');
      });
    }
    return Image.asset(
      widget.url,
      width: widget.width > 0 ? widget.width : null,
      height: widget.height > 0 ? widget.height : null,
    );
  }
}

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hexcolor/hexcolor.dart';
import 'package:materials/materials.dart';

class MyButton extends StatefulWidget {
  final Function()? onPressed;
  final String text;
  final bool loading;
  final double height;
  final double width;
  final double fontSize;
  final EdgeInsets padding;
  final EdgeInsets margin;
  final double borderRadius;
  final Widget icon;
  final Widget suffixIcon;
  final String variant;
  final bool disabled;

  late Color backgroundColor;
  late Color color;
  
  MyButton(
      {
        super.key, required this.onPressed, 
        this.text = '', 
        this.icon = const Text(''),
        this.suffixIcon = const Text(''),
        this.variant = '',
        this.color = Colors.white,
        this.backgroundColor = AppColors.primary, 
        this.loading = false,
        this.width = 500,
        this.height = 45,
        this.margin = const EdgeInsets.fromLTRB(0, 0, 0, 0),
        this.padding = const EdgeInsets.fromLTRB(10, 10, 10, 10),
        this.borderRadius = 10,
        this.fontSize = 18,
        this.disabled = false
      });

  
  @override
  State<MyButton> createState() =>
      _ButtonState();
}

class _ButtonState  extends State<MyButton>{
  late Color color;
  late Color backgroundColor;
  settingVariant(){
      
    switch (widget.variant) {
      case 'primary':
        color = Colors.white;
        backgroundColor = AppColors.primary;
        break;
      case 'light':
        color = Colors.black;
        backgroundColor = AppColors.bgLight;
        break;
      case 'secondary':
        color = Colors.white;
        backgroundColor = AppColors.bgSecondayLight;
        break;
      case 'success':
        color = Colors.white;
        backgroundColor = AppColors.success;
        break;
      case 'danger':
        color = Colors.white;
        backgroundColor = AppColors.danger;
        break;
      case 'warning':
        color = Colors.black;
        backgroundColor = AppColors.warning;
        break;
      case 'info':
        color = Colors.black;
        backgroundColor = const Color.fromRGBO(13, 202, 240,1);
        break;
      default:
        color = widget.color;
        backgroundColor = widget.backgroundColor;
    }
  }
  @override
  Widget build(BuildContext context) {
    settingVariant();
    return Opacity(
      opacity: widget.disabled ? 0.5 : 1,
      child: Container(
        height: widget.height,
        width:widget.width,
        margin: widget.margin,
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.all(0),
            iconColor: color,
            backgroundColor: backgroundColor,
            textStyle: TextStyle(color: color),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(widget.borderRadius)
            ),
          ),
        onPressed: !widget.disabled ?widget.onPressed:null,
        child: Padding(
          padding: widget.padding,
          child: Center(
              child:Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  widget.icon,
                  Text(
                    widget.text,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                      color: color,
                      fontSize: widget.fontSize,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  widget.suffixIcon,
                ]
              )
            ),
              
          ),
        )
      )
    );
  }
}

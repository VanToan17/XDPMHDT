// ignore_for_file: prefer_typing_uninitialized_variables

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hexcolor/hexcolor.dart';

class MyTextField extends StatelessWidget {
  final controller;
  final String hintText;
  final bool obscureText;
  final Icon? prefixIcon;
  final void Function(String)? onChanged;
  final void Function(String)? onSubmitted;
  final void Function()? onEditingComplete;
  final String label;
  final String errorText;
  final TextStyle style;
  const MyTextField(
      {super.key,
      this.controller,
      this.hintText = '',
      this.obscureText = false,
      this.prefixIcon,
      this.onChanged,
      this.onSubmitted,
      this.onEditingComplete,
      this.label = '',
      this.errorText = '',
      this.style = const TextStyle()
    });

  @override
  Widget build(BuildContext context) {
    var controller1 = TextEditingController();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if(label.isNotEmpty) Container(
          margin: const EdgeInsets.only(top: 7,bottom: 6),
          child: Text(label)
        ),
        TextField(
          controller: controller,
          obscureText: obscureText,
          cursorColor: HexColor("#4f4f4f"),
          style: style,
          onChanged: onChanged ?? (str){},
          onTapOutside: (event) {
            print('onTapOutside');
            FocusManager.instance.primaryFocus?.unfocus();
          },
          onSubmitted: (value){
            if(onSubmitted != null) onSubmitted!(value);
          },
          onEditingComplete: (){
            if(onEditingComplete != null) onEditingComplete!();
          },
          decoration: InputDecoration(
            hintText: hintText,
            fillColor: HexColor("#f0f3f1"),
            // contentPadding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
            
            hintStyle: GoogleFonts.poppins(
              fontSize: 13,
              color: HexColor("#8d8d8d"),
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(3),
              borderSide: BorderSide.none,
            ),
            prefixIcon: prefixIcon,
            prefixIconColor: HexColor("#4f4f4f"),
            filled: true,
            errorText: errorText.isNotEmpty ? errorText.toString() : '',
          ),
        )
      ],
    );
  }
}
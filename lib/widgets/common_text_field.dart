import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class CommonTextFormField extends StatelessWidget {
  const CommonTextFormField(
      {this.labelText = '',
      this.isRequired = true,
      this.autofocus = false,
      this.formWidth,
      this.controller,
      this.labelWidth = 70,
      this.validator,
      this.inputFormatters,
      this.suffix,
      this.suffixIcon,
      this.isPassword = false,
      this.maxLength,
      super.key});

  final String labelText;
  final bool isRequired;
  final bool autofocus;
  final double? formWidth;
  final TextEditingController? controller;
  final double labelWidth;
  final String? Function(String?)? validator;
  final List<TextInputFormatter>? inputFormatters;
  final Widget? suffix;
  final Widget? suffixIcon;
  final bool isPassword;
  final int? maxLength;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SizedBox(
        width: formWidth,
        child: TextFormField(
          controller: controller,
          autofocus: autofocus,
          obscureText: isPassword,
          maxLength: maxLength,
          decoration: InputDecoration(
            labelText: isRequired ? labelText : '$labelText (选填)',
            suffix: suffix,
            suffixIcon: suffixIcon,
            counterText: '',
          ),
          validator: validator,
          inputFormatters: inputFormatters,
        ),
      ),
    );
  }
}

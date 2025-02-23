import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:animetrace/utils/extensions/color.dart';

class CommonTextFormField extends StatelessWidget {
  const CommonTextFormField(
      {this.labelText = '',
      this.isRequired = true,
      this.autofocus = false,
      this.formWidth,
      this.controller,
      this.labelWidth = 70,
      this.labelDisplayLeft = false,
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
  final bool labelDisplayLeft;
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
        child: Row(
          children: [
            if (labelDisplayLeft)
              SizedBox(width: labelWidth, child: Text(labelText)),
            Expanded(
              child: TextFormField(
                controller: controller,
                autofocus: autofocus,
                obscureText: isPassword,
                maxLength: maxLength,
                decoration: labelDisplayLeft
                    ? null
                    : InputDecoration(
                        labelText: isRequired ? labelText : '$labelText (选填)',
                        suffix: suffix,
                        suffixIcon: suffixIcon,
                        focusedBorder: OutlineInputBorder(
                          borderSide:
                              BorderSide(color: Theme.of(context).primaryColor),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(
                              color: Theme.of(context)
                                  .hintColor
                                  .withOpacityFactor(0.2)),
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                validator: validator,
                inputFormatters: inputFormatters,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

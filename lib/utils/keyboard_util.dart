import 'package:flutter/material.dart';

class KeyboardUtil {
  static void cancelKeyBoard() {
    FocusManager.instance.primaryFocus?.unfocus();
  }
}

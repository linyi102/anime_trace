import 'package:flutter/material.dart';
import 'package:get/get.dart';

class FormValidator {
  static String? checkNotEmpty(String? value) {
    if (value == null) return 'error: null';
    if (value.trim().isEmpty) return '不能为空';
    return null;
  }

  static String? checkIsUrl(String? value) {
    if (value == null) return 'error: null';
    if (value.trim().isEmpty) return '不能为空';
    if (!value.isURL) return '无效链接';
    return null;
  }

  static String? checkPort(String? value) {
    if (value == null) return 'error: null';
    if (value.trim().isEmpty) return '不能为空';
    int? port = int.tryParse(value);
    if (port == null) return '必须为数字';

    if (1 <= port && port <= 65535) {
      return null;
    } else {
      return 'port范围：[1, 65535]';
    }
  }

  static bool isValid(GlobalKey formKey) {
    return (formKey.currentState as FormState).validate();
  }

  static bool isInvalid(GlobalKey formKey) {
    return !isValid(formKey);
  }
}

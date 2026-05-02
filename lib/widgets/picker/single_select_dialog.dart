import 'package:flutter/material.dart';

class SingleSelectDialog<T> extends StatelessWidget {
  final Widget title;
  final T value;
  final List<T> options;
  final Widget Function(T) labelBuilder;

  Future<T?> show(BuildContext context) {
    return showDialog<T>(
      context: context,
      builder: (BuildContext context) {
        return SingleSelectDialog<T>(
          title: title,
          value: value,
          options: options,
          labelBuilder: labelBuilder,
        );
      },
    );
  }

  const SingleSelectDialog({
    Key? key,
    required this.title,
    required this.value,
    required this.options,
    required this.labelBuilder,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SimpleDialog(
      title: title,
      children: options.map((option) {
        return RadioListTile<T>(
          title: labelBuilder(option),
          value: option,
          groupValue: value,
          onChanged: (T? value) {
            if (value != null) {
              Navigator.pop(context, value);
            }
          },
        );
      }).toList(),
    );
  }
}

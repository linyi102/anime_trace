import 'package:flutter/material.dart';

class SelectViewAction extends StatelessWidget {
  const SelectViewAction({
    required this.onReset,
    required this.onApply,
    super.key,
  });
  final Function() onReset;
  final Function() onApply;

  @override
  Widget build(BuildContext context) {
    const buttonStyle = ButtonStyle(
        padding:
            MaterialStatePropertyAll(EdgeInsets.symmetric(horizontal: 20)));

    return Container(
      margin: const EdgeInsets.all(12),
      child: Row(
        children: [
          const Spacer(),
          OutlinedButton(
              onPressed: onReset, style: buttonStyle, child: const Text('重置')),
          const SizedBox(width: 10),
          ElevatedButton(
              onPressed: () {
                onApply();
                Navigator.pop(context);
              },
              style: buttonStyle,
              child: const Text('确定')),
        ],
      ),
    );
  }
}

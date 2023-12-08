import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:flutter_test_future/utils/toast_util.dart';

Future<int?> dialogSelectUint(context, String title,
    {int initialValue = 0, int minValue = 0, int maxValue = 1 << 32}) async {
  final editingController = TextEditingController();
  return showDialog(
      context: context,
      builder: (context) => AlertDialog(
              title: Text(title),
              content: NumberControlInputField(
                controller: editingController,
                minValue: minValue,
                maxValue: maxValue,
                initialValue: initialValue,
              ),
              actions: [
                TextButton(
                    onPressed: () {
                      Navigator.pop(context, initialValue); // 取消了则返回默认值
                    },
                    child: const Text("取消")),
                TextButton(
                    onPressed: () {
                      String content = editingController.text;
                      if (content.isEmpty) {
                        ToastUtil.showText("不能为空！");
                        return;
                      }
                      int number = int.parse(content);
                      if (number < minValue || number > maxValue) {
                        ToastUtil.showText("设置范围：[$minValue, $maxValue]");
                        return;
                      }
                      Navigator.pop(context, number);
                    },
                    child: const Text("确定")),
              ]));
}

class NumberControlInputField extends StatefulWidget {
  const NumberControlInputField(
      {super.key,
      required this.controller,
      this.minValue = 0,
      this.maxValue = 1 << 32,
      required this.initialValue});
  final TextEditingController controller;
  final int minValue, maxValue;
  final int initialValue;

  @override
  State<NumberControlInputField> createState() =>
      _NumberControlInputFieldState();
}

class _NumberControlInputFieldState extends State<NumberControlInputField> {
  late int tmpValue = widget.initialValue;
  get minValue => widget.minValue;
  get maxValue => widget.maxValue;
  double get radius => 8;
  FocusNode blankFocusNode = FocusNode();

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        TextField(
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly, // 数字，只能是整数
          ],
          keyboardType: TextInputType.number,
          textAlign: TextAlign.center,
          controller: widget.controller..text = tmpValue.toString(),
          onChanged: (value) {
            int? willValue = int.tryParse(value);
            if (willValue == null) return;

            tmpValue = willValue;
            if (tmpValue < minValue) tmpValue = minValue;
            if (tmpValue > maxValue) tmpValue = maxValue;
          },
          decoration: InputDecoration(
            prefixIcon: _buildControlButton(
              action: NumberAction.subtract,
              onTap: _subtractNumber,
            ),
            suffixIcon: _buildControlButton(
              action: NumberAction.add,
              onTap: _addNumber,
            ),
            prefixIconConstraints: BoxConstraints.tight(const Size(32, 48)),
            suffixIconConstraints: BoxConstraints.tight(const Size(32, 48)),
            focusedBorder: _buildBorder(isFocused: true),
            enabledBorder: _buildBorder(),
            isDense: true,
          ),
        ),
        const SizedBox(height: 5),
        Text(
          "范围：[$minValue, $maxValue]",
          style: TextStyle(
            color: Theme.of(context).hintColor,
            fontSize: 12,
          ),
        )
      ],
    );
  }

  void _addNumber() {
    FocusScope.of(context).requestFocus(blankFocusNode);

    tmpValue++;
    if (tmpValue < minValue) tmpValue = minValue;
    if (tmpValue > maxValue) tmpValue = maxValue;
    setState(() {});
  }

  void _subtractNumber() {
    FocusScope.of(context).requestFocus(blankFocusNode);

    tmpValue--;
    if (tmpValue < minValue) tmpValue = minValue;
    if (tmpValue > maxValue) tmpValue = maxValue;
    setState(() {});
  }

  _buildBorder({bool isFocused = false}) {
    return OutlineInputBorder(
        borderRadius: BorderRadius.circular(radius),
        borderSide: BorderSide(
          color: isFocused
              ? Theme.of(context).primaryColor
              : Theme.of(context).hintColor.withOpacity(0.1),
          width: 2.0,
        ));
  }

  _buildControlButton({void Function()? onTap, required NumberAction action}) {
    BorderRadius? borderRadius = BorderRadius.horizontal(
      left: action == NumberAction.subtract
          ? Radius.circular(radius)
          : Radius.zero,
      right: action == NumberAction.add ? Radius.circular(radius) : Radius.zero,
    );

    return InkWell(
        borderRadius: borderRadius,
        onTap: onTap,
        // 避免长按穿透，聚焦到输入框
        onLongPress: () {},
        splashFactory: NoSplash.splashFactory,
        child: Container(
            decoration: BoxDecoration(
                color: Theme.of(context).hintColor.withOpacity(0.05),
                borderRadius: borderRadius),
            child: Icon(
              action == NumberAction.subtract
                  ? Icons.chevron_left
                  : Icons.chevron_right,
              color: Theme.of(context).hintColor,
              size: 20,
            )));
  }
}

enum NumberAction {
  add,
  subtract,
}

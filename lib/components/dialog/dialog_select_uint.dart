import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:animetrace/utils/toast_util.dart';

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
  const NumberControlInputField({
    super.key,
    required this.controller,
    this.minValue = 0,
    this.maxValue = 1 << 32,
    required this.initialValue,
    this.onChanged,
    this.showRangeHintText = true,
  });
  final TextEditingController controller;
  final int minValue, maxValue;
  final int initialValue;
  final void Function(int? number)? onChanged;
  final bool showRangeHintText;

  @override
  State<NumberControlInputField> createState() =>
      _NumberControlInputFieldState();
}

class _NumberControlInputFieldState extends State<NumberControlInputField> {
  late int tmpValue = widget.initialValue;
  get minValue => widget.minValue;
  get maxValue => widget.maxValue;
  get radius => 8.0;
  get numberRangeHint => "范围：[$minValue, $maxValue]";
  FocusNode blankFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    widget.controller.text = '${widget.initialValue}';
  }

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
          controller: widget.controller,
          onChanged: (value) {
            int? willValue = int.tryParse(value);
            if (willValue == null) return;

            tmpValue = willValue;
            if (tmpValue < minValue) tmpValue = minValue;
            if (tmpValue > maxValue) tmpValue = maxValue;
            widget.onChanged?.call(tmpValue);
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
            prefixIconConstraints: BoxConstraints.tight(const Size(36, 48)),
            suffixIconConstraints: BoxConstraints.tight(const Size(36, 48)),
            // helperText: numberRangeHint,
            focusedBorder: _buildBorder(isFocused: true),
            enabledBorder: _buildBorder(),
            isDense: true,
          ),
        ),
        if (widget.showRangeHintText)
          Padding(
            padding: const EdgeInsets.only(top: 5),
            child: Text(
              numberRangeHint,
              style: TextStyle(
                color: Theme.of(context).hintColor,
                fontSize: 12,
              ),
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

    widget.controller.text = '$tmpValue';
    widget.onChanged?.call(tmpValue);
    setState(() {});
  }

  void _subtractNumber() {
    FocusScope.of(context).requestFocus(blankFocusNode);

    tmpValue--;
    if (tmpValue < minValue) tmpValue = minValue;
    if (tmpValue > maxValue) tmpValue = maxValue;

    widget.controller.text = '$tmpValue';
    widget.onChanged?.call(tmpValue);
    setState(() {});
  }

  _buildBorder({bool isFocused = false}) {
    return OutlineInputBorder(
        borderRadius: BorderRadius.circular(radius),
        borderSide: BorderSide(
          color: isFocused
              ? Theme.of(context).colorScheme.primary
              : Theme.of(context).dividerColor,
          width: 1.0,
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
        child: Icon(
          action == NumberAction.subtract ? Icons.remove : Icons.add,
          color: Theme.of(context).hintColor,
          size: 20,
        ));
  }
}

enum NumberAction {
  add,
  subtract,
}

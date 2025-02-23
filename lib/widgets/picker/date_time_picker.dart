import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test_future/utils/extensions/color.dart';
import 'package:flutter_test_future/widgets/bottom_sheet.dart';
import 'package:flutter_test_future/widgets/picker/flutter_picker_fix_mouse_scroll.dart';

const _pickerHeight = 240.0;
const _headerHeight = 60.0;
const _itemExtent = 40.0;
const _fadeHeight = _itemExtent * 1.5;
const _selectedItemHeight = _itemExtent;
Color _bg(BuildContext context) => Theme.of(context).scaffoldBackgroundColor;

Future<DateTime?> showCommonDateTimePicker({
  required BuildContext context,
  int minYear = 1970,
  int? maxYear,
  DateTime? initialValue,
  int type = PickerDateTimeType.kYMDHM,
}) async {
  maxYear = maxYear ?? DateTime.now().year + 100;
  DateTime? selectedDt;

  final picker = Picker(
    cancelText: '取消',
    confirmText: '确定',
    height: _pickerHeight,
    itemExtent: _itemExtent,
    diameterRatio: 100,
    squeeze: 1,
    onBuilderItem: (context, text, child, selected, col, index) => Text(
      text ?? '',
      style: TextStyle(
        fontWeight: selected ? FontWeight.w600 : null,
        fontSize: 17,
        color: selected
            ? Theme.of(context).textTheme.titleMedium?.color
            : Theme.of(context).hintColor,
      ),
    ),
    selectionOverlay: const SizedBox(),
    backgroundColor: _bg(context),
    builderHeader: _buildHeader,
    adapter: DateTimePickerAdapter(
      type: type,
      isNumberMonth: true,
      yearSuffix: ' 年',
      monthSuffix: ' 月',
      daySuffix: ' 日',
      hourSuffix: ' 时',
      minuteSuffix: ' 分',
      yearBegin: minYear,
      yearEnd: maxYear,
      value: initialValue,
    ),
    onConfirm: (picker, selected) {
      switch (type) {
        case PickerDateTimeType.kYMDHM:
          selectedDt = DateTime(
            selected[0] + minYear,
            selected[1] + 1,
            selected[2] + 1,
            selected[3],
            selected[4],
          );
          break;
        case PickerDateTimeType.kYMD:
          selectedDt = DateTime(
            selected[0] + minYear,
            selected[1] + 1,
            selected[2] + 1,
          );
          break;
        default:
          throw UnimplementedError('暂未实现其他日期时间类型');
      }
    },
  );
  await showCommonModalBottomSheet(
    context: context,
    backgroundColor: _bg(context),
    builder: (context) => Stack(
      alignment: Alignment.center,
      children: [
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 10),
          child: picker.makePicker(),
        ),
        _buildSelectedIndicator(context),
        _buildTopGradientLayer(context),
        _buildBottomGradientLayer(context),
      ],
    ),
  );

  return selectedDt;
}

Container _buildHeader(BuildContext context) {
  // 注意：自定义标头无法放在showModal的builder里，因为这样PickerWidget.of(context)会得到null
  return Container(
    color: _bg(context),
    height: _headerHeight,
    child: Row(
      children: [
        TextButton(
          onPressed: () => PickerWidget.of(context).data.doCancel(context),
          child:
              Text('取消', style: TextStyle(color: Theme.of(context).hintColor)),
        ),
        const Expanded(
            child: Center(
          child: Text('选择时间',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        )),
        TextButton(
          onPressed: () => PickerWidget.of(context).data.doConfirm(context),
          child: const Text('确定'),
        ),
      ],
    ),
  );
}

Positioned _buildBottomGradientLayer(BuildContext context) {
  return Positioned(
    bottom: 0,
    child: IgnorePointer(
      ignoring: true,
      child: Container(
        height: _fadeHeight,
        width: MediaQuery.of(context).size.width,
        decoration: BoxDecoration(
            gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            _bg(context).withOpacityFactor(0),
            _bg(context),
          ],
        )),
      ),
    ),
  );
}

Positioned _buildTopGradientLayer(BuildContext context) {
  return Positioned(
    top: _headerHeight,
    child: IgnorePointer(
      ignoring: true,
      child: Container(
        height: _fadeHeight,
        width: MediaQuery.of(context).size.width,
        decoration: BoxDecoration(
            gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            _bg(context),
            _bg(context).withOpacityFactor(0),
          ],
        )),
      ),
    ),
  );
}

IgnorePointer _buildSelectedIndicator(BuildContext context) {
  return IgnorePointer(
    ignoring: true,
    child: Container(
      margin: const EdgeInsets.fromLTRB(16, _headerHeight, 16, 0),
      decoration: BoxDecoration(
        color: CupertinoColors.tertiarySystemFill,
        borderRadius: BorderRadius.circular(8),
      ),
      height: _selectedItemHeight,
      width: MediaQuery.of(context).size.width,
    ),
  );
}

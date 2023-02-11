import 'package:flutter/material.dart';
import 'package:flutter_test_future/components/clear_button.dart';

class SearchAppBar extends StatelessWidget implements PreferredSizeWidget {
  const SearchAppBar(
      {this.inputController,
      this.onChanged,
      this.onEditingComplete,
      this.autofocus = true,
      this.hintText = "搜索",
      this.onTapClear,
      this.useModernStyle = true,
      this.isAppBar = true,
      super.key});
  final void Function()? onEditingComplete;
  final void Function(String)? onChanged;
  final bool autofocus;
  final TextEditingController? inputController;
  final void Function()? onTapClear;
  final String hintText;

  final bool useModernStyle;
  final bool isAppBar;

  @override
  Widget build(BuildContext context) {
    if (isAppBar) {
      return AppBar(
        automaticallyImplyLeading: useModernStyle ? false : true,
        actions: useModernStyle ? [_buildCancelButton(context)] : null,
        title: _buildSearchField(context),
      );
    } else {
      return _buildSearchField(context);
    }
  }

  TextField _buildSearchField(BuildContext context) {
    return TextField(
      // 自动弹出键盘
      autofocus: autofocus,
      controller: inputController,
      decoration: _generateInputDecoration(),
      onEditingComplete: () {
        if (onEditingComplete != null) {
          onEditingComplete!();
        }
        _cancelFocus(context);
      },
      onChanged: onChanged,
    );
  }

  InputDecoration _generateInputDecoration() {
    return InputDecoration(
        prefixIcon: useModernStyle ? const Icon(Icons.search) : null,
        contentPadding: useModernStyle ? const EdgeInsets.all(0) : null,
        filled: useModernStyle ? true : false,
        focusedBorder: useModernStyle
            ? const OutlineInputBorder(
                borderSide: BorderSide(color: Colors.transparent),
                borderRadius: BorderRadius.all(Radius.circular(100)),
              )
            : null,
        enabledBorder: useModernStyle
            ? const OutlineInputBorder(
                borderSide: BorderSide(color: Colors.transparent),
                borderRadius: BorderRadius.all(Radius.circular(100)),
              )
            : null,
        hintText: hintText,
        border: InputBorder.none,
        suffixIcon: ClearButton(onTapClear: onTapClear));
  }

  _buildCancelButton(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(6),
      onTap: () {
        Navigator.pop(context);
      },
      child: Container(
          padding: const EdgeInsets.only(left: 10, right: 10),
          child: const Center(child: Text("取消"))),
    );
  }

  // 取消键盘聚焦
  _cancelFocus(context) {
    FocusNode blankFocusNode = FocusNode(); // 空白焦点
    FocusScope.of(context).requestFocus(blankFocusNode); // 焦点传给空白焦点
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

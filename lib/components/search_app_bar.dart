import 'package:flutter/material.dart';

class SearchAppBar extends StatelessWidget implements PreferredSizeWidget {
  const SearchAppBar(
      {this.inputController,
      this.onChanged,
      this.onEditingComplete,
      this.autofocus = true,
      this.hintText = "搜索",
      this.onTapClear,
      this.showCancelButton = false,
      this.onTapCancelButton,
      this.isAppBar = true,
      this.automaticallyImplyLeading = true,
      this.bottom,
      super.key});
  final void Function()? onEditingComplete;
  final void Function(String)? onChanged;
  final void Function()? onTapCancelButton;
  final bool autofocus;
  final TextEditingController? inputController;
  final void Function()? onTapClear;
  final String hintText;

  final bool automaticallyImplyLeading;
  final bool showCancelButton;
  final bool isAppBar;

  /// isAppBar为true时才会有bottom
  final PreferredSizeWidget? bottom;

  @override
  Widget build(BuildContext context) {
    if (isAppBar) {
      return AppBar(
        automaticallyImplyLeading: automaticallyImplyLeading,
        actions: showCancelButton ? [_buildCancelButton(context)] : null,
        title: _buildSearchField(context),
        bottom: bottom,
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
      decoration: _generateInputDecoration(context),
      onEditingComplete: () {
        if (onEditingComplete != null) {
          onEditingComplete!();
        }
        _cancelFocus(context);
      },
      onChanged: onChanged,
    );
  }

  _generateInputDecoration(BuildContext context) {
    return InputDecoration(
        filled: false,
        hintText: hintText,
        suffixIcon: inputController == null
            ? null
            : ValueListenableBuilder(
                valueListenable: inputController!,
                builder: (context, value, child) {
                  if (value.text.isEmpty) return const SizedBox.shrink();
                  return IconButton(
                    onPressed: onTapClear,
                    icon: const Icon(Icons.close, size: 18),
                  );
                },
              ));
  }

  Widget _buildCancelButton(BuildContext context) {
    return TextButton(onPressed: onTapCancelButton, child: const Text('取消'));
  }

  // 取消键盘聚焦
  _cancelFocus(context) {
    FocusNode blankFocusNode = FocusNode(); // 空白焦点
    FocusScope.of(context).requestFocus(blankFocusNode); // 焦点传给空白焦点
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

import 'package:flutter/material.dart';
import 'package:flutter_test_future/utils/tags.dart';

dialogSelectTag(state, context, originTag) {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      List<Widget> radioList = [];
      for (int i = 0; i < tags.length; ++i) {
        radioList.add(
          ListTile(
            title: Text(tags[i]),
            leading: tags[i] == originTag
                ? const Icon(
                    Icons.radio_button_on_outlined,
                    color: Colors.blue,
                  )
                : const Icon(
                    Icons.radio_button_off_outlined,
                  ),
            onTap: () {
              // 没有效果，并不会更新修改动漫对话框中的标签
              originTag = tags[i];
              state(() {});
              Navigator.pop(context);
            },
          ),
        );
      }
      return AlertDialog(
        title: const Text('选择标签'),
        content: AspectRatio(
          aspectRatio: 0.9 / 1,
          child: ListView(
            children: radioList,
          ),
        ),
      );
    },
  );
}

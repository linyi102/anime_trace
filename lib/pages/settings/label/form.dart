import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test_future/controllers/labels_controller.dart';
import 'package:flutter_test_future/dao/label_dao.dart';
import 'package:flutter_test_future/models/label.dart';
import 'package:flutter_test_future/pages/settings/label/home.dart';
import 'package:flutter_test_future/utils/log.dart';
import 'package:flutter_test_future/utils/platform.dart';
import 'package:flutter_test_future/utils/regexp.dart';
import 'package:flutter_test_future/utils/toast_util.dart';
import 'package:flutter/foundation.dart' as foundation;

class LabelForm extends StatefulWidget {
  const LabelForm(
      {super.key, this.label, this.onUpdate, this.searchKeyword = ''});
  final String searchKeyword;
  final Label? label;
  final void Function(String newLabelName)? onUpdate;

  @override
  State<LabelForm> createState() => _LabelFormState();
}

class _LabelFormState extends State<LabelForm> {
  String? emoji;
  var inputLabelNameController = TextEditingController();

  late bool addAction = widget.label == null;
  late bool updateAction = !addAction;

  @override
  void initState() {
    super.initState();
    if (updateAction) {
      emoji = RegexpUtil.extractFirstEmoji(widget.label?.name ?? '');
      if (emoji != null) {
        inputLabelNameController.text =
            widget.label?.name.replaceFirst(emoji!, '').trim() ?? '';
      } else {
        inputLabelNameController.text = widget.label?.name ?? '';
      }
    }
  }

  @override
  void dispose() {
    inputLabelNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text("${addAction ? "添加" : "修改"}标签"),
      content: Row(
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(6),
            child: Container(
              height: 36,
              width: 36,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(6),
                color: Theme.of(context).hintColor.withOpacity(0.06),
              ),
              child: emoji == null
                  ? Icon(
                      Icons.tag,
                      color: Theme.of(context).hintColor,
                      size: 20,
                    )
                  : Center(
                      child: Text(
                      emoji ?? '',
                      style: const TextStyle(fontSize: 18),
                    )),
            ),
            onTap: () {
              _showEmojiPicker(
                onEmojiSelected: (emoji) {
                  Navigator.pop(context);
                  this.emoji = emoji;
                  setState(() {});
                },
              );
            },
          ),
          const SizedBox(width: 15),
          Expanded(
            child: TextField(
              controller: inputLabelNameController,
              autofocus: true,
              decoration:
                  const InputDecoration(counterText: '', hintText: '标签名'),
              maxLength: LabelManagePage.labelMaxLength,
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: const Text("取消")),
        TextButton(
            onPressed: () async {
              String labelName = inputLabelNameController.text;
              // 禁止空
              if (labelName.isEmpty) {
                ToastUtil.showText('不能添加空标签');
                setState(() {});
                return;
              }

              if (emoji != null) labelName = '$emoji$labelName';

              // 没有修改
              if (updateAction && labelName == widget.label?.name) {
                Navigator.pop(context);
                return;
              }

              // 禁止重名
              if (await LabelDao.existLabelName(labelName)) {
                ToastUtil.showText('已有该标签');
                setState(() {});
                return;
              }

              if (updateAction) {
                widget.onUpdate?.call(labelName);
                return;
              }

              Label newLabel = Label(0, labelName);
              int newId = await LabelDao.insert(newLabel);
              if (newId > 0) {
                Log.info("添加标签成功，新插入的id=$newId");
                // 指定新id，并添加到controller中
                newLabel.id = newId;

                LabelsController labelsController = LabelsController.to;
                if (widget.searchKeyword.isEmpty) {
                  // 没在搜索，直接添加
                  labelsController.labels.add(newLabel);
                } else {
                  // 如果在搜索后添加，则看是否存在关键字，如果有，则添加到labels里(此时controller里的labels存放的是搜索结果)
                  if (labelName.contains(widget.searchKeyword)) {
                    labelsController.labels.add(newLabel);
                  }
                }
                Navigator.of(context).pop();
              } else {
                ToastUtil.showText('添加失败');
              }
            },
            child: const Text("确定")),
      ],
    );
  }

  Future<dynamic> _showEmojiPicker(
      {required void Function(String emoji) onEmojiSelected}) {
    return showModalBottomSheet(
      context: context,
      builder: (context) => EmojiPicker(
        onEmojiSelected: (Category? category, Emoji emoji) {
          onEmojiSelected(emoji.emoji);
        },
        config: Config(
          columns: 7,
          emojiSizeMax: 32 *
              (foundation.defaultTargetPlatform == TargetPlatform.iOS
                  ? 1.30
                  : 1.0), // Issue: https://github.com/flutter/flutter/issues/28894
          verticalSpacing: 0,
          horizontalSpacing: 0,
          gridPadding: EdgeInsets.zero,
          initCategory: Category.RECENT,
          bgColor: Theme.of(context).scaffoldBackgroundColor,
          indicatorColor: Theme.of(context).primaryColor,
          iconColor: Colors.grey,
          iconColorSelected: Theme.of(context).primaryColor,
          backspaceColor: Theme.of(context).primaryColor,
          skinToneDialogBgColor: Colors.white,
          skinToneIndicatorColor: Colors.grey,
          enableSkinTones: true,
          recentTabBehavior: RecentTabBehavior.RECENT,
          recentsLimit: 28,
          noRecents: const Text(
            'No Recents',
            style: TextStyle(fontSize: 20, color: Colors.black26),
            textAlign: TextAlign.center,
          ), // Needs to be const Widget
          loadingIndicator: const SizedBox.shrink(), // Needs to be const Widget
          tabIndicatorAnimDuration: PlatformUtil.tabControllerAnimationDuration,
          categoryIcons: const CategoryIcons(),
          buttonMode: ButtonMode.CUPERTINO,
        ),
      ),
    );
  }
}

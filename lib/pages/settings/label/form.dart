import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import 'package:flutter/material.dart';
import 'package:animetrace/controllers/labels_controller.dart';
import 'package:animetrace/dao/label_dao.dart';
import 'package:animetrace/models/label.dart';
import 'package:animetrace/pages/settings/label/home.dart';
import 'package:animetrace/utils/platform.dart';
import 'package:animetrace/utils/toast_util.dart';
import 'package:flutter/foundation.dart' as foundation;
import 'package:animetrace/widgets/bottom_sheet.dart';
import 'package:animetrace/widgets/emoji_leading.dart';

class LabelForm extends StatefulWidget {
  const LabelForm({super.key, this.label, this.onUpdate});
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
      emoji = widget.label?.emoji;
      inputLabelNameController.text = widget.label?.nameWithoutEmoji ?? '';
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
            child: EmojiLeading(emoji: emoji),
            onLongPress: () {
              _cancelEmoji();
            },
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
                return;
              }

              if (updateAction) {
                widget.onUpdate?.call(labelName);
                return;
              } else {
                LabelsController.to.addLabel(labelName);
                Navigator.of(context).pop();
              }
            },
            child: const Text("确定")),
      ],
    );
  }

  _cancelEmoji() {
    setState(() {
      emoji = null;
    });
  }

  Future<dynamic> _showEmojiPicker(
      {required void Function(String emoji) onEmojiSelected}) {
    return showCommonModalBottomSheet(
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

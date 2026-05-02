import 'package:animetrace/routes/get_route.dart';
import 'package:animetrace/utils/log.dart';
import 'package:animetrace/widgets/anchor_scroll.dart';
import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import 'package:flutter/material.dart';
import 'package:animetrace/controllers/labels_controller.dart';
import 'package:animetrace/dao/label_dao.dart';
import 'package:animetrace/models/label.dart';
import 'package:animetrace/pages/settings/label/home.dart';
import 'package:animetrace/utils/toast_util.dart';
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
            onLongPress: _cancelEmoji,
            onTap: _showEmojiPicker,
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

  void _showEmojiPicker() {
    RouteUtil.materialTo(
      context,
      EmojiPicker(
        onEmojiSelected: (Category? category, Emoji emoji) {
          Navigator.pop(context);
          this.emoji = emoji.emoji;
          setState(() {});
        },
        customWidget: (config, state, showSearchBar) =>
            _EmojiPickerView(config, state, showSearchBar),
      ),
    );
  }
}

class _EmojiPickerView extends EmojiPickerView {
  const _EmojiPickerView(super.config, super.state, super.showSearchBar);

  @override
  _CustomViewState createState() => _CustomViewState();
}

class _CustomViewState extends State<_EmojiPickerView> {
  final anchorScrollController = AnchorScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      // 渲染完毕后重绘展示所有分类锚点，便于切换
      setState(() {});
    });
  }

  @override
  void dispose() {
    anchorScrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(body: LayoutBuilder(
      builder: (context, constraints) {
        final maxWidth = constraints.maxWidth;
        final double paddingHorizontal =
            maxWidth > 500 ? (maxWidth - 500) / 2 : 0;

        Iterable<Widget> _genCategories() sync* {
          for (final section in widget.state.categoryEmoji) {
            if (section.emoji.isEmpty) continue;

            AppLog.debug('build category ${section.category.zhName}');
            yield SliverToBoxAdapter(
              child: AnchorWidget(
                controller: anchorScrollController,
                anchorValue: section.category.zhName,
                child: Padding(
                  padding: EdgeInsets.only(
                    top: 24,
                    bottom: 12,
                    left: paddingHorizontal + 12,
                  ),
                  child: Text(
                    section.category.zhName,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
              ),
            );

            yield SliverPadding(
              padding: EdgeInsets.symmetric(horizontal: paddingHorizontal),
              sliver: SliverGrid.builder(
                  gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: 60,
                  ),
                  itemCount: section.emoji.length,
                  itemBuilder: (context, index) {
                    // AppLog.debug('build emoji $index');
                    final e = section.emoji[index];

                    return Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: () {
                          widget.state.onEmojiSelected(null, e);
                        },
                        child: FittedBox(child: Text(e.emoji)),
                      ),
                    );
                  }),
            );
          }
        }

        return AnchorCustomScrollView(
          controller: anchorScrollController,
          slivers: [
            SliverAppBar(
              title: const Text('选择表情'),
              pinned: true,
              bottom: PreferredSize(
                preferredSize: const Size.fromHeight(40),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      ...anchorScrollController.anchorValues.map(
                        (e) => TextButton(
                          onPressed: () =>
                              anchorScrollController.jumpToAnchor(e),
                          child: Text(e),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            ..._genCategories(),
          ],
        );
      },
    ));
  }
}

extension _CategoryExtension on Category {
  String get zhName {
    switch (this) {
      case Category.RECENT:
        return '最近';
      case Category.SMILEYS:
        return '表情';
      case Category.ANIMALS:
        return '动物';
      case Category.FOODS:
        return '食物';
      case Category.ACTIVITIES:
        return '活动';
      case Category.TRAVEL:
        return '旅行';
      case Category.OBJECTS:
        return '物品';
      case Category.SYMBOLS:
        return '符号';
      case Category.FLAGS:
        return '旗帜';
    }
  }
}

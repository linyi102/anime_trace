import 'package:flutter/material.dart';
import 'package:animetrace/controllers/labels_controller.dart';
import 'package:animetrace/models/label.dart';
import 'package:animetrace/widgets/emoji_leading.dart';

class RecommendedLabelListView extends StatefulWidget {
  const RecommendedLabelListView({super.key});

  @override
  State<RecommendedLabelListView> createState() =>
      _RecommendedLabelListViewState();
}

class _RecommendedLabelListViewState extends State<RecommendedLabelListView> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('推荐标签'),
        automaticallyImplyLeading: false,
      ),
      body: ListView.builder(
        itemCount: LabelsController.to.recommendedLabels.length,
        itemBuilder: (context, index) {
          String recommendedLabel =
              LabelsController.to.recommendedLabels[index];

          return ListTile(
            leading: EmojiLeading(emoji: Label.getEmoji(recommendedLabel)),
            title: Text(Label.getNameWithoutEmoji(recommendedLabel) ?? ''),
            trailing: _buildAction(recommendedLabel),
          );
        },
      ),
    );
  }

  TextButton _buildAction(String recommendedLabel) {
    int addedLabelIndex = LabelsController.to.labels.indexWhere((e) =>
        e.nameWithoutEmoji == Label.getNameWithoutEmoji(recommendedLabel));
    bool isAdded = false;
    Label? addedLabel;
    if (addedLabelIndex >= 0) {
      isAdded = true;
      addedLabel = LabelsController.to.labels[addedLabelIndex];
    }

    if (isAdded) {
      if (addedLabel?.name == recommendedLabel) {
        return const TextButton(onPressed: null, child: Text('已添加'));
      } else {
        return TextButton(
            onPressed: () async {
              await LabelsController.to
                  .updateLabel(addedLabel!, recommendedLabel);
              setState(() {});
            },
            child: const Text('添加图标'));
      }
    }

    return TextButton(
        onPressed: () async {
          await LabelsController.to.addLabel(recommendedLabel);
          setState(() {});
        },
        child: const Text('添加'));
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_test_future/controllers/labels_controller.dart';
import 'package:flutter_test_future/models/label.dart';
import 'package:flutter_test_future/widgets/emoji_leading.dart';

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
          String labelName = LabelsController.to.recommendedLabels[index];
          bool isAdded = LabelsController.to.labels.indexWhere((e) =>
                  e.nameWithoutEmoji ==
                  Label.getNameWithoutEmoji(
                      Label.getEmoji(labelName), labelName)) >=
              0;
          String? emoji = Label.getEmoji(labelName);

          return ListTile(
            leading: EmojiLeading(emoji: emoji),
            title: Text(Label.getNameWithoutEmoji(emoji, labelName) ?? ''),
            trailing: isAdded
                ? const TextButton(onPressed: null, child: Text('已添加'))
                : TextButton(
                    onPressed: () async {
                      await LabelsController.to.addLabel(labelName);
                      setState(() {});
                    },
                    child: const Text('添加')),
          );
        },
      ),
    );
  }
}

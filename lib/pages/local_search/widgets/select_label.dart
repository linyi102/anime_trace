import 'package:flutter/material.dart';
import 'package:flutter_test_future/controllers/labels_controller.dart';
import 'package:flutter_test_future/models/label.dart';
import 'package:flutter_test_future/pages/local_search/controllers/local_search_controller.dart';

import 'package:flutter_test_future/utils/sp_profile.dart';
import 'package:flutter_test_future/values/values.dart';
import 'package:get/get.dart';

class SelectLabelView extends StatefulWidget {
  const SelectLabelView({required this.localSearchController, super.key});
  final LocalSearchController localSearchController;

  @override
  State<SelectLabelView> createState() => _SelectLabelViewState();
}

class _SelectLabelViewState extends State<SelectLabelView> {
  LabelsController labelsController = Get.find();

  late LocalSearchController localSearchController =
      widget.localSearchController;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _buildMultiSelectButton(),
              const Spacer(),
              _buildClearSelectedLabels()
            ],
          ),
          const SizedBox(height: 5),
          GetBuilder(
            init: widget.localSearchController,
            tag: widget.localSearchController.tag,
            builder: (_) => _buildLabelWrap(),
          )
        ],
      ),
    );
  }

  TextButton _buildClearSelectedLabels() {
    return TextButton(
      onPressed: () {
        localSearchController.localSelectFilter.labels.clear();
        setState(() {});

        widget.localSearchController.setLabels([]);
      },
      child: Text(
        "清空选中",
        style: Theme.of(context).textTheme.bodySmall,
      ),
    );
  }

  TextButton _buildMultiSelectButton() {
    return TextButton(
      onPressed: () {
        SpProfile.turnEnableMultiLabelQuery();
        if (SpProfile.getEnableMultiLabelQuery()) {
          // 开启多标签后，不需要清空已选中的标签和搜索结果
        } else {
          // 关闭多标签后，需要清空已选中的标签，以及搜索结果
          widget.localSearchController.setLabels([]);
        }

        setState(() {});
      },
      child: Text(
        SpProfile.getEnableMultiLabelQuery() ? "关闭多标签" : "开启多标签",
        style: Theme.of(context).textTheme.bodySmall,
      ),
    );
  }

  _buildLabelWrap() {
    // 使用obx监听，否则labelController懒加载，打开app后进入本地搜索页看不到标签
    return Obx(() => Wrap(
          spacing: AppTheme.wrapSacing,
          runSpacing: AppTheme.wrapRunSpacing,
          children: labelsController.labels.reversed.map((label) {
            bool selected =
                localSearchController.localSelectFilter.labels.contains(label);

            return FilterChip(
              showCheckmark: false,
              pressElevation: 0,
              selected: selected,
              label: Text(label.name),
              onSelected: (_) => _onTapLabelChip(selected, label),
            );
          }).toList(),
        ));
  }

  void _onTapLabelChip(bool selected, Label lbael) {
    if (SpProfile.getEnableMultiLabelQuery()) {
      // 多标签查询
      if (selected) {
        localSearchController.localSelectFilter.labels.remove(lbael);
      } else {
        localSearchController.localSelectFilter.labels.add(lbael);
      }
    } else {
      // 单标签查询，需要先清空选中的标签
      localSearchController.localSelectFilter.labels.clear();
      localSearchController.localSelectFilter.labels.add(lbael);
    }
    setState(() {});

    widget.localSearchController
        .setLabels(localSearchController.localSelectFilter.labels);
  }
}

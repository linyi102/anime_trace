import 'package:flutter/material.dart';
import 'package:flutter_test_future/components/operation_button.dart';

import '../../../../dao/series_dao.dart';
import '../../../../models/series.dart';
import '../../../../utils/log.dart';
import '../../../../utils/toast_util.dart';
import '../../../../widgets/common_scaffold_body.dart';

class SeriesFormPage extends StatefulWidget {
  const SeriesFormPage({this.series, super.key});
  final Series? series;

  @override
  State<SeriesFormPage> createState() => _SeriesFormPageState();
}

class _SeriesFormPageState extends State<SeriesFormPage> {
  bool get insertAction => widget.series == null;
  bool get updateAction => !insertAction;

  final formKey = GlobalKey();
  TextEditingController nameController = TextEditingController();
  TextEditingController descController = TextEditingController();
  TextEditingController coverUrlController = TextEditingController();

  @override
  void initState() {
    if (updateAction && widget.series != null) {
      nameController.text = widget.series!.name;
      descController.text = widget.series!.desc;
      coverUrlController.text = widget.series!.coverUrl;
    }
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(insertAction ? '添加系列' : '编辑系列'),
      ),
      body: CommonScaffoldBody(
          child: SingleChildScrollView(
              child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        child: Form(
          key: formKey,
          child: Column(
            children: [
              TextFormField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: '名称',
                ),
                autofocus: true,
                maxLength: 30,
              ),
              TextFormField(
                controller: descController,
                decoration: const InputDecoration(
                  labelText: '描述',
                ),
                maxLength: 300,
              ),
              const SizedBox(height: 10),
              OperationButton(
                  onTap: () {
                    if (insertAction) {
                      clickInsertButton();
                    } else {
                      clickUpdateButton();
                    }
                  },
                  text: insertAction ? '添加' : '保存'),
            ],
          ),
        ),
      ))),
    );
  }

  clickUpdateButton() async {
    String newSeriesName = nameController.text;
    String newDesc = descController.text;

    // 禁止空
    if (newSeriesName.isEmpty) {
      ToastUtil.showText("不能添加空系列");
      return;
    }

    // 名字变了，但新名字和其他系列重名了
    if (widget.series!.name != newSeriesName &&
        await SeriesDao.existSeriesName(newSeriesName)) {
      ToastUtil.showText("已有该系列");
      return;
    }

    int updateCnt =
        await SeriesDao.update(widget.series!.id, newSeriesName, newDesc);
    if (updateCnt > 0) {
      Log.info("修改系列成功");
      widget.series!.name = newSeriesName;
      widget.series!.desc = newDesc;
    } else {
      Log.info("修改失败");
    }
    Navigator.pop(context);
  }

  clickInsertButton() async {
    String seriesName = nameController.text;
    // 禁止空
    if (seriesName.isEmpty) {
      ToastUtil.showText("不能添加空系列");
      return;
    }

    // 禁止重名
    if (await SeriesDao.existSeriesName(seriesName)) {
      ToastUtil.showText("已有该系列");

      return;
    }

    Series newSeries = Series(0, seriesName, desc: descController.text);

    int newId = await SeriesDao.insert(newSeries);
    if (newId > 0) {
      Log.info("添加系列成功，新插入的id=$newId");
      // 指定新id，并添加到controller中
      newSeries.id = newId;
      Navigator.pop(context);
    } else {
      Log.info("添加失败");
    }
  }
}

import 'dart:developer';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test_future/animation/fade_route.dart';
import 'package:flutter_test_future/components/anime_list_cover.dart';
import 'package:flutter_test_future/components/img_widget.dart';
import 'package:flutter_test_future/components/note_img_item.dart';
import 'package:flutter_test_future/dao/image_dao.dart';
import 'package:flutter_test_future/models/note.dart';
import 'package:flutter_test_future/models/relative_local_image.dart';
import 'package:flutter_test_future/pages/settings/image_path_setting.dart';
import 'package:flutter_test_future/utils/image_util.dart';
import 'package:flutter_test_future/utils/log.dart';
import 'package:flutter_test_future/utils/sqlite_util.dart';
import 'package:oktoast/oktoast.dart';
import 'package:reorderable_grid_view/reorderable_grid_view.dart';

import '../../dao/note_dao.dart';
import '../../responsive.dart';
import '../../utils/theme_util.dart';

class NoteEdit extends StatefulWidget {
  final Note note; // 可能会修改笔记内容，因此不能用final
  const NoteEdit(this.note, {Key? key}) : super(key: key);

  @override
  State<NoteEdit> createState() => _NoteEditState();
}

class _NoteEditState extends State<NoteEdit> {
  bool _loadOk = false;
  bool _updateNoteContent = false; // 如果文本内容发生变化，返回时会更新数据库
  var noteContentController = TextEditingController();
  // Map<int, int> initialOrderIdx = {}; // key-value对应imageId-orderIdx
  bool changeOrderIdx = false;

  @override
  void initState() {
    super.initState();
    noteContentController.text = widget.note.noteContent;
    debugPrint("进入笔记${widget.note.episodeNoteId}");
    _loadData();
  }

  _loadData() async {
    Future(() {
      return NoteDao.existNoteId(widget.note.episodeNoteId);
    }).then((existNoteId) {
      if (!existNoteId) {
        // 笔记id置0，从笔记编辑页返回到笔记列表页，接收到后根据动漫id删除所有相关笔记
        widget.note.episodeNoteId = 0;
        Navigator.of(context).pop(widget.note);
        showToast("未找到该笔记");
      } else {
        _loadOk = true;
        setState(() {});
      }
      // // 记录所有图片的初始下标
      // for (int i = 0; i < widget.note.relativeLocalImages.length; ++i) {
      //   initialOrderIdx[widget.note.relativeLocalImages[i].imageId] = i;
      // }
    });
  }

  _onWillpop() async {
    Navigator.pop(context, widget.note);

    // 后台更新数据库中的图片顺序
    // 全部更新。只要移动了，就更新所有图片的记录顺序
    if (changeOrderIdx) {
      for (int newOrderIdx = 0;
          newOrderIdx < widget.note.relativeLocalImages.length;
          ++newOrderIdx) {
        int imageId = widget.note.relativeLocalImages[newOrderIdx].imageId;
        ImageDao.updateImageOrderIdxById(imageId, newOrderIdx);
      }
    }
    // 局部更新
    // for (int newOrderIdx = 0;
    //     newOrderIdx < widget.note.relativeLocalImages.length;
    //     ++newOrderIdx) {
    //   int imageId = widget.note.relativeLocalImages[newOrderIdx].imageId;
    //   // 有缺陷，详细参考getRelativeLocalImgsByNoteId方法
    //   if (initialOrderIdx[imageId] != newOrderIdx) {
    //     ImageDao.updateImageOrderIdxById(imageId, newOrderIdx);
    //   }
    // }
    if (_updateNoteContent) {
      NoteDao.updateEpisodeNoteContentByNoteId(
          widget.note.episodeNoteId, widget.note.noteContent);
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        // 返回键
        _onWillpop();
        return true;
      },
      child: Scaffold(
        appBar: AppBar(
          // title: const Text("笔记编辑"),
          leading: IconButton(
              // 返回按钮
              onPressed: () => _onWillpop(),
              tooltip: "返回上一级",
              icon: const Icon(Icons.arrow_back_rounded)),
        ),
        body: _loadOk ? _buildBody() : Container(),
      ),
    );
  }

  _buildBody() {
    // log("_buildBody", time: DateTime.now(), name: runtimeType.toString());
    Log.info("_buildBody");
    // 懒加载
    // return _buildReorderNoteImgGridView(crossAxisCount: 2);

    // 全部加载
    // return ListView(
    //   children: [_buildReorderNoteImgGridView(crossAxisCount: 2)],
    // );

    // TODO 如何保证懒加载？注意还要是GridVie.wbuilder
    // 懒加载
    // return Column(
    //   children: [
    //     Expanded(child: _buildReorderNoteImgGridView(crossAxisCount: 2))
    //   ],
    // );

    // 还是全部加载
    // return CustomScrollView(
    //   slivers: [
    //     SliverList(
    //         delegate: SliverChildListDelegate(
    //             [_buildReorderNoteImgGridView(crossAxisCount: 2)]))
    //   ],
    // );

    //
    return Scrollbar(
      child: ListView(
        children: [
          widget.note.episode.number == 0
              ? Container() // 若为0，表明是评价，不显示该行
              : ListTile(
                  style: ListTileStyle.drawer,
                  leading: AnimeListCover(widget.note.anime),
                  title: Text(
                    widget.note.anime.animeName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textScaleFactor: ThemeUtil.smallScaleFactor,
                  ),
                  subtitle: Text(
                    "第 ${widget.note.episode.number} 集 ${widget.note.episode.getDate()}",
                    textScaleFactor: ThemeUtil.tinyScaleFactor,
                  ),
                ),
          _showNoteContent(),
          Responsive(
              mobile: _buildReorderNoteImgGridView(crossAxisCount: 3),
              tablet: _buildReorderNoteImgGridView(crossAxisCount: 5),
              desktop: _buildReorderNoteImgGridView(crossAxisCount: 7))
        ],
      ),
    );
  }

  _showNoteContent() {
    return TextField(
      controller: noteContentController..text,
      decoration: const InputDecoration(
        hintText: "描述",
        border: InputBorder.none,
        contentPadding: EdgeInsets.fromLTRB(15, 5, 15, 15),
      ),
      style: ThemeUtil.getNoteTextStyle(),
      maxLines: null,
      onChanged: (value) {
        _updateNoteContent = true;
        widget.note.noteContent = value;
      },
    );
  }

  _buildReorderNoteImgGridView({required int crossAxisCount}) {
    // Log.info("_buildReorderNoteImgGridView：开始构建笔记图标网格组件");
    // return ReorderableGridView.builder(
    //   padding: const EdgeInsets.fromLTRB(15, 15, 15, 50),
    //   shrinkWrap: true, // 解决报错问题
    //   physics: const NeverScrollableScrollPhysics(), //解决不滚动问题
    //   onReorder: (oldIndex, newIndex) {
    //     setState(() {
    //       final element = widget.note.relativeLocalImages.removeAt(oldIndex);
    //       widget.note.relativeLocalImages.insert(newIndex, element);
    //     });
    //     changeOrderIdx = true;
    //   },
    //   // 表示长按多久可以拖拽
    //   dragStartDelay: const Duration(milliseconds: 100),
    //   // 拖拽时的组件
    //   dragWidgetBuilder: (int index, Widget child) => Container(
    //     decoration: BoxDecoration(
    //         borderRadius: BorderRadius.circular(10), // 边框的圆角
    //         border: Border.all(color: ThemeUtil.getPrimaryColor(), width: 4)),
    //     // 切割图片为圆角
    //     child: ClipRRect(
    //       borderRadius: BorderRadius.circular(6),
    //       child: buildImgWidget(
    //           url: widget.note.relativeLocalImages[index].path,
    //           showErrorDialog: false,
    //           isNoteImg: true),
    //     ),
    //   ),
    //   gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
    //     crossAxisCount: crossAxisCount,
    //     crossAxisSpacing: 4, // 横轴距离
    //     mainAxisSpacing: 4, // 竖轴距离
    //     childAspectRatio: 1, // 网格比例
    //   ),

    //   itemCount: widget.note.relativeLocalImages.length,
    //   itemBuilder: (BuildContext context, int index) {
    //     debugPrint("$runtimeType: index=$index");
    //     return Container(
    //       key: UniqueKey(),
    //       // key: Key("${widget.note.relativeLocalImages.elementAt(index).imageId}"),
    //       child: _buildNoteItem(index),
    //     );
    //   },
    // );
    return ReorderableGridView.count(
      padding: const EdgeInsets.fromLTRB(15, 15, 15, 50),
      crossAxisCount: crossAxisCount,
      crossAxisSpacing: 4, // 横轴距离
      mainAxisSpacing: 4, // 竖轴距离
      childAspectRatio: 1, // 网格比例
      shrinkWrap: true, // 解决报错问题
      physics: const NeverScrollableScrollPhysics(), //解决不滚动问题
      children: List.generate(
        widget.note.relativeLocalImages.length,
        (index) => Container(
          key: UniqueKey(),
          // key: Key("${widget.note.relativeLocalImages.elementAt(index).imageId}"),
          child: _buildNoteItem(index),
        ),
      ),
      onReorder: (oldIndex, newIndex) {
        // 下标没变直接返回
        debugPrint("oldIndex=$oldIndex, newIndex=$newIndex");
        if (oldIndex == newIndex) {
          debugPrint("拖拽了，但未改变顺序，直接返回");
          return;
        }

        setState(() {
          final element = widget.note.relativeLocalImages.removeAt(oldIndex);
          widget.note.relativeLocalImages.insert(newIndex, element);
        });
        changeOrderIdx = true;
        debugPrint("改变了顺序，修改changeOrderIdx为$changeOrderIdx，将在返回后更新所有图片记录顺序");
      },
      // 表示长按多久可以拖拽
      dragStartDelay: const Duration(milliseconds: 100),
      // 拖拽时的组件
      dragWidgetBuilder: (int index, Widget child) => Container(
        decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10), // 边框的圆角
            border: Border.all(color: ThemeUtil.getPrimaryColor(), width: 4)),
        // 切割图片为圆角
        child: ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: buildImgWidget(
              url: widget.note.relativeLocalImages[index].path,
              showErrorDialog: false,
              isNoteImg: true),
        ),
      ),
      // 添加图片按钮
      footer: [_buildAddButton()],
    );
  }

  Container _buildAddButton() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(4),
        color: ThemeUtil.getPrimaryColor().withOpacity(0.1),
      ),
      child: TextButton(
          onPressed: () => _pickLocalImages(), child: const Icon(Icons.add)),
    );
  }

  Stack _buildNoteItem(int imageIndex) {
    return Stack(
      children: [
        NoteImgItem(
          relativeLocalImages: widget.note.relativeLocalImages,
          initialIndex: imageIndex,
        ),
        // 删除按钮
        Positioned(
          right: 0,
          top: 0,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(5),
              color: const Color.fromRGBO(255, 255, 255, 0.1),
            ),
            child: GestureDetector(
                onTap: () => _dialogRemoveImage(imageIndex),
                child:
                    const Icon(Icons.close, color: Colors.white70, size: 18)),
          ),
        )
      ],
    );
  }

  _pickLocalImages() async {
    if (!ImageUtil.hasNoteImageRootDirPath()) {
      showToast("请先设置图片根目录");
      Navigator.of(context).push(
        // MaterialPageRoute(
        //   builder: (BuildContext context) =>
        //       const NoteSetting(),
        // ),
        FadeRoute(
          builder: (context) {
            return const ImagePathSetting();
          },
        ),
      );
      return;
    }
    if (Platform.isWindows || Platform.isAndroid) {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['jpg', 'jpeg', 'png', 'gif'],
        allowMultiple: true,
      );
      if (result == null) return;
      List<PlatformFile> platformFiles = result.files;
      for (var platformFile in platformFiles) {
        String absoluteImagePath = platformFile.path ?? "";
        if (absoluteImagePath.isEmpty) continue;

        String relativeImagePath =
            ImageUtil.getRelativeNoteImagePath(absoluteImagePath);
        int imageId = await SqliteUtil.insertNoteIdAndImageLocalPath(
            widget.note.episodeNoteId,
            relativeImagePath,
            widget.note.relativeLocalImages.length);
        widget.note.relativeLocalImages
            .add(RelativeLocalImage(imageId, relativeImagePath));
        // 排序结果：null,0,1,2,3...
        // 1.如果添加新图片时没有为新图片设置下标，
        //   1.如果其他图片都为null，该图片会被排序到最后面，正常。
        //   2.如果其他图片都有下标，那么该图片就会排序到最前面，错误。需要重新修改所有，也就是标记changeOrderIdx为true
        // 2.如果添加新图片时为新图片设置下标，
        //   1.其他图片都为都为null，那么会排序到最后面，正常
        //   2.如果其他图片都有下标，正常
      }
    } else {
      throw ("未适配平台：${Platform.operatingSystem}");
    }
    setState(() {});
  }

  _dialogRemoveImage(int index) {
    return showDialog(
        context: context,
        builder: (context) {
          // 返回警告对话框
          return AlertDialog(
            title: const Text("提示"),
            content: const Text("确认移除该图片吗？"),
            // 动作集合
            actions: <Widget>[
              TextButton(
                child: const Text("取消"),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
              ElevatedButton(
                child: const Text("确认"),
                onPressed: () {
                  RelativeLocalImage relativeLocalImage =
                      widget.note.relativeLocalImages[index];
                  // 删除数据库记录、删除该页中的图片
                  SqliteUtil.deleteLocalImageByImageId(
                      relativeLocalImage.imageId);
                  widget.note.relativeLocalImages.removeWhere((element) =>
                      element.imageId == relativeLocalImage.imageId);
                  setState(() {});
                  Navigator.of(context).pop();
                },
              ),
            ],
          );
        });
  }
}

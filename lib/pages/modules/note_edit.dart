import 'dart:io';

import 'package:desktop_drop/desktop_drop.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test_future/components/anime_list_cover.dart';
import 'package:flutter_test_future/components/note/note_img_item.dart';
import 'package:flutter_test_future/controllers/theme_controller.dart';
import 'package:flutter_test_future/dao/image_dao.dart';
import 'package:flutter_test_future/models/note.dart';
import 'package:flutter_test_future/models/relative_local_image.dart';
import 'package:flutter_test_future/pages/settings/image_path_setting.dart';
import 'package:flutter_test_future/utils/image_util.dart';
import 'package:flutter_test_future/utils/sqlite_util.dart';
import 'package:flutter_test_future/values/theme.dart';
import 'package:flutter_test_future/utils/toast_util.dart';
import 'package:flutter_test_future/widgets/common_scaffold_body.dart';
import 'package:reorderable_grid_view/reorderable_grid_view.dart';
import 'package:flutter_test_future/utils/log.dart';
import 'package:flutter_test_future/dao/note_dao.dart';
import 'package:flutter_test_future/widgets/responsive.dart';

import '../../utils/time_util.dart';

class NoteEditPage extends StatefulWidget {
  final Note note;

  const NoteEditPage(this.note, {Key? key}) : super(key: key);

  @override
  State<NoteEditPage> createState() => _NoteEditPageState();
}

class _NoteEditPageState extends State<NoteEditPage> {
  bool _loadOk = false;
  bool _updateNoteContent = false; // 如果文本内容发生变化，返回时会更新数据库
  var noteContentController = TextEditingController();
  bool changeOrderIdx = false;

  final scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    Log.info("进入笔记${widget.note.id}");
    _loadData();
  }

  @override
  void dispose() {
    super.dispose();
    scrollController.dispose();
  }

  _loadData() async {
    Log.info("note.id=${widget.note.id}");
    // 已经能保证是最新的了，所以不需要重新获取
    // NoteDao.getNoteContentAndImagesByNoteId(widget.note.id).then((value) {
    //   if (value.id == 0) {
    //     Navigator.of(context).pop(widget.note);
    //     ToastUtil.showText("未找到该笔记");
    //   } else {
    //     widget.note.relativeLocalImages = value.relativeLocalImages;
    //     noteContentController.text = widget.note.noteContent;
    //     _loadOk = true;
    //     setState(() {});
    //   }
    // });

    Future(() {
      return NoteDao.existNoteId(widget.note.id);
    }).then((existNoteId) {
      if (!existNoteId) {
        // 笔记id置0，从笔记编辑页返回到笔记列表页，接收到后根据动漫id删除所有相关笔记
        widget.note.id = 0;
        Navigator.of(context).pop(widget.note);
        ToastUtil.showText("未找到该笔记");
      } else {
        noteContentController.text = widget.note.noteContent;
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
    if (widget.note.isEmpty) {
      NoteDao.deleteNoteById(widget.note.id);
      Navigator.pop(context, null);
      return;
    }

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
      NoteDao.updateNoteContentByNoteId(
          widget.note.id, widget.note.noteContent);
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
        body: CommonScaffoldBody(child: _loadOk ? _buildBody() : Container()),
      ),
    );
  }

  bool _dragging = false;

  _buildImageDroppable({required Widget child}) {
    return DropTarget(
      onDragDone: (detail) async {
        for (var file in detail.files) {
          await _addImage(file.path);
        }
        if (mounted) setState(() {});
      },
      onDragEntered: (detail) {
        setState(() {
          _dragging = true;
        });
      },
      onDragExited: (detail) {
        setState(() {
          _dragging = false;
        });
      },
      child: Container(
        color: _dragging
            ? ThemeController.to.isDark(context)
                ? Colors.white10
                : Colors.black.withOpacity(0.08)
            : Colors.transparent,
        child: child,
      ),
    );
  }

  _buildBody() {
    return _buildImageDroppable(
      child: Scrollbar(
        controller: scrollController,
        child: ListView(
          controller: scrollController,
          children: [
            _buildAnimeInfo(),
            _showNoteContent(),
            Responsive(
                mobile: _buildReorderNoteImgGridView(crossAxisCount: 3),
                tablet: _buildReorderNoteImgGridView(crossAxisCount: 5),
                desktop: _buildReorderNoteImgGridView(crossAxisCount: 7)),
            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }

  ListTile _buildAnimeInfo() {
    return ListTile(
      style: ListTileStyle.drawer,
      leading: AnimeListCover(widget.note.anime),
      title: Text(
        widget.note.anime.animeName,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
      subtitle: Text(
        widget.note.episode.number == 0
            ? TimeUtil.getHumanReadableDateTimeStr(widget.note.createTime)
            : "${widget.note.episode.caption} ${widget.note.episode.getDate()}",
        style: Theme.of(context).textTheme.bodySmall,
      ),
    );
  }

  _showNoteContent() {
    return TextField(
      // 不能放在这里，否则点击行尾时，光标会跑到行首
      // controller: noteContentController..text = widget.note.noteContent,
      controller: noteContentController..text,
      decoration: const InputDecoration(
        hintText: "描述",
        contentPadding: EdgeInsets.fromLTRB(15, 5, 15, 15),
        border: InputBorder.none,
        focusedBorder: UnderlineInputBorder(
            borderSide: BorderSide(color: Colors.transparent)),
      ),

      style: AppTheme.noteStyle,
      maxLines: null,
      onChanged: (value) {
        _updateNoteContent = true;
        widget.note.noteContent = value;
      },
    );
  }

  _buildReorderNoteImgGridView({required int crossAxisCount}) {
    Log.info("_buildReorderNoteImgGridView：开始构建笔记图标网格组件");

    return ReorderableGridView.count(
      padding: const EdgeInsets.fromLTRB(15, 15, 15, 0),
      crossAxisCount: crossAxisCount,
      // 横轴距离
      crossAxisSpacing: AppTheme.noteImageSpacing,
      // 竖轴距离
      mainAxisSpacing: AppTheme.noteImageSpacing,
      // 网格比例
      childAspectRatio: 1,
      // 解决报错问题
      shrinkWrap: true,
      // 解决不滚动问题
      physics: const NeverScrollableScrollPhysics(),
      children: List.generate(
        widget.note.relativeLocalImages.length,
        (index) => Container(
          key: UniqueKey(),
          // key: Key("${widget.note.relativeLocalImages.elementAt(index).imageId}"),
          child: _buildNoteItem(index),
        ),
      ),
      dragStartDelay: const Duration(milliseconds: 200),
      onReorder: (oldIndex, newIndex) {
        // 下标没变直接返回
        Log.info("oldIndex=$oldIndex, newIndex=$newIndex");
        if (oldIndex == newIndex) {
          Log.info("拖拽了，但未改变顺序，直接返回");
          return;
        }

        setState(() {
          final element = widget.note.relativeLocalImages.removeAt(oldIndex);
          widget.note.relativeLocalImages.insert(newIndex, element);
        });
        changeOrderIdx = true;
        Log.info("改变了顺序，修改changeOrderIdx为$changeOrderIdx，将在返回后更新所有图片记录顺序");
      },
      // 拖拽时的组件
      dragWidgetBuilder: (int index, Widget child) => Material(
          color: Colors.transparent,
          elevation: 12,
          child: _buildNoteItem(index, showDelButton: false)),
      // 添加图片按钮
      footer: [_buildAddButton()],
    );
  }

  Container _buildAddButton() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppTheme.noteImgRadius),
        color: Theme.of(context).hoverColor,
        // border: Border.all(
        //   style: BorderStyle.solid,
        //   color: Theme.of(context).hintColor,
        // ),
      ),
      child: InkWell(
        onTap: () => _pickLocalImages(),
        borderRadius: BorderRadius.circular(AppTheme.noteImgRadius),
        child: Icon(Icons.add, color: Theme.of(context).hintColor),
      ),
    );
  }

  Stack _buildNoteItem(int imageIndex, {bool showDelButton = true}) {
    return Stack(
      children: [
        NoteImgItem(
          relativeLocalImages: widget.note.relativeLocalImages,
          initialIndex: imageIndex,
        ),
        // 删除按钮
        if (showDelButton)
          Positioned(
            right: 2,
            top: 2,
            child: GestureDetector(
              onTap: () => _dialogRemoveImage(imageIndex),
              child: Container(
                padding: const EdgeInsets.all(4.0),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(99),
                  color: Colors.black54,
                ),
                child: const Icon(Icons.close, color: Colors.white, size: 12),
              ),
            ),
          )
      ],
    );
  }

  _pickLocalImages() async {
    if (!ImageUtil.hasNoteImageRootDirPath()) {
      ToastUtil.showText("请先设置图片根目录");
      Navigator.of(context).push(
        // MaterialPageRoute(
        //   builder: (BuildContext context) =>
        //       const NoteSetting(),
        // ),
        MaterialPageRoute(
          builder: (context) {
            return const ImagePathSetting();
          },
        ),
      );
      return;
    }
    if (Platform.isWindows || Platform.isAndroid || Platform.isIOS) {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['jpg', 'jpeg', 'png', 'gif'],
        allowMultiple: true,
      );
      if (result == null) return;
      List<PlatformFile> platformFiles = result.files;
      for (var platformFile in platformFiles) {
        String absoluteImagePath = platformFile.path ?? "";
        await _addImage(absoluteImagePath);
      }
    } else {
      throw ("未适配平台：${Platform.operatingSystem}");
    }
    setState(() {});
  }

  Future<void> _addImage(String absoluteImagePath) async {
    if (absoluteImagePath.isEmpty) return;

    String relativeImagePath =
        ImageUtil.getRelativeNoteImagePath(absoluteImagePath);
    int imageId = await SqliteUtil.insertNoteIdAndImageLocalPath(widget.note.id,
        relativeImagePath, widget.note.relativeLocalImages.length);
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

  _dialogRemoveImage(int index) {
    return showDialog(
        context: context,
        builder: (context) {
          // 返回警告对话框
          return AlertDialog(
            title: const Text("确定移除吗？"),
            content: const Text("这并不会删除您的图片文件"),
            // 动作集合
            actions: <Widget>[
              TextButton(
                child: const Text("取消"),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
              TextButton(
                child: const Text("移除"),
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

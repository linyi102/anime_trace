import 'package:eva_icons_flutter/eva_icons_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test_future/components/my_icon_button.dart';
import 'package:flutter_test_future/dao/note_dao.dart';
import 'package:oktoast/oktoast.dart';
import 'package:flutter_test_future/components/anime_list_cover.dart';
import 'package:flutter_test_future/components/anime_rating_bar.dart';
import 'package:flutter_test_future/components/note_img_grid.dart';
import 'package:flutter_test_future/models/note.dart';
import 'package:flutter_test_future/utils/log.dart';
import 'package:flutter_test_future/utils/sqlite_util.dart';
import 'package:flutter_test_future/utils/theme_util.dart';
import 'package:flutter_test_future/utils/time_show_util.dart';
import '../pages/modules/note_edit.dart';

/// 笔记卡片
/// 使用：所有笔记页、所有评价页、动漫详细评价页
/// 提取到该Widget，目的是为了从编辑页返回后，setState重绘这一个卡片，而不是整个页面
class NoteCard extends StatefulWidget {
  final Note note;
  final void Function()? removeNote;
  final void Function()? enterAnimeDetail;
  final bool showAnimeTile;
  final bool isRateNote;

  const NoteCard(this.note,
      {this.removeNote,
      this.enterAnimeDetail,
      this.showAnimeTile = false,
      this.isRateNote = false,
      Key? key})
      : super(key: key);

  @override
  State<NoteCard> createState() => _NoteCardState();
}

class _NoteCardState extends State<NoteCard> {
  @override
  Widget build(BuildContext context) {
    Log.build(runtimeType);
    Note note = widget.note;

    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: Card(
        elevation: 0,
        child: MaterialButton(
          elevation: 0,
          padding: const EdgeInsets.all(0),
          onPressed: () => _enterNoteEditPage(note),
          child: Column(
            children: [
              if (widget.showAnimeTile) _buildAnimeListTile(note),
              // 笔记内容
              _buildNoteContent(note),
              // 笔记图片
              NoteImgGrid(relativeLocalImages: note.relativeLocalImages),
              // if (widget.isRateNote)
              // 创建时间和操作按钮
              _buildCreateTimeAndMoreAction(note),
              // const Divider(),
            ],
          ),
        ),
      ),
    );
  }

  void _enterNoteEditPage(Note note) {
    Navigator.of(context)
        .push(MaterialPageRoute(builder: (context) => NoteEditPage(note)))
        .then((value) {
      // 重新获取列表
      // _loadData();
      // 不要重新获取，否则有时会直接跳到最上面，而不是上次浏览位置
      // 也不需要重新获取，因为笔记编辑页修改的就是传入的note数据，但注意返回后需要重新绘制
      setState(() {});
    });
  }

  _enterAnimeDetailPage() {
    if (widget.enterAnimeDetail != null) {
      widget.enterAnimeDetail!();
    }
  }

  _buildAnimeListTile(Note note) {
    return ListTile(
      leading: GestureDetector(
        onTap: _enterAnimeDetailPage,
        child: AnimeListCover(
          note.anime,
          showReviewNumber: true,
          reviewNumber: note.episode.reviewNumber,
          circular: false,
        ),
      ),
      // Row的作用是为了避免title组件占满整行，应该只在文字上点击后才进入详细页
      title: Row(
        children: [
          GestureDetector(
            onTap: _enterAnimeDetailPage,
            child: Container(
              // color: Colors.red[200],
              alignment: Alignment.centerLeft,
              child: Text(
                note.anime.animeName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textScaleFactor: ThemeUtil.smallScaleFactor,
                // style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
      subtitle: Row(
        children: [
          GestureDetector(
            onTap: _enterAnimeDetailPage,
            child: widget.isRateNote
                ? AnimeRatingBar(
                    rate: note.anime.rate,
                    iconSize: 12,
                    spacing: 2,
                    enableRate: false,
                    onRatingUpdate: (v) {
                      Log.info("评价分数：$v");
                      note.anime.rate = v.toInt();
                      SqliteUtil.updateAnimeRate(
                          note.anime.animeId, note.anime.rate);
                    })
                : Text("第${note.episode.number}集 ${note.episode.getDate()}",
                    textScaleFactor: ThemeUtil.tinyScaleFactor),
          ),
        ],
      ),
      // trailing: widget.isRateNote
      //     ? null
      //     : MyIconButton(
      //         onPressed: () => _enterNoteEditPage(note),
      //         icon: const Icon(
      //           Icons.edit,
      //           size: 16,
      //         )),
    );
  }

  _buildNoteContent(Note note) {
    if (note.noteContent.isEmpty) return Container();
    return Container(
      alignment: Alignment.centerLeft,
      // 左填充15，这样就和图片对齐了
      padding: const EdgeInsets.fromLTRB(15, 10, 15, 10),
      child: Text(
        note.noteContent,
        maxLines: 10,
        overflow: TextOverflow.ellipsis,
        style: ThemeUtil.getNoteTextStyle(),
      ),
    );
  }

  _buildCreateTimeAndMoreAction(Note note) {
    String timeStr = TimeShowUtil.getHumanReadableDateTimeStr(note.createTime);
    timeStr = timeStr.isEmpty ? "" : "创建于$timeStr";

    return ListTile(
        style: ListTileStyle.drawer,
        title: Text(
          timeStr,
          textScaleFactor: ThemeUtil.tinyScaleFactor,
          style: TextStyle(
              fontWeight: FontWeight.normal,
              color: ThemeUtil.getCommentColor()),
        ),
        trailing: MyIconButton(
            onPressed: () {
              showDialog(
                  context: context,
                  builder: (dialogContext) {
                    return SimpleDialog(
                      children: [
                        ListTile(
                          leading: const Icon(EvaIcons.edit2Outline),
                          title: const Text("编辑"),
                          style: ListTileStyle.drawer, // 变小
                          onTap: () {
                            Navigator.pop(dialogContext);
                            _enterNoteEditPage(note);
                          },
                        ),
                        ListTile(
                          leading: const Icon(EvaIcons.copyOutline),
                          title: const Text("复制内容"),
                          style: ListTileStyle.drawer, // 变小
                          onTap: () {
                            Clipboard.setData(
                                ClipboardData(text: note.noteContent));
                            showToast("已复制到剪贴板");
                            Navigator.pop(dialogContext);
                          },
                        ),
                        ListTile(
                          leading: const Icon(EvaIcons.trash2Outline),
                          title: const Text("删除笔记"),
                          style: ListTileStyle.drawer, // 变小
                          onTap: () {
                            _dialogDeleteConfirm(note);
                          },
                        )
                      ],
                    );
                  });
            },
            icon: const Icon(Icons.more_horiz)));
  }

  _dialogDeleteConfirm(Note note) async {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          content: const Text("确认删除笔记吗？"),
          actions: [
            TextButton(
              onPressed: () {
                // 关闭删除确认对话框和更多菜单对话框
                Navigator.of(context)
                  ..pop()
                  ..pop();
              },
              child: const Text("取消"),
            ),
            TextButton(
              onPressed: () async {
                // 关闭删除确认对话框和更多菜单对话框
                Navigator.of(context)
                  ..pop()
                  ..pop();
                if (await NoteDao.deleteNoteById(note.id)) {
                  if (widget.removeNote != null) {
                    widget.removeNote!();
                  }
                } else {
                  showToast("删除失败！");
                }
              },
              child: const Text(
                "删除",
                style: TextStyle(color: Colors.red),
              ),
            )
          ],
        );
      },
    );
  }
}

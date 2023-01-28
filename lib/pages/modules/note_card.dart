import 'package:flutter/material.dart';
import 'package:oktoast/oktoast.dart';

import '../../components/anime_list_cover.dart';
import '../../components/anime_rating_bar.dart';
import '../../components/note_img_grid.dart';
import '../../models/note.dart';
import '../../utils/log.dart';
import '../../utils/sqlite_util.dart';
import '../../utils/theme_util.dart';
import '../../utils/time_show_util.dart';
import 'note_edit.dart';

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
          onPressed: () {
            Navigator.of(context)
                .push(MaterialPageRoute(builder: (context) => NoteEdit(note)))
                .then((value) {
              // 重新获取列表
              // _loadData();
              // 不要重新获取，否则有时会直接跳到最上面，而不是上次浏览位置
              // 也不需要重新获取，因为笔记编辑页修改的就是传入的note数据，但注意返回后需要重新绘制
              setState(() {});
            });
          },
          child: Flex(
            direction: Axis.vertical,
            children: [
              if (widget.showAnimeTile) _buildAnimeListTile(note),
              // 笔记内容
              _buildNoteContent(note),
              // 笔记图片
              NoteImgGrid(relativeLocalImages: note.relativeLocalImages),
              if (widget.isRateNote)
                // 创建时间和操作按钮
                _buildCreateTimeAndMoreAction(note)
            ],
          ),
        ),
      ),
    );
  }

  _buildAnimeListTile(Note note) {
    return GestureDetector(
        onTap: () {
          if (widget.enterAnimeDetail != null) {
            widget.enterAnimeDetail!();
          }
        },
        child: ListTile(
          leading: AnimeListCover(
            note.anime,
            showReviewNumber: true,
            reviewNumber: note.episode.reviewNumber,
          ),
          title: Text(
            note.anime.animeName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textScaleFactor: ThemeUtil.smallScaleFactor,
            // textAlign: TextAlign.right,
          ),
          subtitle: widget.isRateNote
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
        ));
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
        trailing: IconButton(
            onPressed: () {
              showDialog(
                  context: context,
                  builder: (context) {
                    return SimpleDialog(
                      children: [
                        ListTile(
                          leading: const Icon(Icons.delete),
                          title: const Text("删除笔记"),
                          style: ListTileStyle.drawer, // 变小
                          onTap: () {
                            showDialog(
                              context: context,
                              builder: (BuildContext context) {
                                return AlertDialog(
                                  content: const Text("确定删除笔记吗？"),
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
                                    ElevatedButton(
                                      onPressed: () async {
                                        // 关闭删除确认对话框和更多菜单对话框
                                        Navigator.of(context)
                                          ..pop()
                                          ..pop();
                                        if (await SqliteUtil.deleteNoteById(
                                            note.id)) {
                                          if (widget.removeNote != null) {
                                            widget.removeNote!();
                                          }
                                        } else {
                                          showToast("删除失败！");
                                        }
                                      },
                                      child: const Text("确定"),
                                    )
                                  ],
                                );
                              },
                            );
                          },
                        )
                      ],
                    );
                  });
            },
            icon: const Icon(Icons.more_horiz)));
  }
}

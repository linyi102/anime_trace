import 'package:flutter/material.dart';
import 'package:flutter_test_future/dao/note_dao.dart';
import 'package:flutter_test_future/pages/modules/note_edit.dart';
import 'package:flutter_test_future/utils/common_util.dart';
import 'package:flutter_test_future/values/values.dart';
import 'package:flutter_test_future/utils/toast_util.dart';
import 'package:flutter_test_future/components/anime_list_cover.dart';
import 'package:flutter_test_future/components/note_img_grid.dart';
import 'package:flutter_test_future/models/note.dart';
import 'package:flutter_test_future/utils/time_util.dart';
import 'package:flutter_test_future/widgets/common_divider.dart';

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
  get enableLeftGap => false;

  @override
  Widget build(BuildContext context) {
    Note note = widget.note;

    return Card(
      child: InkWell(
        onTap: () => _enterNoteEditPage(note),
        onLongPress: () => _showMoreDialog(note),
        child: Column(
          children: [
            if (widget.showAnimeTile) _buildAnimeListTile(note),
            Container(
              padding: enableLeftGap ? const EdgeInsets.only(left: 55) : null,
              child: Column(
                children: [
                  // 笔记内容
                  _buildNoteContent(note),
                  // 笔记图片
                  NoteImgGrid(relativeLocalImages: note.relativeLocalImages),
                  if (note.relativeLocalImages.isEmpty)
                    const SizedBox(height: 10),
                ],
              ),
            ),
            const CommonDivider(thinkness: 0)
          ],
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
    String rateTimeStr = TimeUtil.getHumanReadableDateTimeStr(note.createTime);
    rateTimeStr = rateTimeStr.isEmpty ? "" : rateTimeStr;

    return ListTile(
      leading: GestureDetector(
        onTap: _enterAnimeDetailPage,
        child: AnimeListCover(
          note.anime,
          showReviewNumber: true,
          reviewNumber: note.episode.reviewNumber,
        ),
      ),
      trailing: _buildMoreButton(note),
      // Row的作用是为了避免title组件占满整行，应该只在文字上点击后才进入详细页
      title: Row(
        children: [
          // 使用expanded避免maxlines不生效导致文字溢出
          Expanded(
            child: GestureDetector(
              onTap: _enterAnimeDetailPage,
              child: Container(
                alignment: Alignment.centerLeft,
                child: Text(
                  note.anime.animeName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ),
        ],
      ),
      subtitle: Row(
        children: [
          GestureDetector(
            onTap: _enterAnimeDetailPage,
            child: Text(
              widget.isRateNote
                  ? rateTimeStr
                  : "${note.episode.caption} ${note.episode.getDate()}",
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        ],
      ),
    );
  }

  _buildNoteContent(Note note) {
    // 笔记内容为空，但有图片，则不显示笔记内容
    if (note.noteContent.isEmpty && note.relativeLocalImages.isNotEmpty) {
      return Container();
    }

    return Container(
      alignment: Alignment.centerLeft,
      // 左填充15，这样就和图片对齐了
      padding: const EdgeInsets.fromLTRB(15, 0, 15, 10),
      child: Text(
        // 笔记内容为空，而且没有图片，那么提示空笔记
        note.noteContent.isEmpty && note.relativeLocalImages.isEmpty
            ? '什么都没有写'
            : note.noteContent,
        maxLines: 10,
        overflow: TextOverflow.ellipsis,
        style: AppTheme.noteStyle,
      ),
    );
  }

  _buildMoreButton(Note note) {
    return IconButton(
      visualDensity: VisualDensity.compact,
      splashRadius: 24,
      icon: const Icon(Icons.more_horiz),
      onPressed: () => _showMoreDialog(note),
    );
  }

  Future<dynamic> _showMoreDialog(Note note) {
    return showDialog(
        context: context,
        builder: (dialogContext) {
          return SimpleDialog(
            children: [
              ListTile(
                leading: const Icon(Icons.edit),
                title: const Text("编辑"),
                onTap: () {
                  Navigator.pop(dialogContext);
                  _enterNoteEditPage(note);
                },
              ),
              ListTile(
                leading: const Icon(Icons.copy_rounded),
                title: const Text("复制内容"),
                onTap: () {
                  CommonUtil.copyContent(note.noteContent);
                  Navigator.pop(dialogContext);
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete_outline),
                title: const Text("删除笔记"),
                onTap: () {
                  Navigator.pop(dialogContext);

                  _dialogDeleteConfirm(note);
                },
              )
            ],
          );
        });
  }

  _dialogDeleteConfirm(Note note) async {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("确定要删除吗？"),
          content: const Text("删除的笔记将无法找回"),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text("取消"),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(context);

                if (await NoteDao.deleteNoteById(note.id)) {
                  if (widget.removeNote != null) {
                    widget.removeNote!();
                  }
                } else {
                  ToastUtil.showText("删除失败！");
                }
              },
              child: Text(
                "删除",
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            )
          ],
        );
      },
    );
  }
}

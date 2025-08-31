import 'package:flutter/material.dart';
import 'package:animetrace/dao/note_dao.dart';
import 'package:animetrace/pages/modules/note_edit.dart';
import 'package:animetrace/utils/common_util.dart';
import 'package:animetrace/values/values.dart';
import 'package:animetrace/utils/toast_util.dart';
import 'package:animetrace/components/anime_list_cover.dart';
import 'package:animetrace/components/note/note_img_grid.dart';
import 'package:animetrace/models/note.dart';
import 'package:animetrace/utils/time_util.dart';
import 'package:animetrace/widgets/common_divider.dart';
import 'package:ming_cute_icons/ming_cute_icons.dart';

/// 笔记卡片
/// 使用：所有笔记页、所有评价页、动漫详细评价页
/// 提取到该Widget，目的是为了从编辑页返回后，setState重绘这一个卡片，而不是整个页面
class NoteCard extends StatefulWidget {
  final Note note;
  final void Function()? onDeleted;
  final void Function()? enterAnimeDetail;
  final bool showAnimeTile;
  final bool isRateNote;

  const NoteCard(this.note,
      {this.onDeleted,
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

  Future<void> _enterNoteEditPage(Note note) async {
    final newNote = await Navigator.of(context)
        .push(MaterialPageRoute(builder: (context) => NoteEditPage(note)));
    if (newNote == null) {
      widget.onDeleted?.call();
    } else if (newNote is Note) {
      setState(() {});
    }
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
      subtitle: GestureDetector(
        onTap: _enterAnimeDetailPage,
        child: Text(
          widget.isRateNote
              ? rateTimeStr
              : "${note.episode.caption} ${note.episode.getDate()}",
          style: Theme.of(context).textTheme.bodySmall,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
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
                leading: const Icon(MingCuteIcons.mgc_edit_4_line, size: 22),
                title: const Text("编辑"),
                onTap: () {
                  Navigator.pop(dialogContext);
                  _enterNoteEditPage(note);
                },
              ),
              ListTile(
                leading: const Icon(MingCuteIcons.mgc_copy_line, size: 22),
                title: const Text("复制内容"),
                onTap: () {
                  CommonUtil.copyContent(note.noteContent);
                  Navigator.pop(dialogContext);
                },
              ),
              ListTile(
                leading: const Icon(MingCuteIcons.mgc_delete_3_line, size: 22),
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
                  widget.onDeleted?.call();
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

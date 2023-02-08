import 'package:flutter/material.dart';
import 'package:flutter_test_future/models/episode.dart';
import 'package:flutter_test_future/utils/theme_util.dart';

class AnimeDetailEpisodeTile extends StatefulWidget {
  const AnimeDetailEpisodeTile(
      {required this.episode,
      required this.selected,
      this.leading,
      this.trailing,
      this.onTap,
      this.onLongPress,
      super.key});
  final Episode episode;
  final bool selected;
  final Widget? leading;
  final Widget? trailing;
  final void Function()? onTap;
  final void Function()? onLongPress;

  @override
  State<AnimeDetailEpisodeTile> createState() => AnimeDetailEpisodeTileState();
}

class AnimeDetailEpisodeTileState extends State<AnimeDetailEpisodeTile> {
  Color multiSelectedColor = ThemeUtil.getPrimaryColor().withOpacity(0.25);

  get _episode => widget.episode;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      selectedTileColor: multiSelectedColor,
      selected: widget.selected,
      // visualDensity: const VisualDensity(vertical: -2),
      // contentPadding: const EdgeInsets.fromLTRB(15, 0, 15, 0),
      title: Text(
        "第${_episode.number}集",
        style: TextStyle(
          color: ThemeUtil.getEpisodeListTile(_episode.isChecked()),
        ),
        // textScaleFactor: ThemeUtil.smallScaleFactor,
      ),
      // 没有完成时不显示subtitle
      subtitle: widget.episode.isChecked()
          ? Text(
              widget.episode.getDate(),
              style: TextStyle(
                color: ThemeUtil.getEpisodeListTile(_episode.isChecked()),
              ),
              textScaleFactor: ThemeUtil.smallScaleFactor,
            )
          : null,
      leading: widget.leading,
      trailing: widget.trailing,
      onTap: widget.onTap,
      onLongPress: widget.onLongPress,
    );
  }
}

import 'package:animetrace/global.dart';
import 'package:flutter/material.dart';
import 'package:animetrace/pages/anime_air_date_list/anime_air_date_list_page.dart';
import 'package:animetrace/pages/network/directory/directory_page.dart';
import 'package:animetrace/pages/network/sources/pages/lapse_cover_fix/lapse_cover_animes_page.dart';
import 'package:animetrace/pages/network/weekly/weekly.dart';
import 'package:animetrace/pages/settings/image_wall/note_image_wall.dart';
import 'package:animetrace/routes/get_route.dart';
import 'package:ming_cute_icons/ming_cute_icons.dart';

import '../pages/dedup/dedup_page.dart';
import '../pages/trace/view.dart';

class ToolsPage extends StatelessWidget {
  const ToolsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return _buildToolsChipView(context);
  }

  _buildToolsChipView(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(15, 5, 15, 20),
      child: Wrap(
        spacing: 4,
        children: [
          GestureDetector(
              onTap: () => _toDedupPage(context),
              child: const Chip(
                  avatar: Icon(Icons.filter_alt), label: Text('动漫去重'))),
          if (FeatureFlag.enableFixCover)
            GestureDetector(
              onTap: () {
                RouteUtil.materialTo(context, const LapseCoverAnimesPage());
              },
              child: const Chip(
                avatar: Icon(Icons.broken_image_outlined),
                label: Text('修复封面'),
              ),
            ),
          GestureDetector(
              onTap: () => _toTracePage(context),
              child:
                  const Chip(avatar: Icon(Icons.timeline), label: Text('总览'))),
          if (FeatureFlag.enableSelectLocalImage)
            GestureDetector(
                onTap: () => _toNoteImageWallPage(context),
                child: const Chip(
                    avatar: Icon(MingCuteIcons.mgc_film_line),
                    label: Text('照片墙'))),
          GestureDetector(
              onTap: () {
                RouteUtil.materialTo(context, const AnimeAirDateListPage());
              },
              child: const Chip(
                  avatar: Icon(MingCuteIcons.mgc_time_line),
                  label: Text('时间线'))),
          GestureDetector(
              onTap: () {
                RouteUtil.materialTo(context, const WeeklyPage());
              },
              child: const Chip(
                  avatar: Icon(MingCuteIcons.mgc_calendar_month_line),
                  label: Text('周表'))),
          GestureDetector(
            onTap: () {
              RouteUtil.materialTo(context, const DirectoryPage());
            },
            child: const Chip(
              avatar: Icon(Icons.format_list_bulleted),
              label: Text('目录'),
            ),
          ),
        ],
      ),
    );
  }

  void _toNoteImageWallPage(BuildContext context) {
    Navigator.of(context).push(
        MaterialPageRoute(builder: (context) => const NoteImageWallPage()));
  }

  _toTracePage(BuildContext context) {
    Navigator.of(context)
        .push(MaterialPageRoute(builder: (context) => const TracePage()));
  }

  _toDedupPage(BuildContext context) {
    Navigator.of(context)
        .push(MaterialPageRoute(builder: (context) => const DedupPage()));
  }
}

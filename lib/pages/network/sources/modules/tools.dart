import 'package:flutter/material.dart';
import 'package:flutter_test_future/pages/settings/image_wall/note_image_wall.dart';
import 'package:ming_cute_icons/ming_cute_icons.dart';

import '../../../../components/website_logo.dart';
import '../../../../models/fav_website.dart';
import '../../../../utils/launch_uri_util.dart';
import '../pages/dedup/dedup_page.dart';
import '../pages/trace/view.dart';

class ToolsPage extends StatelessWidget {
  const ToolsPage({super.key});

  double get buttonSize => 40.0;
  double get itemHeight => 100.0;
  double get itemWidth => 120.0;
  get favWebsite => FavWebsite(
      url: "https://bgmlist.com/",
      icoUrl: "assets/images/website/fzff.png",
      name: "番组放送");

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
              onTap: () => _openFanZuFangSong(context),
              child: Chip(
                  avatar: WebSiteLogo(url: favWebsite.icoUrl, size: 18),
                  // avatar: Icon(Icons.view_week),
                  label: const Text('番组放送'))),
          GestureDetector(
              onTap: () => _toDedupPage(context),
              child: const Chip(
                  avatar: Icon(Icons.filter_alt), label: Text('动漫去重'))),
          GestureDetector(
              onTap: () => _toTracePage(context),
              child:
                  const Chip(avatar: Icon(Icons.timeline), label: Text('总览'))),
          GestureDetector(
              onTap: () => _toNoteImageWallPage(context),
              child: const Chip(
                  avatar: Icon(MingCuteIcons.mgc_film_line),
                  label: Text('照片墙'))),
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

  _openFanZuFangSong(BuildContext context) =>
      LaunchUrlUtil.launch(context: context, uriStr: favWebsite.url);
}

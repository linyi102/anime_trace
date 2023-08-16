import 'package:flutter/material.dart';
import 'package:ming_cute_icons/ming_cute_icons.dart';

import '../../../../components/website_logo.dart';
import '../../../../models/fav_website.dart';
import '../../../../utils/launch_uri_util.dart';
import '../../../../widgets/icon_text_button.dart';
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
              child: const Chip(
                  avatar: Icon(Icons.timeline), label: Text('历史回顾'))),
        ],
      ),
    );
  }

  _buildToolsListView() {
    return const SingleChildScrollView(
      child: Column(
        children: [
          ListTile(
            // leading: WebSiteLogo(url: favWebsite.icoUrl, size: iconSize),
            leading: Icon(Icons.calendar_month),
            title: Text('番组放送'),
          ),
          ListTile(
            leading: Icon(Icons.filter_alt),
            title: Text('动漫去重'),
          ),
          ListTile(
            leading: Icon(Icons.timeline),
            title: Text('历史回顾'),
          ),
        ],
      ),
    );
  }

  _buildToolsGridView(BuildContext context) {
    var iconSize = 20.0;
    return GridView(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
        mainAxisExtent: 90, // 格子高度
        maxCrossAxisExtent: itemWidth, // 格子最大宽度
      ),
      children: [
        IconTextButton(
          iconSize: buttonSize,
          icon: Container(
            decoration: BoxDecoration(
              color: const Color.fromRGBO(19, 189, 157, 1),
              borderRadius: BorderRadius.circular(99),
            ),
            child: Transform.scale(
              scale: 0.6,
              child: WebSiteLogo(url: favWebsite.icoUrl, size: buttonSize),
            ),
          ),
          text: const Text("番组放送", textScaleFactor: 0.9),
          onTap: () => _openFanZuFangSong(context),
        ),
        // IconTextButton(
        //     iconSize: iconSize,
        //     icon: Container(
        //         decoration: const BoxDecoration(
        //           // color: Theme.of(context).primaryColor,
        //           color: Color.fromRGBO(55, 197, 254, 1),
        //           shape: BoxShape.circle,
        //         ),
        //         child: const Icon(Icons.auto_fix_high_rounded,
        //             size: 18, color: Colors.white)),
        //     text: const Text("封面修复", textScaleFactor: 0.9),
        //     onTap: () => Navigator.of(context).push(MaterialPageRoute(
        //         builder: (context) => const LapseCoverAnimesPage()))),
        IconTextButton(
            iconSize: buttonSize,
            // icon: const Icon(Icons.filter_alt),
            icon: Container(
                decoration: const BoxDecoration(
                  // color: Theme.of(context).primaryColor,
                  color: Color.fromRGBO(255, 199, 87, 1),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.filter_alt,
                    size: iconSize, color: Colors.white)),
            text: const Text("动漫去重", textScaleFactor: 0.9),
            onTap: () => _toDedupPage(context)),
        IconTextButton(
            iconSize: buttonSize,
            // icon: const Icon(Icons.timeline),
            icon: Container(
                decoration: const BoxDecoration(
                  // color: Theme.of(context).primaryColor,
                  color: Colors.redAccent,
                  shape: BoxShape.circle,
                ),
                child: Icon(MingCuteIcons.mgc_road_line,
                    size: iconSize, color: Colors.white)),
            text: const Text("历史回顾", textScaleFactor: 0.9),
            onTap: () => _toTracePage(context)),
      ],
    );
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

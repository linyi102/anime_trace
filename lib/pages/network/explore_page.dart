import 'package:flutter/material.dart';
import 'package:flutter_test_future/pages/network/climb/anime_climb_all_website.dart';
import 'package:flutter_test_future/pages/network/sources/aggregate_page.dart';
import 'package:flutter_test_future/widgets/common_scaffold_body.dart';
import 'package:ming_cute_icons/ming_cute_icons.dart';

/// 探索页
class ExplorePage extends StatefulWidget {
  const ExplorePage({Key? key}) : super(key: key);

  @override
  State<ExplorePage> createState() => _ExplorePageState();
}

class _ExplorePageState extends State<ExplorePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      appBar: AppBar(title: _buildSearchBar()),
      backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
      body: const CommonScaffoldBody(
        child: AggregatePage(),
      ),
    );
  }

  _buildSearchBar() {
    var fg = Theme.of(context).hintColor;
    var radius = BorderRadius.circular(99);

    return Material(
      borderRadius: radius,
      color: Theme.of(context).scaffoldBackgroundColor,
      child: InkWell(
        borderRadius: radius,
        onTap: _enterAnimeClimbAllWebsitePage,
        child: ClipRRect(
          borderRadius: radius,
          child: Container(
            height: 40,
            decoration: BoxDecoration(
              borderRadius: radius,
              border: Border.all(color: Theme.of(context).dividerColor),
            ),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 15),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(MingCuteIcons.mgc_search_line, size: 16, color: fg),
                      const SizedBox(width: 10),
                      Text('搜索动漫', style: TextStyle(fontSize: 14, color: fg)),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _enterAnimeClimbAllWebsitePage() {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (context) {
        return const AnimeClimbAllWebsite();
      },
    ));
  }
}

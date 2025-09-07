import 'package:flutter/material.dart';
import 'package:animetrace/pages/network/climb/anime_climb_all_website.dart';
import 'package:animetrace/pages/network/sources/aggregate_page.dart';
import 'package:animetrace/widgets/common_scaffold_body.dart';
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
      body: SafeArea(
        child: Column(
          children: [
            _buildSearchBar(),
            const Expanded(
              child: CommonScaffoldBody(
                child: AggregatePage(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    final fg = Theme.of(context).hintColor;
    final radius = BorderRadius.circular(32);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 20),
      child: Material(
        borderRadius: radius,
        color: Theme.of(context).colorScheme.surfaceContainer,
        child: InkWell(
          borderRadius: radius,
          onTap: _enterAnimeClimbAllWebsitePage,
          child: ClipRRect(
            borderRadius: radius,
            child: Container(
              height: 52,
              decoration: BoxDecoration(borderRadius: radius),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 15),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(MingCuteIcons.mgc_search_line,
                            size: 16, color: fg),
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

import 'package:animetrace/components/common_image.dart';
import 'package:animetrace/pages/anime_detail/anime_detail.dart';
import 'package:animetrace/values/theme.dart';
import 'package:animetrace/widgets/responsive.dart';
import 'package:flutter/material.dart';
import 'package:animetrace/components/loading_widget.dart';
import 'package:animetrace/components/website_logo.dart';
import 'package:animetrace/controllers/update_record_controller.dart';
import 'package:animetrace/models/anime.dart';
import 'package:animetrace/models/climb_website.dart';
import 'package:animetrace/models/ping_result.dart';
import 'package:animetrace/pages/network/sources/aggregate_logic.dart';
import 'package:animetrace/pages/network/sources/modules/tools.dart';
import 'package:animetrace/pages/network/sources/pages/source_detail_page.dart';
import 'package:animetrace/pages/network/sources/pages/source_list_page.dart';
import 'package:animetrace/pages/network/update/need_update_anime_list.dart';
import 'package:animetrace/pages/network/update/update_record_page.dart';
import 'package:animetrace/routes/get_route.dart';
import 'package:animetrace/utils/climb/climb_anime_util.dart';
import 'package:animetrace/utils/time_util.dart';
import 'package:animetrace/widgets/icon_text_button.dart';
import 'package:animetrace/widgets/setting_title.dart';
import 'package:get/get.dart';
import 'package:percent_indicator/percent_indicator.dart';

/// 聚合页
class AggregatePage extends StatefulWidget {
  const AggregatePage({Key? key}) : super(key: key);

  @override
  State<AggregatePage> createState() => _AggregatePageState();
}

class _AggregatePageState extends State<AggregatePage> {
  AggregateLogic logic = Get.put(AggregateLogic());

  @override
  Widget build(BuildContext context) {
    return GetBuilder(
      init: logic,
      builder: (_) => RefreshIndicator(
        onRefresh: () async {
          logic.loadData();
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            children: [
              _buildClimbWebsiteGridCard(),
              _buildTools(),
              _buildAnimesList(),
              const ListTile(),
            ],
          ),
        ),
      ),
    );
  }

  _buildTools() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildCardTitle("工具"),
        const ToolsPage(),
      ],
    );
  }

  _buildAnimesList() {
    return Column(
      children: [
        Obx(
          () => _buildAnimesSection(
            title: '最近更新',
            loading: logic.loadingRecentUpdateAnimes,
            animes: logic.recentUpdateAnimes,
            specifyItemSubtitle: (anime) => anime.tempInfo,
            trailing: _buildUpdateTrailing(),
          ),
        ),
        _buildAnimesSection(
          title: '最近观看',
          hideWhenEmpty: true,
          loading: logic.loadingRecentWatchedAnimes,
          animes: logic.recentWatchedAnimes,
          specifyItemSubtitle: (anime) {
            final time = DateTime.tryParse(anime.tempInfo ?? '');
            if (time == null) return '';
            return TimeUtil.getTimeAgo(time, pattern: 'yyyy-MM-dd') + ' 观看';
          },
        ),
        _buildAnimesSection(
          title: '今日开播',
          hideWhenEmpty: true,
          loading: logic.loadingAnimesNYearsAgoTodayBroadcast,
          animes: logic.animesNYearsAgoTodayBroadcast,
          specifyItemSubtitle: _parseAnimeYearDistance,
        ),
      ],
    );
  }

  Row _buildSourceTrailing() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          onPressed: logic.pingFinished ? () => logic.pingAllWebsites() : null,
          icon: const Icon(Icons.refresh),
          splashRadius: 18,
          iconSize: 21,
        ),
        IconButton(
          onPressed: () =>
              RouteUtil.materialTo(context, const SourceListPage()),
          icon: const Icon(Icons.arrow_forward),
          splashRadius: 18,
          iconSize: 21,
        ),
      ],
    );
  }

  Row _buildUpdateTrailing() {
    final updateProgress = UpdateRecordController.to.updateProgress;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        UpdateRecordController.to.updating.value
            ? IconButton(
                onPressed: null,
                icon: CircularPercentIndicator(
                  radius: 10,
                  lineWidth: 3,
                  percent: updateProgress,
                  progressColor: Theme.of(context).colorScheme.primary,
                  animation: true,
                  animateFromLastPercent: updateProgress != 0,
                ))
            : IconButton(
                onPressed: () => ClimbAnimeUtil.updateAllAnimesInfo(),
                icon: const Icon(Icons.refresh),
                splashRadius: 18,
                iconSize: 21,
              ),
        IconButton(
          onPressed: () =>
              RouteUtil.materialTo(context, const NeedUpdateAnimeList()),
          icon: const Icon(Icons.date_range),
          splashRadius: 18,
          iconSize: 21,
        ),
        IconButton(
          onPressed: () =>
              RouteUtil.materialTo(context, const UpdateRecordPage()),
          icon: const Icon(Icons.arrow_forward),
          splashRadius: 18,
          iconSize: 21,
        ),
      ],
    );
  }

  String _parseAnimeYearDistance(Anime anime) {
    final year = DateTime.tryParse(anime.premiereTime)?.year;
    if (year == null) return '';

    final diff = DateTime.now().year - year;
    String text = '';
    text = diff == 0 ? '今天' : '$diff 年前的今天';
    return text;
  }

  Widget _buildAnimesSection({
    required String title,
    required List<Anime> animes,
    required bool loading,
    Widget? trailing,
    String? Function(Anime anime)? specifyItemSubtitle,
    bool hideWhenEmpty = false,
  }) {
    if (animes.isEmpty && hideWhenEmpty) {
      return const SizedBox.shrink();
    }

    const defaultHeight = 50.0;

    return Column(
      children: [
        _buildCardTitle(title, trailing: trailing),
        const SizedBox(height: 10),
        loading
            ? const SizedBox(
                height: defaultHeight, child: Center(child: LoadingWidget()))
            : animes.isEmpty
                ? Container(
                    height: defaultHeight,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: const Row(
                      children: [Text('无')],
                    ))
                : _HorizontalAnimeListPage(
                    animes: animes,
                    specifyItemSubtitle: specifyItemSubtitle,
                  ),
        const SizedBox(height: 20),
      ],
    );
  }

  _buildClimbWebsiteGridCard() {
    return Column(
      children: [
        _buildCardTitle("搜索源", trailing: _buildSourceTrailing()),
        SizedBox(
          height: 100,
          child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 10),
              itemCount: logic.usableWebsites.length,
              itemBuilder: (context, index) {
                ClimbWebsite climbWebsite = logic.usableWebsites[index];
                return SizedBox(
                  width: 80,
                  child: IconTextButton(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 5, vertical: 10),
                      margin: const EdgeInsets.symmetric(
                          vertical: 10, horizontal: 5),
                      onTap: () => _enterSourceDetail(climbWebsite),
                      icon: Stack(
                        children: [
                          WebSiteLogo(url: climbWebsite.iconUrl, size: 40),
                          _buildPingStatus(climbWebsite.pingStatus)
                        ],
                      ),
                      text: Text(
                        climbWebsite.name,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(height: 1.1, fontSize: 13),
                      )),
                );
              }),
        ),
      ],
    );
  }

  _buildCardTitle(String title, {Widget? trailing}) {
    return SettingTitle(
      title: title,
      trailing: trailing,
    );
    // return ListTile(
    //   title: Text(title, style: const TextStyle(fontSize: 16)),
    //   trailing: trailing,
    // );
  }

  Positioned _buildPingStatus(PingStatus pingStatus) {
    return Positioned(
      right: 0,
      bottom: 0,
      child: Container(
        height: 12,
        width: 12,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Theme.of(context).appBarTheme.backgroundColor,
        ),
        child: Icon(Icons.circle, size: 10, color: pingStatus.color),
      ),
    );
  }

  _enterSourceDetail(ClimbWebsite climbWebsite) {
    Navigator.of(context).push(MaterialPageRoute(builder: (context) {
      return SourceDetail(climbWebsite);
    }));
  }
}

class _HorizontalAnimeListPage extends StatelessWidget {
  const _HorizontalAnimeListPage({
    required this.animes,
    this.specifyItemSubtitle,
  });
  final List<Anime> animes;
  final String? Function(Anime anime)? specifyItemSubtitle;

  AggregateLogic get logic => AggregateLogic.to;

  @override
  Widget build(BuildContext context) {
    return GetBuilder(
      init: logic,
      builder: (_) => Responsive(
        mobile: _buildListView(110),
        desktop: _buildListView(140),
      ),
    );
  }

  Widget _buildListView(double coverWidth) {
    final itemHeight = (coverWidth / 0.72) + 40;

    return SizedBox(
      height: itemHeight,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 10),
        scrollDirection: Axis.horizontal,
        itemCount: animes.length,
        itemBuilder: (context, index) {
          final anime = animes[index];
          return _CommonCover(
            width: coverWidth,
            coverUrl: anime.animeCoverUrl,
            title: anime.animeName,
            subtitle: specifyItemSubtitle?.call(anime),
            onTap: () async {
              Anime value = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => AnimeDetailPage(anime),
                  ));
              anime.animeName = value.animeName;
              anime.animeCoverUrl = value.animeCoverUrl;
              logic.update();
            },
          );
        },
      ),
    );
  }
}

class _CommonCover extends StatefulWidget {
  const _CommonCover({
    this.onTap,
    this.width = 100,
    this.coverUrl,
    this.title,
    this.subtitle,
    // ignore: unused_element
    this.bottomRightText,
  });

  final GestureTapCallback? onTap;
  final double? width;
  final String? coverUrl;
  final String? title;
  final String? subtitle;
  final String? bottomRightText;

  @override
  State<_CommonCover> createState() => _CommonCoverState();
}

class _CommonCoverState extends State<_CommonCover> {
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 2),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppTheme.imgRadius),
        onTap: widget.onTap,
        child: _buildItem(),
      ),
    );
  }

  Widget _buildItem() {
    return Container(
      width: widget.width,
      padding: const EdgeInsets.all(3),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Stack(
              fit: StackFit.expand,
              children: [
                if (widget.coverUrl != null) _buildImage(),
                if (widget.bottomRightText != null) _buildBottomShadow(),
                if (widget.bottomRightText != null) _buildBottomRightText()
              ],
            ),
          ),
          const SizedBox(height: 5),
          if (widget.title != null)
            Text(
              widget.title ?? '',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 14),
            ),
          if (widget.subtitle != null)
            Text(
              widget.subtitle ?? '',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style:
                  TextStyle(fontSize: 12, color: Theme.of(context).hintColor),
            ),
        ],
      ),
    );
  }

  ClipRRect _buildImage() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppTheme.imgRadius),
      child: CommonImage(
        widget.coverUrl!,
        reduceMemCache: true,
      ),
    );
  }

  Container _buildBottomRightText() {
    return Container(
      // 使用Align替换Positioned，可以保证在Stack下自适应父元素宽度
      alignment: Alignment.bottomRight,
      child: Container(
        padding: const EdgeInsets.fromLTRB(5, 0, 10, 5),
        child: Text(
          widget.bottomRightText ?? '',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
            shadows: [
              Shadow(blurRadius: 3, color: Colors.black),
            ],
          ),
        ),
      ),
    );
  }

  Column _buildBottomShadow() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Container(
          height: 40,
          decoration: BoxDecoration(
              borderRadius: BorderRadius.vertical(
                  bottom: Radius.circular(AppTheme.imgRadius)),
              gradient: const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Color.fromRGBO(0, 0, 0, 0.6),
                  ])),
        ),
      ],
    );
  }
}

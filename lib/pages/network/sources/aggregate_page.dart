import 'package:flutter/material.dart';
import 'package:flutter_test_future/components/loading_widget.dart';
import 'package:flutter_test_future/components/website_logo.dart';
import 'package:flutter_test_future/controllers/update_record_controller.dart';
import 'package:flutter_test_future/models/anime.dart';
import 'package:flutter_test_future/models/climb_website.dart';
import 'package:flutter_test_future/models/ping_result.dart';
import 'package:flutter_test_future/pages/network/sources/aggregate_logic.dart';
import 'package:flutter_test_future/pages/network/sources/modules/horizontal_anime_list.dart';
import 'package:flutter_test_future/pages/network/sources/modules/tools.dart';
import 'package:flutter_test_future/pages/network/sources/pages/source_detail_page.dart';
import 'package:flutter_test_future/pages/network/sources/pages/source_list_page.dart';
import 'package:flutter_test_future/pages/network/update/need_update_anime_list.dart';
import 'package:flutter_test_future/pages/network/update/update_record_page.dart';
import 'package:flutter_test_future/routes/get_route.dart';
import 'package:flutter_test_future/utils/climb/climb_anime_util.dart';
import 'package:flutter_test_future/utils/time_util.dart';
import 'package:flutter_test_future/widgets/icon_text_button.dart';
import 'package:flutter_test_future/widgets/setting_title.dart';
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
          () => _buildAnimesListItem(
            title: '最近更新',
            loading: logic.loadingRecentUpdateAnimes,
            animes: logic.recentUpdateAnimes,
            specifyItemSubtitle: (anime) => anime.tempInfo,
            trailing: _buildUpdateTrailing(),
          ),
        ),
        _buildAnimesListItem(
          title: '最近观看',
          loading: logic.loadingRecentWatchedAnimes,
          animes: logic.recentWatchedAnimes,
          specifyItemSubtitle: (anime) {
            final time = DateTime.tryParse(anime.tempInfo ?? '');
            if (time == null) return '';
            return TimeUtil.getTimeAgo(time, pattern: 'yyyy-MM-dd') + ' 观看';
          },
        ),
        _buildAnimesListItem(
          title: '今日开播',
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

  _buildAnimesListItem({
    required String title,
    required List<Anime> animes,
    required bool loading,
    Widget? trailing,
    String? Function(Anime anime)? specifyItemSubtitle,
  }) {
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
                : HorizontalAnimeListPage(
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

import 'dart:math';

import 'package:flutter/material.dart';
import 'package:animetrace/components/loading_widget.dart';
import 'package:animetrace/dao/history_dao.dart';
import 'package:animetrace/models/anime.dart';
import 'package:animetrace/models/data_state.dart';
import 'package:animetrace/models/review_info.dart';
import 'package:animetrace/utils/time_util.dart';

class AnimeReviewInfoView extends StatefulWidget {
  const AnimeReviewInfoView(
      {super.key, required this.anime, required this.onSelect});
  final Anime anime;
  final void Function(int reviewNumber) onSelect;

  @override
  State<AnimeReviewInfoView> createState() => _AnimeReviewInfoViewState();
}

class _AnimeReviewInfoViewState extends State<AnimeReviewInfoView> {
  var reviewState = DataState<List<ReviewInfo>>.loading();

  @override
  void initState() {
    super.initState();
    _loadAllReviewInfos().then((value) {
      setState(() {
        reviewState = reviewState.toData(value);
      });
    }).onError((error, stackTrace) {
      setState(() {
        reviewState = reviewState.toError(
          error: error ?? Exception('加载错误'),
          stackTrace: stackTrace,
        );
      });
    });
  }

  Future<List<ReviewInfo>> _loadAllReviewInfos() async {
    final watchedReviewInfos = await _getReviewInfos();
    // 将历史的最大观看次数和当前选择的观看次数比较，避免无法多次点击新增按钮
    // 例如当前获取的历史最大次数为1，点击新增按钮后次数为2，而历史的最大次数仍然为1，再次点击新增按钮可设置次数为3
    final maxReviewNumber =
        max(watchedReviewInfos.length, widget.anime.reviewNumber);

    final allReviewInfos = [...watchedReviewInfos];
    // 填充临时添加的没有任何记录的ReviewInfo
    for (int i = 0; i < maxReviewNumber - watchedReviewInfos.length; i++) {
      final lastReviewNumber =
          allReviewInfos.isEmpty ? 0 : allReviewInfos.last.number;
      allReviewInfos.add(ReviewInfo.empty(
          number: lastReviewNumber + 1, total: widget.anime.animeEpisodeCnt));
    }
    return allReviewInfos;
  }

  Future<List<ReviewInfo>> _getReviewInfos() async {
    final animeId = widget.anime.animeId;
    final maxReviewNumber = await HistoryDao.getMaxReviewNumber(animeId);
    final List<ReviewInfo> reviewInfos = [];
    for (int reviewNumber = 1;
        reviewNumber <= maxReviewNumber;
        reviewNumber++) {
      reviewInfos.add(ReviewInfo(
        number: reviewNumber,
        checked: await HistoryDao.getAnimeWatchedCount(animeId, reviewNumber),
        total: widget.anime.animeEpisodeCnt,
        minDate: TimeUtil.getYMD(
            await HistoryDao.getWatchedMinDate(animeId, reviewNumber)),
        maxDate: TimeUtil.getYMD(
            await HistoryDao.getWatchedMaxDate(animeId, reviewNumber)),
      ));
    }
    return reviewInfos;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('回顾'),
        automaticallyImplyLeading: false,
        actions: [
          if (reviewState.hasValue)
            TextButton(
                onPressed: () =>
                    widget.onSelect((reviewState.value?.last.number ?? 0) + 1),
                child: const Text('添加'))
        ],
      ),
      body: reviewState.when(
        data: (data) => _buildListView(data),
        error: (error, stackTrace, message) =>
            Center(child: Text(error.toString())),
        loading: (message) => const LoadingWidget(),
      ),
    );
  }

  ListView _buildListView(List<ReviewInfo> reviewInfos) {
    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 24),
      itemCount: reviewInfos.length,
      itemBuilder: (context, index) {
        final info = reviewInfos[index];
        final selected = widget.anime.reviewNumber == info.number;
        return ListTile(
          leading: Container(
            height: 30,
            width: 30,
            decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: selected
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).colorScheme.primaryContainer),
            child: Center(
              child: Text(
                info.number.toString(),
                style: TextStyle(
                    color: selected
                        ? Theme.of(context).colorScheme.onPrimary
                        : Theme.of(context).colorScheme.onPrimaryContainer),
              ),
            ),
          ),
          selected: selected,
          title: Text('${info.checked} / ${info.total}'),
          subtitle: _buildDateRange(info),
          onTap: () => widget.onSelect(info.number),
        );
      },
    );
  }

  Text? _buildDateRange(ReviewInfo info) {
    if (info.minDate.isEmpty && info.maxDate.isEmpty) return null;
    return Text(info.minDate == info.maxDate
        ? info.minDate
        : '${info.minDate} ~ ${info.maxDate}');
  }
}

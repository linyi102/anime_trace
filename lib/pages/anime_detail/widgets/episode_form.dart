import 'package:flutter/material.dart';
import 'package:flutter_test_future/components/dialog/dialog_select_uint.dart';
import 'package:flutter_test_future/models/anime.dart';
import 'package:flutter_test_future/models/anime_episode_info.dart';
import 'package:flutter_test_future/utils/toast_util.dart';

class EpisodeForm extends StatefulWidget {
  const EpisodeForm({required this.anime, super.key});
  final Anime anime;

  @override
  State<EpisodeForm> createState() => _EpisodeFormState();
}

class _EpisodeFormState extends State<EpisodeForm> {
  late final episodeCntController =
      TextEditingController(text: '${widget.anime.animeEpisodeCnt}');
  late final episodeStartNumberController =
      TextEditingController(text: '${widget.anime.episodeStartNumber}');
  late bool calEpisodeNumberFromOne = widget.anime.calEpisodeNumberFromOne;

  int episodeCntMinValue = 0, episodeCntMaxValue = 2000;
  int episodeStartNumberMinValue = 0, episodeStartNumberMaxValue = 2000;
  int get totalCnt => int.tryParse(episodeCntController.text) ?? 0;
  int get startNumber => int.tryParse(episodeStartNumberController.text) ?? 0;

  @override
  void dispose() {
    episodeCntController.dispose();
    episodeStartNumberController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 10),
              Row(
                children: [
                  const Text('总集数'),
                  const SizedBox(width: 30),
                  Expanded(
                    child: NumberControlInputField(
                      controller: episodeCntController,
                      minValue: episodeCntMinValue,
                      maxValue: episodeCntMaxValue,
                      initialValue: widget.anime.animeEpisodeCnt,
                      onChanged: (number) {
                        setState(() {});
                      },
                      showRangeHintText: false,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  const Text('起始集'),
                  const SizedBox(width: 30),
                  Expanded(
                    child: NumberControlInputField(
                      controller: episodeStartNumberController,
                      minValue: episodeStartNumberMinValue,
                      maxValue: episodeStartNumberMaxValue,
                      initialValue: widget.anime.episodeStartNumber,
                      onChanged: (number) {
                        setState(() {});
                      },
                      showRangeHintText: false,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('从第 1 集计数'),
                  value: calEpisodeNumberFromOne,
                  onChanged: (value) {
                    setState(() {
                      calEpisodeNumberFromOne = value;
                    });
                  }),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('预览'),
                trailing: Container(
                  margin: const EdgeInsets.only(right: 5),
                  child: Text(
                    totalCnt == 0
                        ? '0'
                        : calEpisodeNumberFromOne
                            ? '1-$totalCnt'
                            : '$startNumber-${startNumber - 1 + totalCnt}',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
              onPressed: () {
                Navigator.pop(context, null);
              },
              child: const Text("取消")),
          TextButton(
              onPressed: () {
                if (episodeCntController.text.isEmpty) {
                  ToastUtil.showText("不能为空！");
                  return;
                }
                int? inputEpisodeCnt = int.tryParse(episodeCntController.text);
                if (inputEpisodeCnt == null) {
                  return;
                }
                if (inputEpisodeCnt < episodeCntMinValue ||
                    inputEpisodeCnt > episodeCntMaxValue) {
                  ToastUtil.showText(
                      "集数设置范围：[$episodeCntMinValue, $episodeCntMaxValue]");
                  return;
                }

                if (episodeStartNumberController.text.isEmpty) {
                  ToastUtil.showText("不能为空！");
                  return;
                }
                int? inputEpisodeStartNumber =
                    int.tryParse(episodeStartNumberController.text);
                if (inputEpisodeStartNumber != null &&
                        inputEpisodeStartNumber < episodeStartNumberMinValue ||
                    inputEpisodeStartNumber! > episodeStartNumberMaxValue) {
                  ToastUtil.showText(
                      "起始集设置范围：[$episodeStartNumberMinValue, $episodeStartNumberMaxValue]");
                  return;
                }

                Navigator.pop(
                    context,
                    AnimeEpisodeInfo(
                      totalCnt: inputEpisodeCnt,
                      startNumber: inputEpisodeStartNumber,
                      calNumberFromOne: calEpisodeNumberFromOne,
                    ));
              },
              child: const Text("确定")),
        ]);
  }
}

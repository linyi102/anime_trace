import 'package:animetrace/components/anime_cover.dart';
import 'package:animetrace/models/anime.dart';
import 'package:animetrace/widgets/picker/single_select_dialog.dart';
import 'package:flutter/material.dart';

class AnimeCoverCustomPage extends StatefulWidget {
  const AnimeCoverCustomPage({super.key});

  @override
  State<AnimeCoverCustomPage> createState() => _AnimeCoverCustomPageState();
}

class _AnimeCoverCustomPageState extends State<AnimeCoverCustomPage> {
  AnimeCoverStyle style = const AnimeCoverStyle();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('封面样式')),
      body: Column(
        children: [
          SizedBox(
            height: 320,
            child: CustomAnimeCover(
              width: 160,
              anime: Anime(
                // TODO 固定示例
                animeId: 1,
                animeName: '辉夜大小姐想让我告白～天才们的恋爱头脑战～ 第三季',
                checkedEpisodeCnt: 4,
                animeEpisodeCnt: 10,
                animeCoverUrl: 'https://picsum.photos/300/200',
                hasJoinedSeries: true,
              ),
              style: style,
            ),
          ),
          const Divider(),
          Expanded(
            child: _CustomAnimeCoverStylePanel(
              style: style,
              onChanged: (newStyle) {
                setState(() => style = newStyle);
                // TODO 保存和获取
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _CustomAnimeCoverStylePanel extends StatefulWidget {
  final AnimeCoverStyle style;
  final ValueChanged<AnimeCoverStyle> onChanged;

  const _CustomAnimeCoverStylePanel({
    required this.style,
    required this.onChanged,
  });

  @override
  State<_CustomAnimeCoverStylePanel> createState() =>
      _CustomAnimeCoverStylePanelState();
}

class _CustomAnimeCoverStylePanelState
    extends State<_CustomAnimeCoverStylePanel> {
  late AnimeCoverStyle style;

  @override
  void initState() {
    super.initState();
    style = widget.style;
  }

  void updateStyle(AnimeCoverStyle newStyle) {
    setState(() => style = newStyle);
    widget.onChanged(newStyle);
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        ListTile(
          title: const Text('名字位置'),
          subtitle: Text(style.namePlacement.label),
          onTap: () async {
            final r = await SingleSelectDialog(
              title: const Text('选择位置'),
              value: style.namePlacement,
              options: const [
                Placement.bottomInCover,
                Placement.bottomOutCover,
                Placement.none
              ],
              labelBuilder: (placement) => Text(placement.label),
            ).show(context);
            if (r != null) {
              updateStyle(style.copyWith(namePlacement: r));
            }
          },
        ),
        ListTile(
          title: const Text('进度条'),
          subtitle: Text(style.progressLinearPlacement.label),
          onTap: () async {
            final r = await SingleSelectDialog(
              title: const Text('选择位置'),
              value: style.progressLinearPlacement,
              options: const [
                Placement.bottomInCover,
                Placement.bottomOutCover,
                Placement.none
              ],
              labelBuilder: (placement) => Text(placement.label),
            ).show(context);
            if (r != null) {
              updateStyle(style.copyWith(progressLinearPlacement: r));
            }
          },
        ),
        ListTile(
          title: const Text('进度'),
          subtitle: Text(style.progressNumberPlacement.label),
          onTap: () async {
            final r = await SingleSelectDialog(
              title: const Text('选择位置'),
              value: style.progressNumberPlacement,
              options: const [
                Placement.topLeft,
                Placement.topRight,
                Placement.none
              ],
              labelBuilder: (placement) => Text(placement.label),
            ).show(context);
            if (r != null) {
              updateStyle(style.copyWith(progressNumberPlacement: r));
            }
          },
        ),
        ListTile(
          title: const Text('系列'),
          subtitle: Text(style.seriesPlacement.label),
          onTap: () async {
            final r = await SingleSelectDialog(
              title: const Text('选择位置'),
              value: style.seriesPlacement,
              options: const [
                Placement.topLeft,
                Placement.topRight,
                Placement.none
              ],
              labelBuilder: (placement) => Text(placement.label),
            ).show(context);
            if (r != null) {
              updateStyle(style.copyWith(seriesPlacement: r));
            }
          },
        ),
        ListTile(
          title: const Text('名字行数'),
          subtitle: Text(style.maxNameLines.toString()),
          onTap: () async {
            final r = await SingleSelectDialog(
              title: const Text('选择行数'),
              value: style.maxNameLines,
              options: const [1, 2, 3],
              labelBuilder: (line) => Text(line.toString()),
            ).show(context);
            if (r != null) {
              updateStyle(style.copyWith(maxNameLines: r));
            }
          },
        ),
      ],
    );
  }
}

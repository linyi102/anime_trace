import 'package:animetrace/models/anime.dart';
import 'package:animetrace/models/bangumi/character.dart';
import 'package:animetrace/modules/load_status/load_status.dart';
import 'package:animetrace/modules/load_status/page.dart';
import 'package:animetrace/pages/bangumi/bind_subject/view.dart';
import 'package:animetrace/pages/viewer/network_image/network_image_page.dart';
import 'package:animetrace/routes/get_route.dart';
import 'package:animetrace/utils/string.dart';
import 'package:animetrace/values/theme.dart';
import 'package:flutter/material.dart';
import 'package:animetrace/components/common_image.dart';
import 'package:animetrace/pages/bangumi/subject_detail/logic.dart';
import 'package:get/get.dart' hide GetDynamicUtils;

class BangumiSubjectDetailPage extends StatefulWidget {
  const BangumiSubjectDetailPage(this.anime, {super.key});
  final Anime anime;

  @override
  State<BangumiSubjectDetailPage> createState() =>
      BangumiSubjectDetailPageState();
}

class BangumiSubjectDetailPageState extends State<BangumiSubjectDetailPage> {
  late final logic = Get.put(BangumiSubjectDetailLogic(widget.anime));

  @override
  void dispose() {
    super.dispose();
    Get.delete<BangumiSubjectDetailLogic>();
  }

  @override
  Widget build(BuildContext context) {
    return GetBuilder(
      init: logic,
      builder: (_) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('角色'),
          ),
          body: LoadStatusBuilder(
            controller: logic.loadStatusController,
            builder: (context) {
              if (logic.subjectId.isEmpty) {
                return BaseEmptyPage(
                  msg: '非 Bangumi 动漫需要首次进行关联',
                  buttonText: '搜索',
                  onTap: () async {
                    final anime = await RouteUtil.materialTo<Anime>(
                        context, BindBgmSubjectView(widget.anime.animeName));
                    if (anime != null) logic.bindBgmSubject(anime);
                  },
                );
              }
              return _buildCharacters();
            },
          ),
        );
      },
    );
  }

  GridView _buildCharacters() {
    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 500,
        mainAxisExtent: 72,
      ),
      itemCount: logic.characters.length,
      itemBuilder: (BuildContext context, int index) {
        final character = logic.characters[index];
        return _buildCharacterItem(character);
      },
    );
  }

  Widget _buildCharacterItem(BgmCharacter character) {
    final borderRadius = BorderRadius.circular(AppTheme.imgRadius);
    return Align(
      alignment: Alignment.centerLeft,
      child: ListTile(
        leading: InkWell(
          borderRadius: borderRadius,
          onTap: () => RouteUtil.toImageViewer(
              context, NetworkImageViewPage(character.images?.large ?? '')),
          child: ClipRRect(
            borderRadius: borderRadius,
            child: SizedBox(
              height: 42,
              width: 42,
              child: CommonImage(
                character.images?.grid ?? '',
                alignment: Alignment.topCenter,
              ),
            ),
          ),
        ),
        title: Text(
          character.name ?? '',
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: _buildSubtitle(character),
        trailing: character.comment == null || character.comment == 0
            ? null
            : Text('(+${character.comment})'),
        onTap: () => logic.toDetail(context, character),
      ),
    );
  }

  Row _buildSubtitle(BgmCharacter character) {
    final actors = character.actors?.isNotEmpty == true
        ? character.actors!
            .map((e) => e.name ?? '')
            .where((name) => name.isNotEmpty)
            .join(' / ')
        : '';
    return Row(
      children: [
        if (character.relation?.isNullOrBlank == false) ...[
          Text('${character.relation}'),
          if (actors.isNotEmpty) const Text(' · '),
        ],
        Expanded(
          child: Text(actors, overflow: TextOverflow.ellipsis),
        )
      ],
    );
  }
}

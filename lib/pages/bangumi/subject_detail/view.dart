import 'package:flutter/material.dart';
import 'package:flutter_test_future/components/common_image.dart';
import 'package:flutter_test_future/pages/bangumi/subject_detail/logic.dart';
import 'package:flutter_test_future/utils/string.dart';
import 'package:flutter_test_future/values/theme.dart';
import 'package:get/get.dart' hide GetDynamicUtils;

class BangumiSubjectDetailPage extends StatefulWidget {
  const BangumiSubjectDetailPage({super.key});

  @override
  State<BangumiSubjectDetailPage> createState() =>
      BangumiSubjectDetailPageState();
}

class BangumiSubjectDetailPageState extends State<BangumiSubjectDetailPage> {
  final logic = Get.put(BangumiSubjectDetailLogic());

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
          appBar: AppBar(),
          body: SingleChildScrollView(
            child: Column(
              children: [
                GridView(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2, mainAxisExtent: 60),
                  children: [
                    for (final character in logic.characters
                        // .sublist(0, 8.clamp(0, logic.characters.length))
                        )
                      ListTile(
                        leading: ClipRRect(
                          borderRadius:
                              BorderRadius.circular(AppTheme.imgRadius),
                          child: SizedBox(
                            height: 40,
                            width: 40,
                            child: CommonImage(
                              character.images?.grid ?? '',
                              alignment: Alignment.topCenter,
                            ),
                          ),
                        ),
                        title: Text(character.name ?? ''),
                        subtitle: Row(
                          children: [
                            if (!character.relation.isNullOrBlank)
                              Text('${character.relation} · '),
                            Expanded(
                              child: Text(
                                character.actors?.isNotEmpty == true
                                    ? character.actors!
                                        .map((e) => e.name ?? '')
                                        .where((name) => name.isNotEmpty)
                                        .join(' / ')
                                    : '',
                                overflow: TextOverflow.ellipsis,
                              ),
                            )
                          ],
                        ),
                      )
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

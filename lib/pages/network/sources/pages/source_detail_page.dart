import 'package:expand_widget/expand_widget.dart';
import 'package:flutter/material.dart';

import 'package:flutter_test_future/models/climb_website.dart';
import 'package:flutter_test_future/components/website_logo.dart';
import 'package:flutter_test_future/pages/network/climb/anime_climb_one_website.dart';
import 'package:flutter_test_future/pages/network/sources/pages/import/import_collection_page.dart';
import 'package:flutter_test_future/utils/launch_uri_util.dart';
import 'package:flutter_test_future/utils/sp_util.dart';
import 'package:flutter_test_future/utils/theme_util.dart';
import 'package:oktoast/oktoast.dart';

import 'anime_list_in_source.dart';

/// 单个搜索源详细页面
class SourceDetail extends StatefulWidget {
  final ClimbWebsite climbWebstie;

  const SourceDetail(this.climbWebstie, {Key? key}) : super(key: key);

  @override
  State<SourceDetail> createState() => _SourceDetailState();
}

class _SourceDetailState extends State<SourceDetail> {
  late ClimbWebsite climbWebstie = widget.climbWebstie;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          climbWebstie.name,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 10),
            WebSiteLogo(url: climbWebstie.iconUrl, size: 100, addShadow: false),
            Container(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 10),
              child: ExpandText(climbWebstie.desc,
                  maxLines: 2, textAlign: TextAlign.center),
            ),
            ListTile(
              enabled: !climbWebstie.discard,
              title: const Text("启动搜索"),
              leading: !climbWebstie.discard && climbWebstie.enable
                  ? Icon(Icons.check_box, color: ThemeUtil.getPrimaryColor())
                  : Icon(
                      Icons.check_box_outline_blank,
                      color: ThemeUtil.getPrimaryIconColor(),
                    ),
              onTap: () {
                if (climbWebstie.discard) {
                  showToast("很抱歉，该搜索源已经无法使用");
                  return;
                }
                climbWebstie.enable = !climbWebstie.enable;
                setState(() {});
                // 保存
                SPUtil.setBool(climbWebstie.spkey, climbWebstie.enable);
              },
            ),
            ListTile(
              title: const Text("访问网站"),
              leading: Icon(
                Icons.open_in_new_rounded,
                color: ThemeUtil.getPrimaryIconColor(),
              ),
              onTap: () {
                LaunchUrlUtil.launch(
                    context: context, uriStr: climbWebstie.climb.baseUrl);
              },
            ),
            ListTile(
              enabled: !climbWebstie.discard,
              title: const Text("搜索动漫"),
              leading: Icon(
                Icons.search_rounded,
                color: ThemeUtil.getPrimaryIconColor(),
              ),
              onTap: () {
                Navigator.of(context)
                    .push(MaterialPageRoute(builder: (context) {
                  return AnimeClimbOneWebsite(climbWebStie: climbWebstie);
                }));
              },
            ),
            ListTile(
              title: const Text("收藏列表"),
              leading: Icon(
                Icons.favorite_border,
                color: ThemeUtil.getPrimaryIconColor(),
              ),
              onTap: () {
                Navigator.of(context)
                    .push(MaterialPageRoute(builder: (context) {
                  return AnimeListInSource(sourceKeyword: climbWebstie.keyword);
                }));
              },
            ),
            _buildImportDataTile(context)
          ],
        ),
      ),
    );
  }

  _buildImportDataTile(BuildContext context) {
    return ListTile(
      enabled: climbWebstie.supportImport,
      title: const Text("导入数据"),
      leading: Icon(
        // Icons.post_add,
        // Icons.add_chart_outlined,
        Icons.bar_chart_rounded,
        color: ThemeUtil.getPrimaryIconColor(),
      ),
      onTap: () {
        Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => ImportCollectionPage(
                      climbWebsite: climbWebstie,
                    )));
      },
    );
  }
}
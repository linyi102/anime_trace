import 'package:flutter/material.dart';
import 'package:flutter_test_future/classes/climb_website.dart';
import 'package:flutter_test_future/fade_route.dart';
import 'package:flutter_test_future/scaffolds/anime_climb_one_website.dart';
import 'package:flutter_test_future/utils/sp_util.dart';
import 'package:flutter_test_future/utils/theme_util.dart';
import 'package:url_launcher/url_launcher.dart';

class SourceDetail extends StatefulWidget {
  final ClimbWebstie climbWebstie;
  const SourceDetail(this.climbWebstie, {Key? key}) : super(key: key);

  @override
  State<SourceDetail> createState() => _SourceDetailState();
}

class _SourceDetailState extends State<SourceDetail> {
  late ClimbWebstie climbWebstie = widget.climbWebstie;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          climbWebstie.name,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      body: Column(
        children: [
          const SizedBox(height: 10),
          Container(
            height: 100,
            width: 100,
            alignment: Alignment.topCenter,
            padding: const EdgeInsets.fromLTRB(0, 20, 0, 0),
            decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(150),
                image: DecorationImage(
                    fit: BoxFit.cover,
                    image: AssetImage(climbWebstie.iconAssetUrl)),
                boxShadow: const [
                  BoxShadow(
                      color: Colors.black12,
                      offset: Offset(0.0, 15.0), //阴影xy轴偏移量
                      blurRadius: 15.0, //阴影模糊程度
                      spreadRadius: 1.0 //阴影扩散程度
                      )
                ]),
          ),
          const SizedBox(height: 10),
          ListTile(
            title: const Text("启动搜索"),
            leading: climbWebstie.enable
                ? Icon(Icons.check_box, color: ThemeUtil.getThemePrimaryColor())
                : Icon(
                    Icons.check_box_outline_blank,
                    color: ThemeUtil.getLeadingIconColor(),
                  ),
            onTap: () {
              climbWebstie.enable = !climbWebstie.enable;
              setState(() {});
              // 保存
              SPUtil.setBool(climbWebstie.spkey, climbWebstie.enable);
            },
          ),
          ListTile(
            title: const Text("访问网站"),
            leading: Icon(
              Icons.open_in_browser_rounded,
              color: ThemeUtil.getLeadingIconColor(),
            ),
            onTap: () {
              launchUrl(Uri.parse(climbWebstie.climb.baseUrl),
                      mode: LaunchMode.externalApplication) // 浏览器打开
                  .catchError((e) {
                debugPrint(e);
              });
            },
          ),
          ListTile(
            title: const Text("搜索动漫"),
            leading: Icon(
              Icons.search_rounded,
              color: ThemeUtil.getLeadingIconColor(),
            ),
            onTap: () {
              Navigator.of(context).push(FadeRoute(builder: (context) {
                return AnimeClimbOneWebsite(climbWebStie: climbWebstie);
              }));
            },
          ),
        ],
      ),
    );
  }
}

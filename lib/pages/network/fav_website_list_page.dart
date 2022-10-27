import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test_future/classes/fav_website.dart';
import 'package:flutter_test_future/utils/launch_uri_util.dart';
import 'package:flutter_test_future/utils/sp_util.dart';
import 'package:transparent_image/transparent_image.dart';

class FavWebsiteListPage extends StatelessWidget {
  FavWebsiteListPage({Key? key}) : super(key: key);
  final List<FavWebsite> defaultList = [
    FavWebsite(
        url: "https://bgmlist.com/",
        icoUrl: "https://bgmlist.com/public/favicons/apple-touch-icon.png",
        name: "番组放送"),
  ];

  @override
  Widget build(BuildContext context) {
    bool openWebInApp = SPUtil.getBool("openWebInApp", defaultValue: true);

    return Column(
      children: [
        ListTile(
          title: const Text("网站导航"),
          style: ListTileStyle.drawer,
          trailing: IconButton(
              onPressed: () {
                showDialog(
                    context: context,
                    builder: (dialogContext) {
                      // 返回有状态的builder，从而实现对话框内实时更新
                      return StatefulBuilder(builder: (context, setState) {
                        return AlertDialog(
                          content: SingleChildScrollView(
                            child: Column(
                              children: [
                                ListTile(
                                    title: const Text("应用内打开网页"),
                                    subtitle: const Text("仅对Android端有效"),
                                    trailing: openWebInApp
                                        ? const Icon(Icons.toggle_on,
                                            color: Colors.blue)
                                        : const Icon(Icons.toggle_off),
                                    onTap: () {
                                      setState(() {
                                        openWebInApp = !openWebInApp;
                                      });
                                      SPUtil.setBool(
                                          "openWebInApp", openWebInApp);
                                    })
                              ],
                            ),
                          ),
                        );
                      });
                    });
              },
              icon: const Icon(Icons.settings)),
        ),
        ListView.builder(
            // 解决报错问题
            shrinkWrap: true,
            // 解决不滚动问题
            physics: const NeverScrollableScrollPhysics(),
            itemCount: defaultList.length,
            itemBuilder: (context, index) {
              FavWebsite favWebsite = defaultList[index];
              return ListTile(
                title: Text(favWebsite.name),
                onTap: () {
                  LaunchUrlUtil.launch(favWebsite.url, inApp: openWebInApp);
                },
                leading: ClipOval(
                  child: CachedNetworkImage(
                    imageUrl: favWebsite.icoUrl,
                    fit: BoxFit.cover,
                    // 占位符为透明图。否则显示先前缓存的图片时，不是圆形，加载完毕后又会显示圆形导致显得很突兀
                    placeholder: (context, str) =>
                        Image.memory(kTransparentImage),
                    width: 35,
                  ),
                ),
              );
            }),
      ],
    );
    // return GridView.builder(
    //     shrinkWrap: true,
    //     // 解决报错问题
    //     physics: NeverScrollableScrollPhysics(),
    //     //解决不滚动问题
    //     gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
    //       crossAxisCount: 20, // 横轴数量
    //       crossAxisSpacing: 5, // 横轴距离
    //       mainAxisSpacing: 5, // 竖轴距离
    //       childAspectRatio: 1, // 网格比例
    //     ),
    //     itemCount: defaultList.length,
    //     itemBuilder: (BuildContext context, int index) {
    //       FavWebsite favWebsite = defaultList[index];
    //       return Column(
    //         children: [
    //           ClipRRect(
    //             borderRadius: BorderRadius.circular(50),
    //             child: CachedNetworkImage(
    //               imageUrl: favWebsite.icoUrl,
    //             ),
    //           ),
    //           Text(favWebsite.name),
    //         ],
    //       );
    //     });

    // return Column(
    //   children: [
    //     const ListTile(
    //       title: Text("常用网站"),
    //     ),
    //     SizedBox(
    //       height: 50,
    //       child: ListView(
    //         scrollDirection: Axis.horizontal,
    //         children: [
    //           for (var favWebsite in defaultList)
    //             ClipRRect(
    //               borderRadius: BorderRadius.circular(50),
    //               child: CachedNetworkImage(
    //                 imageUrl: favWebsite.icoUrl,
    //               ),
    //             ),
    //         ],
    //       ),
    //     ),
    //   ],
    // );
  }
}

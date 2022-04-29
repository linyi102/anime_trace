import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test_future/classes/anime.dart';

class AnimeGridCover extends StatelessWidget {
  final Anime _anime;
  const AnimeGridCover(this._anime, {Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
        padding: const EdgeInsets.all(3.0),
        child: AspectRatio(
          // 固定大小
          aspectRatio: 198 / 275,
          // aspectRatio: 31 / 45,
          // aspectRatio: 41 / 63,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: _anime.animeCoverUrl.isEmpty
                // ? Image.asset("assets/images/defaultAnimeCover.jpg")
                ? Container(
                    color: Colors.white,
                    child: Center(
                      child: Text(
                        _anime.animeName.substring(
                            0,
                            _anime.animeName.length >
                                    3 // 最低长度为3，此时下标最大为2，才可以设置end为3，[0, 3)
                                ? 3
                                : _anime
                                    .animeName.length), // 第二个参数如果只设置为3可能会导致越界
                        style: const TextStyle(fontSize: 20),
                      ),
                    ),
                  )
                : Container(
                    // padding: const EdgeInsets.fromLTRB(3, 3, 5, 5),
                    // decoration: BoxDecoration(
                    //   boxShadow: [
                    //     BoxShadow(
                    //       color: Colors.grey, // 阴影的颜色
                    //       offset: const Offset(20, 20), // 阴影与容器的距离
                    //       blurRadius:
                    //           45.0, // 高斯的标准偏差与盒子的形状卷积。spreadRadius: 0.0,
                    //     ),
                    //   ],
                    // ),
                    child: CachedNetworkImage(
                      imageUrl: _anime.animeCoverUrl,
                      fit: BoxFit.fitHeight,
                    ),
                  ),
            // : Card(
            //     elevation: 6, // z轴高度，即阴影大小
            //     shadowColor: Colors.grey,
            //     child: CachedNetworkImage(
            //       imageUrl: _anime.animeCoverUrl,
            //       fit: BoxFit.fitHeight,
            //     ),
            //   )
            // : Image.network(_anime.animeCoverUrl),
          ),
        ));
  }
}

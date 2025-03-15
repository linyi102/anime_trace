import 'package:animetrace/pages/network/climb/anime_climb_one_website.dart';
import 'package:animetrace/utils/global_data.dart';
import 'package:flutter/material.dart';

class BindBgmSubjectView extends StatefulWidget {
  const BindBgmSubjectView(this.animeName, {super.key});
  final String animeName;

  @override
  State<BindBgmSubjectView> createState() => _BindBgmSubjectViewState();
}

class _BindBgmSubjectViewState extends State<BindBgmSubjectView> {
  @override
  Widget build(BuildContext context) {
    return AnimeClimbOneWebsite(
      climbWebStie: bangumiClimbWebsite,
      keyword: widget.animeName,
      enableSourceSelector: false,
      onTap: (anime) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('关联动漫'),
            content: const Text('是否关联该动漫？'),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('取消')),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.pop(context, anime);
                },
                child: const Text('确定'),
              ),
            ],
          ),
        );
      },
    );
  }
}

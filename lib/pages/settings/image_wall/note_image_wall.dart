import 'package:flutter/material.dart';
import 'package:animetrace/components/loading_widget.dart';
import 'package:animetrace/dao/image_dao.dart';
import 'package:animetrace/pages/settings/image_wall/view.dart';

class NoteImageWallPage extends StatefulWidget {
  const NoteImageWallPage({super.key, this.animeId});
  final int? animeId;

  @override
  State<NoteImageWallPage> createState() => _NoteImageWallPageState();
}

class _NoteImageWallPageState extends State<NoteImageWallPage> {
  bool loadok = false;
  List<String> noteImagePaths = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  Widget build(BuildContext context) {
    return loadok
        ? ImageWallPage(imageUrls: noteImagePaths)
        : Scaffold(
            appBar: AppBar(),
            body: const LoadingWidget(center: true),
          );
  }

  void _loadData() async {
    if (widget.animeId != null) {
      noteImagePaths = await ImageDao.getImages(widget.animeId!);
    } else {
      noteImagePaths = await ImageDao.getAllImages();
    }

    setState(() {
      loadok = true;
    });
  }
}

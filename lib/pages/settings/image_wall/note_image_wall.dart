import 'package:flutter/material.dart';
import 'package:flutter_test_future/components/loading_widget.dart';
import 'package:flutter_test_future/dao/image_dao.dart';
import 'package:flutter_test_future/pages/settings/image_wall/view.dart';

class NoteImageWallPage extends StatefulWidget {
  const NoteImageWallPage({super.key});

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
    noteImagePaths = await ImageDao.getAllImages();
    setState(() {
      loadok = true;
    });
  }
}

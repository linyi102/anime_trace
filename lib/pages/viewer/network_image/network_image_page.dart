import 'package:flutter/material.dart';
import 'package:photo_view/photo_view.dart';

class NetworkImageViewPage extends StatefulWidget {
  const NetworkImageViewPage(this.url, {super.key});
  final String url;

  @override
  State<NetworkImageViewPage> createState() => _NetworkImageViewPageState();
}

class _NetworkImageViewPageState extends State<NetworkImageViewPage> {
  late final imageProvider = Image.network(widget.url).image;

  @override
  Widget build(BuildContext context) {
    return PhotoView(
      imageProvider: imageProvider,
      onTapDown: (_, __, ___) => Navigator.pop(context),
      errorBuilder: (context, error, stackTrace) {
        return GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              color: Colors.black,
              child: const Center(
                  child: Text('图片加载失败', style: TextStyle(color: Colors.white))),
            ));
      },
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_test_future/components/loading_widget.dart';
import 'package:flutter_test_future/utils/platform.dart';
import 'package:flutter_test_future/widgets/stack_appbar.dart';
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
    return GestureDetector(
      onTap: () => Navigator.pop(context),
      child: Stack(
        children: [
          PhotoView(
            imageProvider: imageProvider,
            onTapDown: (_, __, ___) => Navigator.pop(context),
            loadingBuilder: (context, event) => Container(
              color: Colors.black,
              child: const Center(child: LoadingWidget()),
            ),
            errorBuilder: (context, error, stackTrace) {
              return Container(
                color: Colors.black,
                child: const Center(
                    child:
                        Text('图片加载失败', style: TextStyle(color: Colors.white))),
              );
            },
          ),
          if (PlatformUtil.isDesktop) const StackAppBar(hideShadow: true),
        ],
      ),
    );
  }
}

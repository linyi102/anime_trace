import 'package:flutter/material.dart';
import 'package:animetrace/components/loading_widget.dart';
import 'package:animetrace/utils/platform.dart';
import 'package:animetrace/widgets/stack_appbar.dart';
import 'package:photo_view/photo_view.dart';

class NetworkImageViewPage extends StatelessWidget {
  const NetworkImageViewPage(this.url, {super.key});
  final String url;

  @override
  Widget build(BuildContext context) {
    Color bg = const Color.fromARGB(255, 14, 14, 14);

    return GestureDetector(
      onTap: () => Navigator.pop(context),
      child: Stack(
        children: [
          PhotoView(
            imageProvider: Image.network(url).image,
            backgroundDecoration: BoxDecoration(color: bg),
            loadingBuilder: (context, event) => Container(
              color: bg,
              child: const Center(child: LoadingWidget()),
            ),
            errorBuilder: (context, error, stackTrace) {
              return Container(
                color: bg,
                child: const Center(
                    child:
                        Text('图片加载失败', style: TextStyle(color: Colors.white))),
              );
            },
          ),
          if (PlatformUtil.isDesktop)
            StackAppBar(hideShadow: true, leading: _buildCloseButton(context)),
        ],
      ),
    );
  }

  InkWell _buildCloseButton(BuildContext context) {
    return InkWell(
      onTap: () => Navigator.pop(context),
      child: Container(
        margin: const EdgeInsets.all(8),
        height: 30,
        width: 30,
        decoration: const BoxDecoration(
          color: Colors.black,
          shape: BoxShape.circle,
        ),
        child: const Icon(Icons.close, color: Colors.white, size: 20),
      ),
    );
  }
}

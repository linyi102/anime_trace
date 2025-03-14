import 'package:flutter/material.dart';

class LoadingPage extends StatelessWidget {
  const LoadingPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: CircularProgressIndicator(
        strokeCap: StrokeCap.round,
      ),
    );
  }
}

class EmptyPage extends BaseEmptyPage {
  const EmptyPage({
    super.key,
    super.icon = Icons.outlet_outlined,
    super.msg = '什么都没有~',
    super.onClickRefresh,
  });
}

class FailPage extends BaseEmptyPage {
  const FailPage({
    super.key,
    super.icon = Icons.error_outline,
    super.msg = '加载失败',
    super.onClickRefresh,
  });
}

class BaseEmptyPage extends StatelessWidget {
  const BaseEmptyPage({
    this.icon = Icons.error_outline,
    this.imgAssetPath,
    required this.msg,
    this.onClickRefresh,
    this.refreshText = '刷新',
    Key? key,
  }) : super(key: key);
  final IconData icon;
  final String? imgAssetPath;
  final String? msg;
  final Function()? onClickRefresh;
  final String refreshText;

  @override
  Widget build(BuildContext context) {
    Color color = Colors.grey;

    return SizedBox(
      width: MediaQuery.of(context).size.width,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            child: imgAssetPath == null
                ? Icon(icon, size: 60, color: color)
                : Image.asset(imgAssetPath!, height: 60),
          ),
          if (msg?.isNotEmpty == true)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              child: Text(msg!, style: TextStyle(color: color)),
            ),
          if (onClickRefresh != null)
            FilledButton(
              onPressed: onClickRefresh,
              child: Text(refreshText),
            ),
        ],
      ),
    );
  }
}

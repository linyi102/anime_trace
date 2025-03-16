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
    super.icon = Icons.inbox,
    String? msg,
    super.onTap,
    super.buttonText = '刷新',
  }) : super(msg: msg ?? '什么都没有~');
}

class FailPage extends BaseEmptyPage {
  const FailPage({
    super.key,
    super.icon = Icons.error_outline,
    String? msg,
    super.onTap,
    super.buttonText = '刷新',
  }) : super(msg: msg ?? '加载失败');
}

class BaseEmptyPage extends StatelessWidget {
  const BaseEmptyPage({
    this.icon = Icons.error_outline,
    this.imgAssetPath,
    required this.msg,
    required this.onTap,
    required this.buttonText,
    Key? key,
  }) : super(key: key);
  final IconData icon;
  final String? imgAssetPath;
  final String? msg;
  final Function()? onTap;
  final String buttonText;

  @override
  Widget build(BuildContext context) {
    Color color = Colors.grey;

    return SizedBox(
      width: MediaQuery.of(context).size.width,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Padding(
            padding: const EdgeInsets.all(4),
            child: imgAssetPath == null
                ? Icon(icon, size: 60, color: color)
                : Image.asset(imgAssetPath!, height: 60),
          ),
          if (msg?.isNotEmpty == true)
            Padding(
              padding: const EdgeInsets.all(8),
              child: Text(msg!, style: TextStyle(color: color)),
            ),
          if (onTap != null)
            FilledButton(
              onPressed: onTap,
              child: Text(buttonText),
            ),
        ],
      ),
    );
  }
}

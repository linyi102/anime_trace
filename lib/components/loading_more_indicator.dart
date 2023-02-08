import 'package:flutter/material.dart';

class LoadingMoreIndicator extends StatelessWidget {
  const LoadingMoreIndicator({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 20, bottom: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            height: 10,
            width: 10,
            child: const CircularProgressIndicator(strokeWidth: 2),
            margin: const EdgeInsets.only(right: 10),
          ),
          const Text("加载更多中..."),
        ],
      ),
    );
  }
}

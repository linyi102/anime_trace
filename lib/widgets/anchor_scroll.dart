import 'package:flutter/widgets.dart';

class AnchorScrollController<AnchorValue> extends ScrollController {
  final Map<AnchorValue, GlobalKey> _anchorKeys = {};

  /// 有序获得所有anchorValue
  Iterable<AnchorValue> get anchorValues {
    final values = _anchorKeys.keys.toList();
    final dys = <AnchorValue, double>{};
    for (int i = 0; i < values.length; i++) {
      final value = values[i];
      final box =
          _anchorKeys[value]?.currentContext?.findRenderObject() as RenderBox?;
      dys[value] = box?.localToGlobal(Offset.zero).dy ?? 0;
    }
    values.sort((l, r) => dys[l]!.compareTo(dys[r]!));

    return values;
  }

  GlobalKey registerAnchor(AnchorValue value) {
    return _anchorKeys.putIfAbsent(value, () => GlobalKey());
  }

  /// 一般在重新获取数据后执行清理，便于重新生成目录
  void deregisterAll() {
    _anchorKeys.clear();
  }

  @override
  void dispose() {
    deregisterAll();
    super.dispose();
  }

  void jumpToAnchor(AnchorValue anchorValue) {
    final render = _anchorKeys[anchorValue]?.currentContext?.findRenderObject();
    if (render != null) position.ensureVisible(render);
  }
}

class AnchorCustomScrollView<AnchorValue> extends CustomScrollView {
  const AnchorCustomScrollView({
    super.key,
    required AnchorScrollController controller,
    super.slivers,
  }) : super(controller: controller);
}

class AnchorWidget<AnchorValue> extends StatelessWidget {
  const AnchorWidget({
    super.key,
    required this.controller,
    required this.anchorValue,
    required this.child,
  });

  final AnchorScrollController controller;
  final AnchorValue anchorValue;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final key = controller.registerAnchor(anchorValue);

    return KeyedSubtree(key: key, child: child);
  }
}

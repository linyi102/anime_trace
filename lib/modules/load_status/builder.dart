import 'package:flutter/widgets.dart';

import 'controller.dart';
import 'page.dart';
import 'status.dart';

class LoadStatusBuilder extends StatelessWidget {
  const LoadStatusBuilder({
    super.key,
    required this.controller,
    required this.builder,
  });
  final LoadStatusController controller;
  final WidgetBuilder builder;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, child) => _buildChild(context),
    );
  }

  Widget _buildChild(BuildContext context) {
    final refresh = controller.refresh;
    switch (controller.status) {
      case LoadStatus.success:
        return builder(context);
      case LoadStatus.fail:
        return FailPage(onTap: refresh, msg: controller.msg);
      case LoadStatus.loading:
        return const LoadingPage();
      case LoadStatus.empty:
        return EmptyPage(onTap: refresh, msg: controller.msg);
      default:
        return const SizedBox();
    }
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_test_future/components/percent_bar.dart';

class ProgressController extends ChangeNotifier {
  int _count = 0;
  int _total = 0;

  ProgressController({int count = 0, required int total}) {
    _count = count;
    _total = total;
  }

  set count(int count) {
    _count = count;
    notifyListeners();
  }

  set total(int total) {
    _total = total;
    notifyListeners();
  }

  int get count => _count;
  int get total => _total;
  double get percent => total == 0 ? 0 : (count / total).clamp(0, 1);
}

class ProgressBuilder extends StatelessWidget {
  const ProgressBuilder({
    super.key,
    required this.controller,
    required this.builder,
  });
  final ProgressController controller;
  final Widget Function(
      BuildContext context, int count, int total, double percent) builder;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, child) => builder(
        context,
        controller.count,
        controller.total,
        controller.percent,
      ),
    );
  }
}

class ProgressDialog extends StatelessWidget {
  const ProgressDialog({
    super.key,
    required this.controller,
    required this.title,
  });
  final ProgressController controller;
  final String title;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      content: ProgressBuilder(
        controller: controller,
        builder: (context, count, total, percent) => Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: PercentBar(percent: percent),
            ),
            Text(
              '$count / $total',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}

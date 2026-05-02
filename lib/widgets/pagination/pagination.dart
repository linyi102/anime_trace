import 'package:animetrace/utils/log.dart';
import 'package:animetrace/utils/toast_util.dart';
import 'package:easy_refresh/easy_refresh.dart';
import 'package:flutter/widgets.dart';

class PaginationController<T> extends ChangeNotifier {
  int _pageNo = 1;
  final int _pageSize;
  final List<T> _data = [];
  bool _isLoading = false;
  bool _isEnd = false;

  Future<Iterable<T>?> Function(int pageNo, int pageSize) fetch;
  void Function()? onReload;

  PaginationController({
    int pageSize = 20,
    required this.fetch,
    this.onReload,
  }) : _pageSize = pageSize;

  bool get isLoading => _isLoading;
  bool get isEmpty => _data.isEmpty;

  Future<void> reload({bool showLoading = false}) async {
    onReload?.call();
    if (showLoading) _data.clear();
    _pageNo = 1;
    _isEnd = false;
    await _fetch();
  }

  Future<void> loadNext() async {
    await _fetch();
  }

  Future<void> _fetch() async {
    if (_pageNo > 1 && _isEnd) {
      ToastUtil.showText('已经到底了');
      return;
    }

    _isLoading = true;
    notifyListeners();

    try {
      final pageList = await fetch(_pageNo, _pageSize);
      if (pageList == null) {
        // ignore
      } else {
        if (_pageNo == 1) _data.clear();
        _data.addAll(pageList);

        if (_pageNo > 1 && pageList.isEmpty) {
          _isEnd = true;
          ToastUtil.showText('已经到底了');
        }
        _pageNo++;
      }
    } catch (err) {
      AppLog.error('fetch pageNo $_pageNo error: $err');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}

class PaginationBuilder<T> extends StatelessWidget {
  const PaginationBuilder({
    super.key,
    required this.controller,
    required this.idleWidget,
    required this.loadingWidget,
    required this.listWidgetBuilder,
  });
  final PaginationController<T> controller;
  final Widget idleWidget;
  final Widget loadingWidget;
  final Widget Function(BuildContext context, List<T> data) listWidgetBuilder;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, child) {
        return EasyRefresh(
          onRefresh: controller.reload,
          onLoad: controller._data.isEmpty ? null : controller.loadNext,
          child: Builder(
            builder: (context) {
              if (controller._pageNo == 1 &&
                  controller._isLoading &&
                  controller._data.isEmpty) {
                return loadingWidget;
              }

              if (controller._data.isEmpty) {
                return idleWidget;
              }

              return listWidgetBuilder(context, controller._data);
            },
          ),
        );
      },
    );
  }
}

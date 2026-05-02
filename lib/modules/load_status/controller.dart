import 'package:animetrace/utils/log.dart';
import 'package:flutter/widgets.dart';

import 'status.dart';

class LoadStatusController extends ChangeNotifier {
  Future<void> Function() refresh;
  LoadStatus _status = LoadStatus.none;
  String? _msg;

  LoadStatusController({required this.refresh});

  LoadStatus get status => _status;
  String? get msg => _msg;
  bool get isSuccess => _status == LoadStatus.success;

  void setStatus(LoadStatus status, {String? msg}) {
    _status = status;
    _msg = msg;
    notifyListeners();
  }

  void setLoading() {
    setStatus(LoadStatus.loading);
  }

  void setFail([String? msg]) {
    setStatus(LoadStatus.fail, msg: msg);
  }

  void setEmpty() {
    setStatus(LoadStatus.empty);
  }

  void setSuccess() {
    setStatus(LoadStatus.success);
  }

  void trySetSuccess(void Function() action, {String? failMsg}) {
    try {
      action();
      setStatus(LoadStatus.success);
    } catch (e, st) {
      AppLog.error('trySetSuccess error: $e', stackTrace: st);
      setStatus(LoadStatus.fail, msg: failMsg);
    }
  }
}

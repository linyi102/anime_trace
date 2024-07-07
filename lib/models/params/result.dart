import 'package:flutter_test_future/utils/log.dart';

class Result<T> {
  int code;
  T data;
  String msg;

  Result(this.code, this.data, {this.msg = ""});

  static Result success<T>(T data, {String msg = ""}) {
    return Result<T>(200, data, msg: msg);
  }

  static Result failure(int code, String msg) {
    return Result(code, "", msg: msg);
  }

  bool get isSuccess => code == 200;

  bool get isFailure => !isSuccess;

  @override
  String toString() {
    return "code=$code, data=$data, msg=$msg";
  }
}

extension ResultConverter on Result {
  bool _isMap(dynamic value) => value is Map<String, dynamic>;
  bool _isNotMap(dynamic value) => !_isMap(value);

  T toModel<T>({
    required T Function(Map<String, dynamic> json) transform,
    required T Function() dataOnError,
  }) {
    if (isFailure || _isNotMap(data) || _isNotMap(data['data'])) {
      return dataOnError();
    }

    try {
      return transform(data['data']);
    } catch (e) {
      return dataOnError();
    }
  }

  List<T> toModelList<T>({
    required T Function(Map<String, dynamic> json) transform,
    List<T> Function()? dataOnError,
  }) {
    if (isFailure || _isNotMap(data) || data['data'] is! List) {
      return dataOnError?.call() ?? [];
    }

    List<T> list = [];
    for (final item in data['data']) {
      if (_isNotMap(item)) continue;
      try {
        list.add(transform(item));
      } catch (e) {
        Log.error(e);
      }
    }
    return list;
  }

  T? toValue<T>({
    T? Function()? dataOnError,
  }) {
    if (isFailure || _isNotMap(data) || data['data'] is! T) {
      return dataOnError?.call();
    }
    return data['data'];
  }

  List<T> toValueList<T>({
    List<T> Function()? dataOnError,
  }) {
    if (isFailure || _isNotMap(data) || data['data'] is! List<T>) {
      return dataOnError?.call() ?? [];
    }
    return data['data'];
  }
}

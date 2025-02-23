import 'package:dio/dio.dart';
import 'package:animetrace/utils/log.dart';

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

bool _isMap(dynamic value) => value is Map<String, dynamic>;
bool _isNotMap(dynamic value) => !_isMap(value);

enum ResultDataType {
  body,
  bodyData,
  responseBody,
  responseBodyData,
  ;
}

extension ResultDataTypeExtension on ResultDataType {
  R? extract<R>(Result result) {
    switch (this) {
      case ResultDataType.body:
        return _extractBody(result);
      case ResultDataType.bodyData:
        return _extractBodyData(result);
      case ResultDataType.responseBody:
        return _extractResponseBody(result);
      case ResultDataType.responseBodyData:
        return _extractResponseBodyData(result);
    }
  }

  R? _extractBodyData<R>(Result result) {
    if (result.isFailure || _isNotMap(result.data)) return null;
    final data = result.data['data'];
    if (data is! R) return null;
    return data;
  }

  R? _extractBody<R>(Result result) {
    if (result.isFailure) return null;
    final data = result.data;
    if (data is! R) return null;
    return data;
  }

  R? _extractResponseBody<R>(Result result) {
    if (result.isFailure) return null;
    if (result.data is! Response) return null;
    final data = (result.data as Response).data;
    if (data is! R) return null;
    return data;
  }

  R? _extractResponseBodyData<R>(Result result) {
    if (result.isFailure) return null;
    if (result.data is! Response) return null;
    final respData = (result.data as Response).data;
    return _extractBodyData(Result(result.code, respData));
  }
}

extension ResponseDataTransformer on Result {
  T toModel<T>({
    required T Function(Map<String, dynamic> json) transform,
    required T Function() onError,
    ResultDataType dataType = ResultDataType.body,
  }) {
    final innerData = dataType.extract<Map<String, dynamic>>(this);
    if (innerData == null) return onError();

    try {
      return transform(innerData);
    } catch (e) {
      return onError();
    }
  }

  List<T> toModelList<T>({
    required T Function(Map<String, dynamic> json) transform,
    List<T> Function()? onError,
    ResultDataType dataType = ResultDataType.body,
  }) {
    final data = dataType.extract<List<dynamic>>(this);
    if (data == null) return onError?.call() ?? [];

    List<T> list = [];
    for (final item in data) {
      if (_isNotMap(item)) continue;
      try {
        list.add(transform(item));
      } catch (err, stack) {
        logger.error('transfrom异常：$err', stackTrace: stack);
      }
    }
    return list;
  }

  T? toValue<T>({
    T? Function()? onError,
    ResultDataType dataType = ResultDataType.body,
  }) {
    final data = dataType.extract<T>(this);
    if (data == null) return onError?.call();

    return data;
  }

  List<T> toValueList<T>({
    List<T> Function()? onError,
    ResultDataType dataType = ResultDataType.body,
  }) {
    final data = dataType.extract<List<T>>(this);
    if (data == null) return onError?.call() ?? [];

    return data;
  }
}

import 'package:dio/dio.dart';
import 'package:flutter_test_future/utils/error_format_util.dart';
import 'package:flutter_test_future/utils/result.dart';

class DioPackage {
  BaseOptions baseOptions = BaseOptions(
      method: "get",
      connectTimeout: 8000,
      sendTimeout: 8000,
      receiveTimeout: 8000);

  Future<Result> get<T>(String path) async {
    try {
      Response response = await Dio(baseOptions).request(path);
      return Result.success(response);
    } catch (e) {
      String msg = ErrorFormatUtil.formatError(e);
      return Result.failure(-1, msg);
    }
  }
}

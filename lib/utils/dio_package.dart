import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test_future/utils/error_format_util.dart';
import 'package:flutter_test_future/utils/result.dart';

class DioPackage {
  Future<Result> get<T>(String path) async {
    try {
      Response response = await Dio().get(path);
      return Result.success(response);
    } on DioError catch (e) {
      debugPrint(e.toString());
      ErrorFormatUtil.formatDioError(e);
    } catch (e) {
      debugPrint("捕获到其他错误");
      debugPrint(e.toString());
    }
    return Result.failure(-1, "未知错误");
  }
}

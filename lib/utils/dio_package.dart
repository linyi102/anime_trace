import 'package:dart_ping/dart_ping.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test_future/utils/error_format_util.dart';
import 'package:flutter_test_future/utils/ping_result.dart';
import 'package:flutter_test_future/utils/result.dart';

class DioPackage {
  static final BaseOptions _baseOptions = BaseOptions(
      method: "get",
      connectTimeout: 8000,
      sendTimeout: 8000,
      receiveTimeout: 8000);

  Future<Result> get<T>(String path) async {
    try {
      Response response = await Dio(_baseOptions).request(path);
      return Result.success(response);
    } catch (e) {
      String msg = ErrorFormatUtil.formatError(e);
      return Result.failure(-1, msg);
    }
  }

  static Future<PingStatus> ping(String path) async {
    PingStatus pingStatus = PingStatus();
    // 加上https://会提示错误
    /**
      flutter: PingError(response:null, error:UnknownHost)
      flutter: PingSummary(transmitted:0, received:0), time: 0 ms, Errors: [Unknown: Ping process exited with code: 1]
     */
    List<String> prefixs = ["https://", "http://"];
    for (String prefix in prefixs) {
      if (path.startsWith(prefix)) {
        path = path.replaceFirst(prefix, ""); // 删除前缀
        break;
      }
    }
    final ping = Ping(path, count: 3, timeout: 8);
    await ping.stream.listen((event) {
      // 只需要看Summary，忽略Response
      if (event.toString().contains("PingSummary")) {
        // 3次有1次回复，则返回true
        int reveived = event.summary?.received ?? 0;
        debugPrint("$event, reveived=$reveived");
        if (reveived >= 1) {
          pingStatus.connectable = true;
          pingStatus.time = event.summary?.time?.inMilliseconds ?? -1;
        }
      }
    }).asFuture(); // stream改为futrue，并await
    pingStatus.pinging = false; // ping结束
    pingStatus.notPing = false; // 不再是一次还没ping过
    return pingStatus;

    // try {
    //   int? statusCode = (await Dio(_baseOptions).request(path)).statusCode;
    //   debugPrint("状态码：$statusCode");
    //   pingStatus.ok = true; // 不会抛出异常则说明可以连接
    //   debugPrint("ping ok");
    // } catch (e) {
    //   pingStatus.ok = false;
    //   debugPrint("ping false");
    // }
    // pingStatus.pingFinish = true; // 不管能不能连接，都设置为ping结束了
    // return pingStatus;
  }
}

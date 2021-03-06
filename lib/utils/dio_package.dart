import 'package:dart_ping/dart_ping.dart';
import 'package:dio/adapter.dart';
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

  static Dio _getDio() {
    /**
      I/flutter ( 1540): e.message=HandshakeException: Handshake error in client (OS Error:
      I/flutter ( 1540):      CERTIFICATE_VERIFY_FAILED: certificate has expired(handshake.cc:359))
       */
    // 来源：https://www.cnblogs.com/MingGyGy-Castle/p/13761327.html
    // OmoFun搜索动漫时会报错，因此添加证书验证，不再直接使用Response response = await Dio(_baseOptions).request(path);
    Dio dio = Dio(_baseOptions);
    (dio.httpClientAdapter as DefaultHttpClientAdapter).onHttpClientCreate =
        (client) {
      client.badCertificateCallback = (cert, host, port) {
        return true;
      };
      return null;
    };
    return dio;
  }

  Future<Result> get<T>(String path) async {
    try {
      Dio dio = _getDio();
      Response response = await dio.request(path);

      return Result.success(response);
    } catch (e) {
      String msg = ErrorFormatUtil.formatError(e);
      return Result.failure(-1, msg);
    }
  }

  static const bool _enablePing = false;

  // 查看网络状态
  static Future<PingStatus> ping(String path) async {
    PingStatus pingStatus = PingStatus();
    if (_enablePing) {
      // 使用ping第三方包
      // 缺点：打包后win端始终超时
      /**加上https://会提示错误
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
    } else {
      // 使用dio方法
      bool connectable = false;
      try {
        var start = DateTime.now();
        Dio dio = _getDio();
        int? statusCode = (await dio.request(path)).statusCode;
        var end = DateTime.now();
        pingStatus.time = end.difference(start).inMilliseconds;
        if (statusCode == 200) {
          connectable = true; // 只有不抛出异常且状态码为200时才说明可以连接
        } else {
          debugPrint("状态码：$statusCode");
        }
      } catch (e) {
        String msg = ErrorFormatUtil.formatError(e);
        debugPrint(msg);
      }

      if (connectable) {
        pingStatus.connectable = true;
        debugPrint("ping ok: $path");
      } else {
        pingStatus.connectable = false;
        debugPrint("ping false: $path");
      }
    }

    // 更新状态并返回
    pingStatus.pinging = false; // ping结束
    pingStatus.notPing = false; // 不再是一次还没ping过
    return pingStatus;
  }
}

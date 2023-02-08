import 'package:dart_ping/dart_ping.dart';
import 'package:dio/adapter.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test_future/utils/error_format_util.dart';
import 'package:flutter_test_future/utils/ping_result.dart';
import 'package:flutter_test_future/models/params/result.dart';
import 'package:flutter_test_future/utils/log.dart';

class DioPackage {
  static final BaseOptions _baseOptions = BaseOptions(
      method: "get",
      connectTimeout: 5000,
      sendTimeout: 5000,
      receiveTimeout: 5000);

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

  static Future<Result> get<T>(String path, {bool isMobile = false}) async {
    try {
      Dio dio = _getDio();

      Options? options;
      if (isMobile) {
        options = Options(headers: {
          "User-Agent":
              "Mozilla/5.0 (Linux; Android 6.0; Nexus 5 Build/MRA58N) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/109.0.0.0 Mobile Safari/537.36 Edg/109.0.1518.78",
        });
      }
      Response response = await dio.request(path, options: options);

      return Result.success(response);
    } catch (e) {
      String msg = ErrorFormatUtil.formatError(e);
      return Result.failure(-1, msg);
    }
  }

  static const bool _enablePing = false;

  // 查询链接状态
  static Future<bool> urlResponseOk(String url) async {
    Dio dio = _getDio();
    try {
      int? statusCode = (await dio.head(url))
          .statusCode; // 使用head而非request、get会更有效率，因为它不会下载内容
      if (statusCode == 200) {
        return true;
      } else {
        Log.info("$url返回码：$statusCode");
        return false;
      }
    } catch (e) {
      // debugPrint(e.toString());
      // 400会报异常，这里捕捉到后返回false
      return false;
    }
  }

  // 查看网站状态
  static Future<PingStatus> ping(String path) async {
    PingStatus pingStatus = PingStatus();
    pingStatus.needPing = false; // 先设置为false，这样在ping的过程中来回切换页面后，不会再次ping

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
          Log.info("$event, reveived=$reveived");
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
        bool responseOk = await urlResponseOk(path);
        var end = DateTime.now();
        pingStatus.time = end.difference(start).inMilliseconds;
        if (responseOk) {
          connectable = true; // 只有不抛出异常且状态码为200时才说明可以连接
        }
      } catch (e) {
        String msg = ErrorFormatUtil.formatError(e);
        Log.info(msg);
      }

      if (connectable) {
        pingStatus.connectable = true;
        Log.info("ping ok: $path");
      } else {
        pingStatus.connectable = false;
        Log.info("ping false: $path");
      }
    }

    // 更新状态并返回
    pingStatus.pinging = false; // ping结束
    return pingStatus;
  }
}

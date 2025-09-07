import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:animetrace/utils/error_format_util.dart';
import 'package:animetrace/models/ping_result.dart';
import 'package:animetrace/models/params/result.dart';
import 'package:animetrace/utils/log.dart';
import 'package:animetrace/utils/network/dio_log_interceptor.dart';
import 'package:dio/io.dart';

class DioUtil {
  static final BaseOptions _baseOptions = BaseOptions(
    method: "get",
    connectTimeout: const Duration(milliseconds: 8000),
    sendTimeout: const Duration(milliseconds: 8000),
    // 取消接收超时，避免下载文件过程中超时
    // receiveTimeout: const Duration(milliseconds: 8000),
  );
  static late Dio dio;

  static void init() {
    dio = Dio(_baseOptions);
    dio.interceptors.add(DioLogInterceptor());
    dio.httpClientAdapter = IOHttpClientAdapter(createHttpClient: () {
      final HttpClient client =
          HttpClient(context: SecurityContext(withTrustedRoots: false));
      client.badCertificateCallback = (cert, host, port) => true;
      return client;
    });
  }

  static Future<Result> get<T>(
    String path, {
    bool isMobile = false,
    String? referer,
    Map<String, dynamic>? headers,
    Map<String, dynamic>? query,
  }) async {
    try {
      headers = headers ?? {};
      if (isMobile) {
        headers['User-Agent'] =
            'Mozilla/5.0 (Linux; Android 6.0; Nexus 5 Build/MRA58N) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/109.0.0.0 Mobile Safari/537.36 Edg/109.0.1518.78';
      }
      if (referer != null) {
        headers['referer'] = referer;
      }
      Options? options = Options(headers: headers);
      Response response =
          await dio.request(path, options: options, queryParameters: query);

      return Result.success(response);
    } catch (e) {
      String msg = ErrorFormatUtil.formatError(e);
      return Result.failure(-1, msg);
    }
  }

  static Future<Result> post<T>(String path,
      {Map<String, dynamic> data = const {}}) async {
    try {
      Response response = await dio.post(
        path,
        data: FormData.fromMap(data),
      );

      return Result.success(response);
    } catch (e) {
      String msg = ErrorFormatUtil.formatError(e);
      return Result.failure(-1, msg);
    }
  }

  static Future<Result> graphql(String path, String graphSQL) async {
    try {
      Response response = await dio.post(
        path,
        data: jsonEncode({"query": graphSQL}),
      );

      return Result.success(response);
    } catch (e) {
      String msg = ErrorFormatUtil.formatError(e);
      return Result.failure(-1, msg);
    }
  }

  // 查询链接状态
  static Future<bool> urlResponseOk(String url) async {
    try {
      int? statusCode = (await dio.head(url))
          .statusCode; // 使用head而非request、get会更有效率，因为它不会下载内容
      if (statusCode == 200) {
        return true;
      } else {
        AppLog.info("$url返回码：$statusCode");
        return false;
      }
    } catch (e) {
      // AppLog.error(e.toString());
      // 400会报异常，这里捕捉到后返回false
      return false;
    }
  }

  // 查看网站状态
  static Future<PingStatus> ping(String path) async {
    PingStatus pingStatus = PingStatus();
    pingStatus.needPing = false; // 先设置为false，这样在ping的过程中来回切换页面后，不会再次ping

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
      AppLog.info(msg);
    }

    if (connectable) {
      pingStatus.connectable = true;
      AppLog.info("ping ok: $path");
    } else {
      pingStatus.connectable = false;
      AppLog.info("ping false: $path");
    }

    // 更新状态并返回
    pingStatus.pinging = false; // ping结束
    return pingStatus;
  }

  static Future<Result> download({
    required String urlPath,
    required String savePath,
    void Function(int count, int total)? onReceiveProgress,
    CancelToken? cancelToken,
  }) async {
    Response response;

    try {
      // 若savePath已存在，则会重新写入，不会追加
      // 断网后恢复也可以继续下载
      response = await dio.download(
        urlPath,
        savePath,
        onReceiveProgress: onReceiveProgress,
        cancelToken: cancelToken,
      );
    } on Exception catch (e) {
      return Result(-1, null, msg: ErrorFormatUtil.formatError(e));
    }

    if (response.statusCode == 200) {
      return Result.success(response);
    } else {
      return Result.failure(response.statusCode ?? -1, "下载失败");
    }
  }
}

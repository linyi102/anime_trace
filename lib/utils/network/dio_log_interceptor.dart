import 'package:animetrace/utils/log.dart';
import 'package:dio/dio.dart';

class DioLogInterceptor extends Interceptor {
  DioLogInterceptor();

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    String msg = '[REQ] ${options.method.toUpperCase()} ${options.uri}';
    AppLog.info(msg);

    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) async {
    String msg =
        '[RESP] ${response.requestOptions.method.toUpperCase()} ${response.requestOptions.uri}';
    if (response.statusCode != null || response.statusMessage != null) {
      msg += '\nStatusCode: ${response.statusCode} ${response.statusMessage}';
    }
    AppLog.info(msg);

    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    String msg =
        '[RESP ERR] ${err.requestOptions.method.toUpperCase()} ${err.requestOptions.uri}';
    if (err.response?.statusCode != null) {
      msg += '\nStatusCode: ${err.response?.statusCode}';
    }
    if (err.response?.statusMessage != null) {
      msg += '\nStatusMessage: ${err.response?.statusMessage}';
    }
    AppLog.info(msg);

    handler.next(err);
  }
}

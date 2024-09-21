import 'package:dio/dio.dart';
import 'package:flutter_logkit/logkit.dart';
import 'package:flutter_test_future/utils/log.dart';

class DioLogInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    logger.logTyped(
      HttpRequestLogRecord.generate(
        method: options.method,
        url: options.uri.toString(),
        headers: options.headers,
        body: options.data,
      ),
      settings: const LogSettings(printToConsole: false),
    );
    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) async {
    logger.logTyped(
      HttpResponseLogRecord.generate(
        method: response.requestOptions.method,
        url: response.requestOptions.uri.toString(),
        statusCode: response.statusCode,
        statusMessage: response.statusMessage,
        headers: response.headers,
        body: response.data,
      ),
      settings: const LogSettings(printToConsole: false),
    );
    handler.next(response);
  }

  @override
  void onError(DioError err, ErrorInterceptorHandler handler) async {
    logger.logTyped(
      HttpResponseLogRecord.generate(
        method: err.requestOptions.method,
        url: err.requestOptions.uri.toString(),
        statusCode: err.response?.statusCode,
        statusMessage: err.response?.statusMessage,
        headers: err.response?.headers,
        body: err.response?.data,
      ),
    );
    handler.next(err);
  }
}

import 'package:animetrace/controllers/host_service.dart';
import 'package:dio/dio.dart';

class DioForwardInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    options.path = HostService.to.tryForwardUrl(options.uri.toString());

    return handler.next(options);
  }
}

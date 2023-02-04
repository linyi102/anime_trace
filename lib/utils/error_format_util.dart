import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_test_future/utils/log.dart';

class ErrorFormatUtil {
  /*
   * error统一处理
   */
  static String formatError(e) {
    String msg = "";
    if (e is DioError) {
      if (e.type == DioErrorType.connectTimeout) {
        // It occurs when url is opened timeout.
        Log.info(e.message);
        msg = "连接超时";
      } else if (e.type == DioErrorType.sendTimeout) {
        // It occurs when url is sent timeout.
        msg = "请求超时";
      } else if (e.type == DioErrorType.receiveTimeout) {
        //It occurs when receiving timeout
        msg = "响应超时";
      } else if (e.type == DioErrorType.response) {
        // When the server response, but with a incorrect status, such as 404, 503...
        // msg = "出现异常";
        msg = getMsgByErrorCode(e);
      } else if (e.type == DioErrorType.cancel) {
        // When the request is cancelled, dio will throw a error with this type.
        msg = "请求取消";
      } else {
        //DEFAULT Default error type, Some other Error. In this case, you can read the DioError.error if it is not null.
        dynamic childE = e.error;
        Log.info("e.message=" + e.message);
        if (e.message ==
            "HandshakeException: Connection terminated during handshake") {
          msg = "连接失败";
        } else if (childE is SocketException) {
          msg = "网络无连接,请检查网络设置";
          if (childE.osError.toString().contains("OS Error: 信号灯超时时间已到")) {
            msg = "信号灯超时";
          }
        } else {
          /**
        flutter: e.message=HttpException: Connection closed before full header was received, uri = https://www.yhdmp.cc/list/?region=&year=&season=&status=&label=&order=&genre=
        flutter: 未知错误
         */
          msg = "未知错误";
        }
      }
    } else {
      msg = "未知错误";
      Log.info("捕获到非DioEoor");
    }
    if (msg.length > 300) {
      Log.info(msg.substring(0, 300)); // 限制打印长度
    } else {
      Log.info(msg);
    }
    return msg;
  }

  static String getMsgByErrorCode(error) {
    int errCode = error.response?.statusCode ?? 0;

    switch (errCode) {
      case 400:
        return "请求语法错误";
      case 401:
        return "没有权限";
      case 403:
        return "服务器拒绝执行";
      case 404:
        return "无法连接服务器";
      case 405:
        return "请求方法被禁止";
      case 500:
        return "服务器内部错误";
      case 502:
        return "无效的请求";
      case 503:
        return "服务器不可用";
      case 505:
        return "不支持HTTP协议请求";
      default:
        return "未知错误";
    }
  }
}

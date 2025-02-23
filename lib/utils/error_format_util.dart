import 'dart:io';

import 'package:dio/dio.dart';
import 'package:animetrace/utils/log.dart';

class ErrorFormatUtil {
  static String formatError(e) {
    String msg = "";
    Log.error(e);
    if (e is DioException) {
      if (e.type == DioExceptionType.connectionTimeout) {
        Log.info(e.message);
        msg = "连接超时";
      } else if (e.type == DioExceptionType.sendTimeout) {
        msg = "请求超时";
      } else if (e.type == DioExceptionType.receiveTimeout) {
        msg = "响应超时";
      } else if (e.type == DioExceptionType.badResponse) {
        msg = getMsgByErrorCode(e);
      } else if (e.type == DioExceptionType.cancel) {
        msg = "请求取消";
      } else {
        dynamic childE = e.error;
        if (e.message != null) Log.info("e.message=" + e.message!);
        if (e.message ==
            "HandshakeException: Connection terminated during handshake") {
          msg = "连接失败";
        } else if (childE is SocketException) {
          msg = "网络无连接，请检查网络设置";
          if (childE.osError.toString().contains("OS Error: 信号灯超时时间已到")) {
            msg = "信号灯超时";
          }
        } else {
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

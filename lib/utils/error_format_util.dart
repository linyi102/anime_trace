import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:oktoast/oktoast.dart';

class ErrorFormatUtil {
  /*
   * error统一处理
   */
  static void formatDioError(DioError e) {
    String msg = "";
    if (e.type == DioErrorType.connectTimeout) {
      // It occurs when url is opened timeout.
      msg = "连接超时";
    } else if (e.type == DioErrorType.sendTimeout) {
      // It occurs when url is sent timeout.
      msg = "请求超时";
    } else if (e.type == DioErrorType.receiveTimeout) {
      //It occurs when receiving timeout
      msg = "响应超时";
    } else if (e.type == DioErrorType.response) {
      // When the server response, but with a incorrect status, such as 404, 503...
      msg = "出现异常";
    } else if (e.type == DioErrorType.cancel) {
      // When the request is cancelled, dio will throw a error with this type.
      msg = "请求取消";
    } else {
      //DEFAULT Default error type, Some other Error. In this case, you can read the DioError.error if it is not null.
      dynamic childE = e.error;
      debugPrint("e.message=" + e.message);
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
    if (msg.length > 300) {
      debugPrint(msg.substring(0, 300)); // 限制打印长度
    } else {
      debugPrint(msg);
    }
    showToast(msg);
  }
}

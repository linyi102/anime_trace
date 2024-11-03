import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('URI Encode', () async {
    const text = '乱马1/2';
    expect(Uri.encodeFull(text), '%E4%B9%B1%E9%A9%AC1/2');
    expect(Uri.encodeComponent(text), '%E4%B9%B1%E9%A9%AC1%2F2');
    expect(Uri.encodeQueryComponent(text), '%E4%B9%B1%E9%A9%AC1%2F2');
  });

  test('http', () async {
    var headers = {'Cookie': 'chii_searchDateLine=1729417788'};
    var dio = Dio();
    var response = await dio.get(
      // 'https://api.bgm.tv/search/subject/乱马1%2F2',
      // 'https://bangumi.tv/subject_search/乱马1%2F2',
      'https://bangumi.tv/subject_search/${Uri.encodeComponent('乱马1/2')}',
      options: Options(
        headers: headers,
      ),
    );

    if (response.statusCode == 200) {
      debugPrint(json.encode(response.data));
    } else {
      debugPrint(response.statusMessage);
    }
  });
}

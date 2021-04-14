import 'dart:io';

import 'package:dio/dio.dart';

class HttpClient {
  Dio _dio;
  String _baseUrl = 'https://0270deebeefe.ngrok.io';

  HttpClient() {
    _dio = new Dio();
    _dio.options.baseUrl = _baseUrl;

    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (
        RequestOptions options,
        RequestInterceptorHandler _handler,
      ) {
        Map<String, String> headers = {
          HttpHeaders.contentTypeHeader: 'application/json; charset=UTF-8',
        };
        options.headers.addAll(headers);
        return _handler.next(options);
      },
    ));
  }

  Dio getClient() {
    return _dio;
  }
}

import 'package:animetrace/controllers/host_service.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:http/http.dart' as http;

class CustomImageCacheManager extends CacheManager with ImageCacheManager {
  static const key = 'libCachedImageData';

  static final CustomImageCacheManager _instance = CustomImageCacheManager._();

  factory CustomImageCacheManager() {
    return _instance;
  }

  CustomImageCacheManager._()
      : super(
          Config(key, fileService: _CustomHttpFileService()),
        );
}

class _CustomHttpFileService extends FileService {
  final http.Client _httpClient;

  _CustomHttpFileService({http.Client? httpClient})
      : _httpClient = httpClient ?? http.Client();

  @override
  Future<FileServiceResponse> get(String url,
      {Map<String, String>? headers}) async {
    url = HostService.to.tryForwardUrl(url);

    final req = http.Request('GET', Uri.parse(url));
    if (headers != null) {
      req.headers.addAll(headers);
    }
    final httpResponse =
        await _httpClient.send(req).timeout(const Duration(seconds: 5));

    return HttpGetResponse(httpResponse);
  }
}

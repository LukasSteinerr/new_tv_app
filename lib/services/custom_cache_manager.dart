import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

class CustomCacheManager {
  static const key = 'customCacheKey';

  static CacheManager? _instance;

  static Future<CacheManager> getInstance() async {
    if (_instance == null) {
      final customPath = await getApplicationSupportDirectory();
      _instance = CacheManager(
        Config(
          key,
          stalePeriod: const Duration(days: 15),
          maxNrOfCacheObjects: 200,
          repo: JsonCacheInfoRepository(databaseName: key),
          fileService: HttpFileService(),
        ),
      );
    }
    return _instance!;
  }
}

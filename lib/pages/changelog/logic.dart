import 'package:animetrace/models/app_release.dart';
import 'package:animetrace/utils/dio_util.dart';
import 'package:animetrace/utils/toast_util.dart';
import 'package:get/get.dart';

class ChangelogLogic extends GetxController {
  get url => 'https://api.github.com/repos/linyi102/anime_trace/releases';
  bool loading = false;

  List<AppRelease> releases = [];

  @override
  void onInit() {
    super.onInit();
    loadData();
  }

  loadData() async {
    loading = true;
    releases.clear();
    update();

    final result = await DioUtil.get(url);

    if (result.isSuccess) {
      List releaseJsons = result.data.data;
      releases.addAll(releaseJsons.map((e) => AppRelease.fromJson(e)));
    } else {
      ToastUtil.showText(result.msg);
    }

    loading = false;
    update();
  }
}

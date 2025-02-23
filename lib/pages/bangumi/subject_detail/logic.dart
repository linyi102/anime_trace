import 'package:animetrace/repositories/bangumi_repository.dart';
import 'package:animetrace/models/bangumi/bangumi.dart';
import 'package:get/get.dart';

class BangumiSubjectDetailLogic extends GetxController {
  String subjectId = '400602';
  final repository = BangumiRepository();
  List<BgmCharacter> characters = [];

  @override
  void onInit() {
    super.onInit();
    loadData();
  }

  Future<void> loadData() async {
    characters = await repository.fetchCharacters(subjectId);
    characters.sort((a, b) =>
        _getReleationPriority(b.relation) - _getReleationPriority(a.relation));
    update();
  }

  int _getReleationPriority(String? relation) {
    switch (relation) {
      case '主角':
        return 3;
      case '配角':
        return 2;
      case '客串':
        return 1;
      default:
        return 0;
    }
  }
}

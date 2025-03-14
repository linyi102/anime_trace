import 'package:animetrace/models/bangumi/character_graph.dart';
import 'package:animetrace/modules/load_status/controller.dart';
import 'package:animetrace/repositories/bangumi_repository.dart';
import 'package:animetrace/models/bangumi/bangumi.dart';
import 'package:animetrace/utils/launch_uri_util.dart';
import 'package:flutter/widgets.dart';
import 'package:get/get.dart';

class BangumiSubjectDetailLogic extends GetxController {
  String subjectId = '428735';
  final repository = BangumiRepository();
  List<BgmCharacter> characters = [];
  late final loadStatusController = LoadStatusController(refresh: loadData);

  @override
  void onInit() {
    super.onInit();
    loadData();
  }

  @override
  void onClose() {
    super.onClose();
    loadStatusController.dispose();
  }

  Future<void> loadData() async {
    loadStatusController.setLoading();
    characters = await repository.fetchCharacters(subjectId);
    await _covertToChineseName(characters);
    characters.sort((a, b) =>
        _getReleationPriority(b.relation) - _getReleationPriority(a.relation));
    loadStatusController.setSuccess();
  }

  Future<void> _covertToChineseName(List<BgmCharacter> characters) async {
    final characterGraphs = await repository.fetchCharacterGraphs(characters
        .map((c) => c.id)
        .where((id) => id != null)
        .cast<int>()
        .toList());
    for (final c in characters) {
      final cn =
          characterGraphs.firstWhereOrNull((g) => g.id == c.id)?.chineseName;
      if (cn?.isNotEmpty == true) {
        c.name = cn;
      }
    }
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

  void toDetail(BuildContext context, BgmCharacter character) {
    LaunchUrlUtil.launch(
        context: context, uriStr: 'https://bgm.tv/character/${character.id}');
  }
}

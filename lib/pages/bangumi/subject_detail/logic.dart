import 'package:animetrace/dao/anime_dao.dart';
import 'package:animetrace/models/anime.dart';
import 'package:animetrace/models/bangumi/character_graph.dart';
import 'package:animetrace/modules/load_status/controller.dart';
import 'package:animetrace/repositories/bangumi_repository.dart';
import 'package:animetrace/models/bangumi/bangumi.dart';
import 'package:animetrace/utils/climb/climb_anime_util.dart';
import 'package:animetrace/utils/climb/climb_bangumi.dart';
import 'package:get/get.dart';

class BangumiSubjectDetailLogic extends GetxController {
  String subjectId = '';
  final Anime anime;
  BangumiSubjectDetailLogic(this.anime);

  final repository = BangumiRepository();
  List<BgmCharacter> characters = [];
  late final loadStatusController = LoadStatusController(refresh: _loadData);

  @override
  void onInit() async {
    super.onInit();
    _loadData();
  }

  @override
  void onClose() {
    super.onClose();
    loadStatusController.dispose();
  }

  Future<void> _loadData() async {
    loadStatusController.setLoading();

    final website = ClimbAnimeUtil.getClimbWebsiteByAnimeUrl(anime.animeUrl);
    if (website?.climb is ClimbBangumi) {
      // 先以bangumi动漫链接为准
      final idStr = _extractSubjectId(anime.animeUrl);
      if (idStr.isNotEmpty) {
        subjectId = idStr;
      } else {
        _promptBindBgmSubject();
        return;
      }
    } else {
      // 如果不是bangumi，再从数据库中查找之前绑定的subjectId
      final dbSubjectId = await AnimeDao.getBgmSubjectId(anime.animeId);
      if (dbSubjectId.isEmpty) {
        _promptBindBgmSubject();
        return;
      }
      subjectId = dbSubjectId;
    }

    characters = await repository.fetchCharacters(subjectId);
    await _fillOtherInfo(characters);
    characters.sort((a, b) =>
        _getReleationPriority(b.relation) - _getReleationPriority(a.relation));
    characters.isEmpty
        ? loadStatusController.setEmpty()
        : loadStatusController.setSuccess();
  }

  void _promptBindBgmSubject() {
    subjectId = '';
    loadStatusController.setSuccess();
  }

  Future<void> bindBgmSubject(Anime bgmAnime) async {
    final idStr = _extractSubjectId(bgmAnime.animeUrl);
    await AnimeDao.setBgmSubjectId(anime.animeId, idStr);
    _loadData();
  }

  String _extractSubjectId(String animeUrl) {
    return RegExp(r'\/subject\/(\d+)').firstMatch(animeUrl)?.group(1) ?? '';
  }

  Future<void> _fillOtherInfo(List<BgmCharacter> characters) async {
    final ids = characters
        .map((c) => c.id)
        .where((id) => id != null)
        .cast<int>()
        .toList();
    if (ids.isEmpty) return;
    final characterGraphs = await repository.fetchCharacterGraphs(ids);
    for (final c in characters) {
      final graph = characterGraphs.firstWhereOrNull((g) => g.id == c.id);
      if (graph?.chineseName?.isNotEmpty == true) {
        c.name = graph?.chineseName;
        c.gender = graph?.gender;
        c.birthday = graph?.birthday;
        c.bloodType = graph?.bloodType;
        c.height = graph?.height;
        c.weight = graph?.weight;
        c.bwh = graph?.bwh;
      }
      c.comment = graph?.comment;
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
}

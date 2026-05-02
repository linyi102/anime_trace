import 'package:animetrace/models/bangumi/bangumi.dart';
import 'package:animetrace/models/bangumi/character_graph.dart';
import 'package:animetrace/models/params/result.dart';
import 'package:animetrace/utils/dio_util.dart';
import 'package:animetrace/utils/network/bangumi_api.dart';

class BangumiRepository {
  final episodesLimit = 1000;

  const BangumiRepository();

  Future<BgmSubject?> fetchSubject(String subjectId) async {
    final result = await DioUtil.get(BangumiApi.subject(subjectId),
        headers: BangumiApi.headers);
    return result.toModel(
      transform: BgmSubject.fromMap,
      dataType: ResultDataType.responseBody,
      onError: () => null,
    );
  }

  Future<List<BgmEpisode>> fetchEpisodes(String subjectId) async {
    final List<BgmEpisode> episodes = [];

    while (true) {
      final r = await DioUtil.get(
        BangumiApi.episodes,
        headers: BangumiApi.headers,
        query: {
          'subject_id': subjectId,
          'limit': episodesLimit,
          'offset': episodes.length,
        },
      );
      final eps = r.toModelList(
        transform: BgmEpisode.fromMap,
        dataType: ResultDataType.responseBodyData,
      );
      episodes.addAll(eps);

      if (eps.length < episodesLimit || episodes.length > 5000) break;
    }

    return episodes;
  }

  Future<List<BgmCharacter>> fetchCharacters(String subjectId) async {
    final result = await DioUtil.get(BangumiApi.characters(subjectId),
        headers: BangumiApi.headers);
    return result.toModelList(
      transform: BgmCharacter.fromMap,
      dataType: ResultDataType.responseBody,
    );
  }

  Future<List<BgmCharacterGraph>> fetchCharacterGraphs(
      List<int> characterIds) async {
    final result = await DioUtil.graphql(BangumiApi.graphUrl, '''
    query Query {
      ${characterIds.map((id) => 'c$id: character(id: $id) { ...CharacterGraph }').join('\n')}
    }

    fragment CharacterGraph on Character {
      id
      comment
      infobox {
        key
        values {
          k
          v
        }
      }
    }
    ''');
    return result
        .toModel(
          transform: BgmCharacterGraphList.fromMap,
          dataType: ResultDataType.responseBodyData,
          onError: () => BgmCharacterGraphList([]),
        )
        .characters;
  }

  Future<List<BgmPerson>> fetchPersons(String subjectId) async {
    final result = await DioUtil.get(BangumiApi.persons(subjectId),
        headers: BangumiApi.headers);
    return result.toModelList(
      transform: BgmPerson.fromMap,
      dataType: ResultDataType.responseBody,
    );
  }

  /// 获取用户收藏
  ///
  /// - [subjectType] 条目类型
  /// - [type] 1: 想看 2: 看过 3: 在看 4: 搁置 5: 抛弃
  /// - [pageNo] 从0开始
  /// - [pageSize] 最大100
  Future<({List<BgmSubject> list, int total})> fetchCollections({
    required String username,
    BgmSubjectType category = BgmSubjectType.all,
    required int type,
    required int pageNo,
    required int pageSize,
  }) async {
    final r = await DioUtil.get(
        '${BangumiApi.baseUrl}/v0/users/$username/collections',
        headers: BangumiApi.headers,
        query: {
          if (category != BgmSubjectType.all) 'subject_type': category.value,
          'type': type,
          'limit': pageSize,
          'offset': pageNo * pageSize,
        });
    if (r.isFailure) return (list: <BgmSubject>[], total: 0);

    return (
      list: r.toModelList<BgmSubject>(
        transform: (json) => BgmSubject.fromMap(json['subject']),
        dataType: ResultDataType.responseBodyData,
        onError: () => [],
      ),
      total: r.data.data['total'] as int? ?? 0,
    );
  }
}

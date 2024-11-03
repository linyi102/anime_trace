import 'package:flutter_test_future/models/bangumi/bangumi.dart';
import 'package:flutter_test_future/models/params/result.dart';
import 'package:flutter_test_future/utils/dio_util.dart';
import 'package:flutter_test_future/utils/network/bangumi_api.dart';

class BangumiRepository {
  Future<List<RelatedCharacter>> fetchSubjectCharacters(
      String subjectId) async {
    final result = await DioUtil.get(BangumiApi.subjectCharacters(subjectId),
        headers: BangumiApi.headers);
    return result.toModelList(
      transform: RelatedCharacter.fromMap,
      dataType: ResultDataType.responseBody,
    );
  }

  Future<List<RelatedPerson>> fetchSubjectPersons(String subjectId) async {
    final result = await DioUtil.get(BangumiApi.subjectPersons(subjectId),
        headers: BangumiApi.headers);
    return result.toModelList(
      transform: RelatedPerson.fromMap,
      dataType: ResultDataType.responseBody,
    );
  }
}

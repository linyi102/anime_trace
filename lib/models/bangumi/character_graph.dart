import 'dart:convert';

import 'package:get/get.dart';

class BgmCharacterGraph {
  final int? id;
  final int? comment;
  final List<_Infobox>? infobox;

  BgmCharacterGraph({
    this.id,
    this.comment,
    this.infobox,
  });

  factory BgmCharacterGraph.fromJson(String str) =>
      BgmCharacterGraph.fromMap(json.decode(str));

  String toJson() => json.encode(toMap());

  factory BgmCharacterGraph.fromMap(Map<String, dynamic> json) =>
      BgmCharacterGraph(
        id: json["id"],
        comment: json["comment"],
        infobox: json["infobox"] == null
            ? []
            : List<_Infobox>.from(
                json["infobox"]!.map((x) => _Infobox.fromMap(x))),
      );

  Map<String, dynamic> toMap() => {
        "id": id,
        "comment": comment,
        "infobox": infobox == null
            ? []
            : List<dynamic>.from(infobox!.map((x) => x.toMap())),
      };
}

class _Infobox {
  final String? key;
  final List<_KV>? values;

  _Infobox({
    this.key,
    this.values,
  });

  String toJson() => json.encode(toMap());

  factory _Infobox.fromMap(Map<String, dynamic> json) => _Infobox(
        key: json["key"],
        values: json["values"] == null
            ? []
            : List<_KV>.from(json["values"]!.map((x) => _KV.fromMap(x))),
      );

  Map<String, dynamic> toMap() => {
        "key": key,
        "values": values == null
            ? []
            : List<dynamic>.from(values!.map((x) => x.toMap())),
      };
}

class _KV {
  final String? k;
  final String? v;

  _KV({
    this.k,
    this.v,
  });

  String toJson() => json.encode(toMap());

  factory _KV.fromMap(Map<String, dynamic> json) => _KV(
        k: json["k"],
        v: json["v"],
      );

  Map<String, dynamic> toMap() => {
        "k": k,
        "v": v,
      };
}

class BgmCharacterGraphList {
  List<BgmCharacterGraph> characters;

  BgmCharacterGraphList(this.characters);

  factory BgmCharacterGraphList.fromJson(String str) =>
      BgmCharacterGraphList.fromMap(json.decode(str));

  factory BgmCharacterGraphList.fromMap(Map<String, dynamic> json) =>
      BgmCharacterGraphList(
          List.from(json.values.map((x) => BgmCharacterGraph.fromMap(x))));
}

extension BgmCharacterGraphX on BgmCharacterGraph {
  String? get chineseName => infobox
      ?.firstWhereOrNull((info) => info.key == '简体中文名')
      ?.values
      ?.firstOrNull
      ?.v;
}

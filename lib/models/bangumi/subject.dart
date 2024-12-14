import 'dart:convert';

import 'bangumi.dart';

class BgmSubject {
  DateTime? date;
  String? platform;
  BgmImages? images;
  String? summary;
  String? name;
  String? nameCn;
  int? totalEpisodes;
  int? id;
  int? eps;
  List<String>? metaTags;
  int? volumes;
  bool? series;
  bool? locked;
  bool? nsfw;
  int? type;

  BgmSubject({
    this.date,
    this.platform,
    this.images,
    this.summary,
    this.name,
    this.nameCn,
    this.totalEpisodes,
    this.id,
    this.eps,
    this.metaTags,
    this.volumes,
    this.series,
    this.locked,
    this.nsfw,
    this.type,
  });

  factory BgmSubject.fromJson(String str) =>
      BgmSubject.fromMap(json.decode(str));

  String toJson() => json.encode(toMap());

  factory BgmSubject.fromMap(Map<String, dynamic> json) => BgmSubject(
        date: json["date"] == null ? null : DateTime.tryParse(json["date"]),
        platform: json["platform"],
        images:
            json["images"] == null ? null : BgmImages.fromMap(json["images"]),
        summary: json["summary"],
        name: json["name"],
        nameCn: json["name_cn"],
        totalEpisodes: json["total_episodes"],
        id: json["id"],
        eps: json["eps"],
        metaTags: json["meta_tags"] == null
            ? []
            : List<String>.from(json["meta_tags"]!.map((x) => x)),
        volumes: json["volumes"],
        series: json["series"],
        locked: json["locked"],
        nsfw: json["nsfw"],
        type: json["type"],
      );

  Map<String, dynamic> toMap() => {
        "date":
            "${date!.year.toString().padLeft(4, '0')}-${date!.month.toString().padLeft(2, '0')}-${date!.day.toString().padLeft(2, '0')}",
        "platform": platform,
        "images": images?.toMap(),
        "summary": summary,
        "name": name,
        "name_cn": nameCn,
        "total_episodes": totalEpisodes,
        "id": id,
        "eps": eps,
        "meta_tags":
            metaTags == null ? [] : List<dynamic>.from(metaTags!.map((x) => x)),
        "volumes": volumes,
        "series": series,
        "locked": locked,
        "nsfw": nsfw,
        "type": type,
      };
}

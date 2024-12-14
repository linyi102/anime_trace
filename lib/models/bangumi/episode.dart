import 'dart:convert';

class BgmEpisode {
  DateTime? airdate;
  String? name;
  String? nameCn;
  String? duration;
  String? desc;
  int? ep;
  int? sort;
  int? id;
  int? subjectId;
  int? comment;
  int? type;
  int? disc;
  int? durationSeconds;

  BgmEpisode({
    this.airdate,
    this.name,
    this.nameCn,
    this.duration,
    this.desc,
    this.ep,
    this.sort,
    this.id,
    this.subjectId,
    this.comment,
    this.type,
    this.disc,
    this.durationSeconds,
  });

  factory BgmEpisode.fromJson(String str) =>
      BgmEpisode.fromMap(json.decode(str));

  String toJson() => json.encode(toMap());

  factory BgmEpisode.fromMap(Map<String, dynamic> json) => BgmEpisode(
        airdate:
            json["airdate"] == null ? null : DateTime.tryParse(json["airdate"]),
        name: json["name"],
        nameCn: json["name_cn"],
        duration: json["duration"],
        desc: json["desc"],
        ep: json["ep"],
        sort: json["sort"],
        id: json["id"],
        subjectId: json["subject_id"],
        comment: json["comment"],
        type: json["type"],
        disc: json["disc"],
        durationSeconds: json["duration_seconds"],
      );

  Map<String, dynamic> toMap() => {
        "airdate":
            "${airdate!.year.toString().padLeft(4, '0')}-${airdate!.month.toString().padLeft(2, '0')}-${airdate!.day.toString().padLeft(2, '0')}",
        "name": name,
        "name_cn": nameCn,
        "duration": duration,
        "desc": desc,
        "ep": ep,
        "sort": sort,
        "id": id,
        "subject_id": subjectId,
        "comment": comment,
        "type": type,
        "disc": disc,
        "duration_seconds": durationSeconds,
      };
}

enum BgmEpisodeType {
  main('本篇', 0),
  sp('特别篇', 1),
  op('OP', 2),
  ed('ED', 3),
  pv('预告/宣传/广告', 4),
  mad('MAD', 5),
  other('其他', 6),
  ;

  final String label;
  final int value;
  const BgmEpisodeType(this.label, this.value);
}

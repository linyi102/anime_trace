// To parse this JSON data, do
//
//     final ageRecord = ageRecordFromJson(jsonString);

import 'dart:convert';

List<AgeRecord> ageRecordFromJson(String str) =>
    List<AgeRecord>.from(json.decode(str).map((x) => AgeRecord.fromJson(x)));

String ageRecordToJson(List<AgeRecord> data) =>
    json.encode(List<dynamic>.from(data.map((x) => x.toJson())));

class AgeRecord {
  AgeRecord({
    required this.isnew,
    required this.id,
    required this.wd,
    required this.name,
    required this.mtime,
    required this.namefornew,
  });

  bool isnew;
  String id;
  int wd;
  String name;
  DateTime mtime;
  String namefornew;

  factory AgeRecord.fromJson(Map<String, dynamic> json) => AgeRecord(
        isnew: json["isnew"],
        id: json["id"],
        wd: json["wd"],
        name: json["name"],
        mtime: DateTime.parse(json["mtime"]),
        namefornew: json["namefornew"],
      );

  Map<String, dynamic> toJson() => {
        "isnew": isnew,
        "id": id,
        "wd": wd,
        "name": name,
        "mtime": mtime.toIso8601String(),
        "namefornew": namefornew,
      };
}

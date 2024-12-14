import 'dart:convert';

import 'bangumi.dart';

class BgmPerson {
  BgmImages? images;
  String? name;
  String? shortSummary;
  List<String>? career;
  int? id;
  int? type;
  bool? locked;

  BgmPerson({
    this.images,
    this.name,
    this.shortSummary,
    this.career,
    this.id,
    this.type,
    this.locked,
  });

  factory BgmPerson.fromJson(String str) =>
      BgmPerson.fromMap(json.decode(str));

  String toJson() => json.encode(toMap());

  factory BgmPerson.fromMap(Map<String, dynamic> json) => BgmPerson(
        images: json["images"] == null ? null : BgmImages.fromMap(json["images"]),
        name: json["name"],
        shortSummary: json["short_summary"],
        career: json["career"] == null
            ? []
            : List<String>.from(json["career"]!.map((x) => x)),
        id: json["id"],
        type: json["type"],
        locked: json["locked"],
      );

  Map<String, dynamic> toMap() => {
        "images": images?.toMap(),
        "name": name,
        "short_summary": shortSummary,
        "career":
            career == null ? [] : List<dynamic>.from(career!.map((x) => x)),
        "id": id,
        "type": type,
        "locked": locked,
      };
}

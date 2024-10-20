import 'dart:convert';

import 'bangumi.dart';

class RelatedPerson {
  Images? images;
  String? name;
  String? shortSummary;
  List<String>? career;
  int? id;
  int? type;
  bool? locked;

  RelatedPerson({
    this.images,
    this.name,
    this.shortSummary,
    this.career,
    this.id,
    this.type,
    this.locked,
  });

  factory RelatedPerson.fromJson(String str) =>
      RelatedPerson.fromMap(json.decode(str));

  String toJson() => json.encode(toMap());

  factory RelatedPerson.fromMap(Map<String, dynamic> json) => RelatedPerson(
        images: json["images"] == null ? null : Images.fromMap(json["images"]),
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

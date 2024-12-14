import 'dart:convert';

import 'bangumi.dart';

class BgmCharacter {
  BgmImages? images;
  String? name;
  String? relation;
  List<BgmPerson>? actors;
  int? type;
  int? id;

  BgmCharacter({
    this.images,
    this.name,
    this.relation,
    this.actors,
    this.type,
    this.id,
  });

  factory BgmCharacter.fromJson(String str) =>
      BgmCharacter.fromMap(json.decode(str));

  String toJson() => json.encode(toMap());

  factory BgmCharacter.fromMap(Map<String, dynamic> json) =>
      BgmCharacter(
        images: json["images"] == null ? null : BgmImages.fromMap(json["images"]),
        name: json["name"],
        relation: json["relation"],
        actors: json["actors"] == null
            ? []
            : List<BgmPerson>.from(
                json["actors"]!.map((x) => BgmPerson.fromMap(x))),
        type: json["type"],
        id: json["id"],
      );

  Map<String, dynamic> toMap() => {
        "images": images?.toMap(),
        "name": name,
        "relation": relation,
        "actors": actors == null
            ? []
            : List<dynamic>.from(actors!.map((x) => x.toMap())),
        "type": type,
        "id": id,
      };
}

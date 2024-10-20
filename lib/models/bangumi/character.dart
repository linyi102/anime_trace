import 'dart:convert';

import 'bangumi.dart';

class RelatedCharacter {
  Images? images;
  String? name;
  String? relation;
  List<RelatedPerson>? actors;
  int? type;
  int? id;

  RelatedCharacter({
    this.images,
    this.name,
    this.relation,
    this.actors,
    this.type,
    this.id,
  });

  factory RelatedCharacter.fromJson(String str) =>
      RelatedCharacter.fromMap(json.decode(str));

  String toJson() => json.encode(toMap());

  factory RelatedCharacter.fromMap(Map<String, dynamic> json) =>
      RelatedCharacter(
        images: json["images"] == null ? null : Images.fromMap(json["images"]),
        name: json["name"],
        relation: json["relation"],
        actors: json["actors"] == null
            ? []
            : List<RelatedPerson>.from(
                json["actors"]!.map((x) => RelatedPerson.fromMap(x))),
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

import 'dart:convert';

import 'bangumi.dart';

class BgmCharacter {
  BgmImages? images;
  String? name;
  String? relation;
  List<BgmPerson>? actors;
  int? type;
  int? id;
  int? comment;
  String? gender;
  String? birthday;
  String? bloodType;
  String? height;
  String? weight;
  String? bwh;

  BgmCharacter({
    this.images,
    this.name,
    this.relation,
    this.actors,
    this.type,
    this.id,
    this.comment,
    this.gender,
    this.birthday,
    this.bloodType,
    this.height,
    this.weight,
    this.bwh,
  });

  factory BgmCharacter.fromJson(String str) =>
      BgmCharacter.fromMap(json.decode(str));

  String toJson() => json.encode(toMap());

  factory BgmCharacter.fromMap(Map<String, dynamic> json) => BgmCharacter(
        images:
            json["images"] == null ? null : BgmImages.fromMap(json["images"]),
        name: json["name"],
        relation: json["relation"],
        actors: json["actors"] == null
            ? []
            : List<BgmPerson>.from(
                json["actors"]!.map((x) => BgmPerson.fromMap(x))),
        type: json["type"],
        id: json["id"],
        comment: json["comment"],
        gender: json["gender"],
        birthday: json["birthday"],
        bloodType: json["bloodType"],
        height: json["height"],
        weight: json["weight"],
        bwh: json["bwh"],
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
        "comment": comment,
        "gender": gender,
        "birthday": birthday,
        "bloodType": bloodType,
        "height": height,
        "weight": weight,
        "bwh": bwh,
      };
}

extension BgmCharacterX on BgmCharacter {
  String get actorsText =>
      actors
          ?.map((e) => e.name ?? '')
          .where((name) => name.isNotEmpty)
          .join(' / ') ??
      '';
}

import 'dart:convert';

class MigrateConfig {
  bool nameIsNew;
  bool anotherNameIsNew;
  bool areaIsNew;
  bool categoryIsNew;
  bool premiereTimeIsNew;
  bool playStatusIsNew;
  bool urlIsNew;
  bool coverIsNew;
  bool descIsNew;

  MigrateConfig({
    bool? nameIsNew,
    bool? anotherNameIsNew,
    bool? areaIsNew,
    bool? categoryIsNew,
    bool? premiereTimeIsNew,
    bool? playStatusIsNew,
    bool? urlIsNew,
    bool? coverIsNew,
    bool? descIsNew,
    bool defaultValue = true,
  })  : nameIsNew = nameIsNew ?? defaultValue,
        anotherNameIsNew = anotherNameIsNew ?? defaultValue,
        areaIsNew = areaIsNew ?? defaultValue,
        categoryIsNew = categoryIsNew ?? defaultValue,
        premiereTimeIsNew = premiereTimeIsNew ?? defaultValue,
        playStatusIsNew = playStatusIsNew ?? defaultValue,
        urlIsNew = urlIsNew ?? defaultValue,
        coverIsNew = coverIsNew ?? defaultValue,
        descIsNew = descIsNew ?? defaultValue;

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'nameIsNew': nameIsNew,
      'anotherNameIsNew': anotherNameIsNew,
      'areaIsNew': areaIsNew,
      'categoryIsNew': categoryIsNew,
      'premiereTimeIsNew': premiereTimeIsNew,
      'playStatusIsNew': playStatusIsNew,
      'urlIsNew': urlIsNew,
      'coverIsNew': coverIsNew,
      'descIsNew': descIsNew,
    };
  }

  factory MigrateConfig.fromMap(Map<String, dynamic> map) {
    return MigrateConfig(
      nameIsNew: map['nameIsNew'] as bool,
      anotherNameIsNew: map['anotherNameIsNew'] as bool,
      areaIsNew: map['areaIsNew'] as bool,
      categoryIsNew: map['categoryIsNew'] as bool,
      premiereTimeIsNew: map['premiereTimeIsNew'] as bool,
      playStatusIsNew: map['playStatusIsNew'] as bool,
      urlIsNew: map['urlIsNew'] as bool,
      coverIsNew: map['coverIsNew'] as bool,
      descIsNew: map['descIsNew'] as bool,
    );
  }

  String toJson() => json.encode(toMap());

  factory MigrateConfig.fromJson(String source) =>
      MigrateConfig.fromMap(json.decode(source) as Map<String, dynamic>);
}

import 'dart:convert';

class BgmImages {
  String? small;
  String? grid;
  String? large;
  String? medium;

  BgmImages({
    this.small,
    this.grid,
    this.large,
    this.medium,
  });

  factory BgmImages.fromJson(String str) => BgmImages.fromMap(json.decode(str));

  String toJson() => json.encode(toMap());

  factory BgmImages.fromMap(Map<String, dynamic> json) => BgmImages(
        small: json["small"],
        grid: json["grid"],
        large: json["large"],
        medium: json["medium"],
      );

  Map<String, dynamic> toMap() => {
        "small": small,
        "grid": grid,
        "large": large,
        "medium": medium,
      };
}

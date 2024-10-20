import 'dart:convert';

class Images {
  String? small;
  String? grid;
  String? large;
  String? medium;

  Images({
    this.small,
    this.grid,
    this.large,
    this.medium,
  });

  factory Images.fromJson(String str) => Images.fromMap(json.decode(str));

  String toJson() => json.encode(toMap());

  factory Images.fromMap(Map<String, dynamic> json) => Images(
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

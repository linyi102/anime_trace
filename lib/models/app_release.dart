// To parse this JSON data, do
//
//     final appRelease = appReleaseFromJson(jsonString);

import 'dart:convert';

AppRelease appReleaseFromJson(String str) =>
    AppRelease.fromJson(json.decode(str));

String appReleaseToJson(AppRelease data) => json.encode(data.toJson());

class AppRelease {
  int id;
  String nodeId;
  String tagName;
  String targetCommitish;
  String name;
  List<Asset> assets;
  String body;

  AppRelease({
    required this.id,
    required this.nodeId,
    required this.tagName,
    required this.targetCommitish,
    required this.name,
    required this.assets,
    required this.body,
  });

  factory AppRelease.fromJson(Map<String, dynamic> json) => AppRelease(
        id: json["id"],
        nodeId: json["node_id"],
        tagName: json["tag_name"],
        targetCommitish: json["target_commitish"],
        name: json["name"],
        assets: List<Asset>.from(json["assets"].map((x) => Asset.fromJson(x))),
        body: json["body"],
      );

  Map<String, dynamic> toJson() => {
        "id": id,
        "node_id": nodeId,
        "tag_name": tagName,
        "target_commitish": targetCommitish,
        "name": name,
        "assets": List<dynamic>.from(assets.map((x) => x.toJson())),
        "body": body,
      };
}

class Asset {
  String url;
  int id;
  String nodeId;
  String name;
  dynamic label;
  String contentType;
  String state;
  int size;
  int downloadCount;
  DateTime createdAt;
  DateTime updatedAt;
  String browserDownloadUrl;

  Asset({
    required this.url,
    required this.id,
    required this.nodeId,
    required this.name,
    this.label,
    required this.contentType,
    required this.state,
    required this.size,
    required this.downloadCount,
    required this.createdAt,
    required this.updatedAt,
    required this.browserDownloadUrl,
  });

  factory Asset.fromJson(Map<String, dynamic> json) => Asset(
        url: json["url"],
        id: json["id"],
        nodeId: json["node_id"],
        name: json["name"],
        label: json["label"],
        contentType: json["content_type"],
        state: json["state"],
        size: json["size"],
        downloadCount: json["download_count"],
        createdAt: DateTime.parse(json["created_at"]),
        updatedAt: DateTime.parse(json["updated_at"]),
        browserDownloadUrl: json["browser_download_url"],
      );

  Map<String, dynamic> toJson() => {
        "url": url,
        "id": id,
        "node_id": nodeId,
        "name": name,
        "label": label,
        "content_type": contentType,
        "state": state,
        "size": size,
        "download_count": downloadCount,
        "created_at": createdAt.toIso8601String(),
        "updated_at": updatedAt.toIso8601String(),
        "browser_download_url": browserDownloadUrl,
      };
}

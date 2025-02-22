/// GENERATED CODE - DO NOT MODIFY BY HAND
/// *****************************************************
///  FlutterGen
/// *****************************************************

// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: directives_ordering,unnecessary_import,implicit_dynamic_list_literal,deprecated_member_use

import 'package:flutter/widgets.dart';

class $AssetsIconsGen {
  const $AssetsIconsGen();

  /// File path: assets/icons/chat_4_line.svg
  String get chat4Line => 'assets/icons/chat_4_line.svg';

  /// File path: assets/icons/collections-24-filled.svg
  String get collections24Filled => 'assets/icons/collections-24-filled.svg';

  /// File path: assets/icons/collections-24-regular.svg
  String get collections24Regular => 'assets/icons/collections-24-regular.svg';

  /// File path: assets/icons/default_picture.png
  AssetGenImage get defaultPicture =>
      const AssetGenImage('assets/icons/default_picture.png');

  /// File path: assets/icons/eva--checkmark-square-outline.svg
  String get evaCheckmarkSquareOutline =>
      'assets/icons/eva--checkmark-square-outline.svg';

  /// File path: assets/icons/eva--collapse-outline.svg
  String get evaCollapseOutline => 'assets/icons/eva--collapse-outline.svg';

  /// File path: assets/icons/eva--expand-outline.svg
  String get evaExpandOutline => 'assets/icons/eva--expand-outline.svg';

  /// File path: assets/icons/eva--external-link-outline.svg
  String get evaExternalLinkOutline =>
      'assets/icons/eva--external-link-outline.svg';

  /// File path: assets/icons/eva--square-outline.svg
  String get evaSquareOutline => 'assets/icons/eva--square-outline.svg';

  /// File path: assets/icons/failed_picture.png
  AssetGenImage get failedPicture =>
      const AssetGenImage('assets/icons/failed_picture.png');

  /// File path: assets/icons/gitee.svg
  String get gitee => 'assets/icons/gitee.svg';

  /// File path: assets/icons/github.svg
  String get github => 'assets/icons/github.svg';

  /// File path: assets/icons/infini_cloud.svg
  String get infiniCloud => 'assets/icons/infini_cloud.svg';

  /// File path: assets/icons/jianguoyun.png
  AssetGenImage get jianguoyun =>
      const AssetGenImage('assets/icons/jianguoyun.png');

  /// List of all assets
  List<dynamic> get values => [
    chat4Line,
    collections24Filled,
    collections24Regular,
    defaultPicture,
    evaCheckmarkSquareOutline,
    evaCollapseOutline,
    evaExpandOutline,
    evaExternalLinkOutline,
    evaSquareOutline,
    failedPicture,
    gitee,
    github,
    infiniCloud,
    jianguoyun,
  ];
}

class $AssetsImagesGen {
  const $AssetsImagesGen();

  /// File path: assets/images/logo-round.png
  AssetGenImage get logoRound =>
      const AssetGenImage('assets/images/logo-round.png');

  /// Directory path: assets/images/website
  $AssetsImagesWebsiteGen get website => const $AssetsImagesWebsiteGen();

  /// List of all assets
  List<AssetGenImage> get values => [logoRound];
}

class $AssetsLottiesGen {
  const $AssetsLottiesGen();

  /// File path: assets/lotties/playing.json
  String get playing => 'assets/lotties/playing.json';

  /// List of all assets
  List<String> get values => [playing];
}

class $AssetsImagesWebsiteGen {
  const $AssetsImagesWebsiteGen();

  /// File path: assets/images/website/OmoFun.jpg
  AssetGenImage get omoFun =>
      const AssetGenImage('assets/images/website/OmoFun.jpg');

  /// File path: assets/images/website/agemys.jpg
  AssetGenImage get agemys =>
      const AssetGenImage('assets/images/website/agemys.jpg');

  /// File path: assets/images/website/aimi.jpg
  AssetGenImage get aimi =>
      const AssetGenImage('assets/images/website/aimi.jpg');

  /// File path: assets/images/website/bangumi.png
  AssetGenImage get bangumi =>
      const AssetGenImage('assets/images/website/bangumi.png');

  /// File path: assets/images/website/cyc.png
  AssetGenImage get cyc => const AssetGenImage('assets/images/website/cyc.png');

  /// File path: assets/images/website/douban.ico
  String get douban => 'assets/images/website/douban.ico';

  /// File path: assets/images/website/fzff.png
  AssetGenImage get fzff =>
      const AssetGenImage('assets/images/website/fzff.png');

  /// File path: assets/images/website/gugu.png
  AssetGenImage get gugu =>
      const AssetGenImage('assets/images/website/gugu.png');

  /// File path: assets/images/website/nayfun.png
  AssetGenImage get nayfun =>
      const AssetGenImage('assets/images/website/nayfun.png');

  /// File path: assets/images/website/qdm.png
  AssetGenImage get qdm => const AssetGenImage('assets/images/website/qdm.png');

  /// File path: assets/images/website/quqi.ico
  String get quqi => 'assets/images/website/quqi.ico';

  /// File path: assets/images/website/yhdm.ico
  String get yhdm => 'assets/images/website/yhdm.ico';

  /// List of all assets
  List<dynamic> get values => [
    omoFun,
    agemys,
    aimi,
    bangumi,
    cyc,
    douban,
    fzff,
    gugu,
    nayfun,
    qdm,
    quqi,
    yhdm,
  ];
}

class Assets {
  const Assets._();

  static const $AssetsIconsGen icons = $AssetsIconsGen();
  static const $AssetsImagesGen images = $AssetsImagesGen();
  static const $AssetsLottiesGen lotties = $AssetsLottiesGen();
}

class AssetGenImage {
  const AssetGenImage(this._assetName, {this.size, this.flavors = const {}});

  final String _assetName;

  final Size? size;
  final Set<String> flavors;

  Image image({
    Key? key,
    AssetBundle? bundle,
    ImageFrameBuilder? frameBuilder,
    ImageErrorWidgetBuilder? errorBuilder,
    String? semanticLabel,
    bool excludeFromSemantics = false,
    double? scale,
    double? width,
    double? height,
    Color? color,
    Animation<double>? opacity,
    BlendMode? colorBlendMode,
    BoxFit? fit,
    AlignmentGeometry alignment = Alignment.center,
    ImageRepeat repeat = ImageRepeat.noRepeat,
    Rect? centerSlice,
    bool matchTextDirection = false,
    bool gaplessPlayback = true,
    bool isAntiAlias = false,
    String? package,
    FilterQuality filterQuality = FilterQuality.medium,
    int? cacheWidth,
    int? cacheHeight,
  }) {
    return Image.asset(
      _assetName,
      key: key,
      bundle: bundle,
      frameBuilder: frameBuilder,
      errorBuilder: errorBuilder,
      semanticLabel: semanticLabel,
      excludeFromSemantics: excludeFromSemantics,
      scale: scale,
      width: width,
      height: height,
      color: color,
      opacity: opacity,
      colorBlendMode: colorBlendMode,
      fit: fit,
      alignment: alignment,
      repeat: repeat,
      centerSlice: centerSlice,
      matchTextDirection: matchTextDirection,
      gaplessPlayback: gaplessPlayback,
      isAntiAlias: isAntiAlias,
      package: package,
      filterQuality: filterQuality,
      cacheWidth: cacheWidth,
      cacheHeight: cacheHeight,
    );
  }

  ImageProvider provider({AssetBundle? bundle, String? package}) {
    return AssetImage(_assetName, bundle: bundle, package: package);
  }

  String get path => _assetName;

  String get keyName => _assetName;
}

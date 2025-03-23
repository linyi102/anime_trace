import 'package:animetrace/components/common_image.dart';
import 'package:animetrace/models/bangumi/bangumi.dart';
import 'package:animetrace/utils/launch_uri_util.dart';
import 'package:animetrace/values/theme.dart';
import 'package:flutter/material.dart';

class CharacterDetailView extends StatefulWidget {
  const CharacterDetailView({
    super.key,
    required this.characters,
    required this.selectedIndex,
  });
  final List<BgmCharacter> characters;
  final int selectedIndex;

  @override
  State<CharacterDetailView> createState() => _CharacterDetailViewState();
}

class _CharacterDetailViewState extends State<CharacterDetailView> {
  late int selectedIndex = widget.selectedIndex;

  @override
  Widget build(BuildContext context) {
    final character = widget.characters[selectedIndex];
    return AlertDialog(
      title: Row(
        children: [
          _buildAvatar(character),
          const SizedBox(width: 12),
          Expanded(
            child: Text(character.name ?? '', overflow: TextOverflow.ellipsis),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: _buildInfoGrid(
          children: [
            _buildInfoTile('关系', character.relation),
            _buildInfoTile('声优', character.actorsText),
            _buildInfoTile('性别', character.gender),
            _buildInfoTile('生日', character.birthday),
            _buildInfoTile('血型', character.bloodType),
            _buildInfoTile('身高', character.height),
            _buildInfoTile('体重', character.weight),
            _buildInfoTile('BWH', character.bwh),
          ],
        ),
      ),
      actions: [
        TextButton(
            onPressed: () => openDetailWeb(context, character),
            child: const Text('查看网页')),
        TextButton(
            onPressed: Navigator.of(context).pop, child: const Text('关闭'))
      ],
    );
  }

  // ignore: unused_element
  List<Widget> _buildSwitchActions(BgmCharacter character) {
    return [
      IconButton(
        onPressed: () => setState(() {
          selectedIndex--;
          if (selectedIndex < 0) selectedIndex = widget.characters.length - 1;
        }),
        icon: const Icon(Icons.chevron_left),
      ),
      IconButton(
        onPressed: () => openDetailWeb(context, character),
        icon: const Icon(Icons.open_in_new),
      ),
      IconButton(
        onPressed: () => setState(() {
          selectedIndex++;
          if (selectedIndex >= widget.characters.length) selectedIndex = 0;
        }),
        icon: const Icon(Icons.chevron_right),
      ),
    ];
  }

  Widget _buildInfoGrid({required List<Widget> children}) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (int i = 0; i < children.length; i += 2)
          Row(
            children: [
              Expanded(child: children[i]),
              if (i + 1 < children.length) Expanded(child: children[i + 1]),
            ],
          ),
      ],
    );
  }

  ClipRRect _buildAvatar(BgmCharacter character) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppTheme.imgRadius),
      child: SizedBox(
        height: 42,
        width: 42,
        child: CommonImage(
          character.images?.grid ?? '',
          alignment: Alignment.topCenter,
        ),
      ),
    );
  }

  Widget _buildInfoTile(String title, String? content) {
    return ListTile(
      title: Text(title),
      subtitle: Text(
        content?.isNotEmpty == true ? content! : '-',
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
      contentPadding: EdgeInsets.zero,
    );
  }

  void openDetailWeb(BuildContext context, BgmCharacter character) {
    LaunchUrlUtil.launch(
        context: context, uriStr: 'https://bgm.tv/character/${character.id}');
  }
}

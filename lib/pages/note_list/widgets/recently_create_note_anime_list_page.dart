import 'package:flutter/material.dart';
import 'package:animetrace/components/anime_list_tile.dart';
import 'package:animetrace/components/loading_widget.dart';
import 'package:animetrace/dao/episode_note_dao.dart';
import 'package:animetrace/models/anime.dart';
import 'package:animetrace/models/enum/note_type.dart';
import 'package:animetrace/utils/extensions/color.dart';
import 'package:super_sliver_list/super_sliver_list.dart';

class RecentlyCreateNoteAnimeListPage extends StatefulWidget {
  const RecentlyCreateNoteAnimeListPage(
      {super.key, required this.noteType, this.selectedAnime, this.onTapItem});
  final Anime? selectedAnime;
  final NoteType noteType;
  final void Function(Anime? anime)? onTapItem;

  @override
  State<RecentlyCreateNoteAnimeListPage> createState() =>
      _RecentlyCreateNoteAnimeListPageState();
}

class _RecentlyCreateNoteAnimeListPageState
    extends State<RecentlyCreateNoteAnimeListPage> {
  List<Anime> recentlyCreateNoteAnimes = [];
  bool loadOk = false;

  @override
  void initState() {
    super.initState();
    _loadRecentlyCreatNoteAnime();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: loadOk
          ? SuperListView.builder(
              itemCount: recentlyCreateNoteAnimes.length + 1,
              itemBuilder: (context, index) {
                if (index == 0) {
                  return _buildAnimeItemCard(
                    child: ListTile(title: Text('全部${widget.noteType.title}')),
                    isSelected: widget.selectedAnime == null,
                  );
                }

                final animeIndex = index - 1;
                final anime = recentlyCreateNoteAnimes[animeIndex];
                return _buildAnimeItemCard(
                    child: AnimeListTile(anime: anime),
                    anime: anime,
                    isSelected: anime == widget.selectedAnime);
              },
            )
          : const LoadingWidget(),
    );
  }

  Container _buildAnimeItemCard({
    required Widget child,
    bool isSelected = false,
    Anime? anime,
  }) {
    var radius = BorderRadius.circular(6);

    return Container(
      margin: const EdgeInsets.fromLTRB(10, 2, 15, 2),
      decoration: BoxDecoration(
        borderRadius: radius,
        color: isSelected
            ? Theme.of(context).primaryColor.withOpacityFactor(0.2)
            : null,
      ),
      child: InkWell(
        borderRadius: radius,
        onTap: () {
          widget.onTapItem?.call(anime);
        },
        child: child,
      ),
    );
  }

  _loadRecentlyCreatNoteAnime() async {
    recentlyCreateNoteAnimes = await EpisodeNoteDao.getAnimesRecentlyCreateNote(
        noteType: widget.noteType);
    loadOk = true;
    if (mounted) setState(() {});
  }
}

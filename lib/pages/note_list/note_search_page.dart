import 'package:animetrace/models/enum/note_type.dart';
import 'package:animetrace/pages/note_list/widgets/rate_note_list_page.dart';
import 'package:flutter/material.dart';
import 'package:animetrace/models/note_filter.dart';
import 'package:animetrace/pages/note_list/widgets/episode_note_list_page.dart';
import 'package:animetrace/widgets/responsive.dart';

class NoteSearchPage extends StatefulWidget {
  const NoteSearchPage({super.key});

  @override
  State<NoteSearchPage> createState() => _NoteSearchPageState();
}

class _NoteSearchPageState extends State<NoteSearchPage> {
  final animeNameController = TextEditingController();
  final noteContentController = TextEditingController();
  bool inputOk = false;
  NoteFilter noteFilter = NoteFilter();
  NoteType noteType = NoteType.episode;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            _buildFormCard(),
            if (inputOk) Expanded(child: _buildSearchResult())
          ],
        ),
      ),
    );
  }

  Widget _buildSearchResult() {
    switch (noteType) {
      case NoteType.episode:
        return EpisodeNoteListPage(
          noteFilter: noteFilter,
          key: ValueKey(noteFilter.valueKeyStr),
        );
      case NoteType.rate:
        return RateNoteListPage(
          noteFilter: noteFilter,
          key: ValueKey(noteFilter.valueKeyStr),
        );
    }
  }

  bool isExpanded = true;

  _buildFormCard() {
    return ExpansionPanelList(
      expansionCallback: (_, __) {
        setState(() {
          isExpanded = !isExpanded;
        });
      },
      elevation: 0,
      children: [
        ExpansionPanel(
            isExpanded: isExpanded,
            canTapOnHeader: true,
            headerBuilder: (context, isExpanded) {
              return ListTile(
                leading: IconButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    icon: Icon(
                      Icons.arrow_back,
                      color: Theme.of(context).appBarTheme.iconTheme?.color,
                    )),
                title: Text('搜索${noteType.title}'),
              );
            },
            body: _buildSearchForm())
      ],
    );
  }

  Container _buildSearchForm() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Column(
        children: [
          Responsive(
            mobile: Column(
              children: [
                _buildNameTextField(),
                const SizedBox(height: 10),
                _buildContentTextField(),
              ],
            ),
            desktop: Row(
              children: [
                Expanded(
                  child: _buildNameTextField(),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildContentTextField(),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              DropdownMenu<NoteType>(
                requestFocusOnTap: false,
                initialSelection: noteType,
                dropdownMenuEntries: NoteType.values
                    .map((e) => DropdownMenuEntry(value: e, label: e.title))
                    .toList(),
                onSelected: (value) {
                  if (value == null) return;
                  setState(() {
                    noteType = value;
                  });
                },
              ),
              const Spacer(),
              FilledButton(
                onPressed: () {
                  noteFilter.animeNameKeyword = animeNameController.text;
                  noteFilter.noteContentKeyword = noteContentController.text;
                  _markInputOk();
                },
                child: const Text('搜索'),
              )
            ],
          ),
        ],
      ),
    );
  }

  TextField _buildContentTextField() {
    return _buildCommonTextField(
      inputController: noteContentController,
      title: '${noteType.title}内容',
    );
  }

  TextField _buildNameTextField() {
    return _buildCommonTextField(
      inputController: animeNameController,
      title: '动漫名称',
    );
  }

  TextField _buildCommonTextField({
    required TextEditingController inputController,
    String title = '',
  }) {
    return TextField(
      controller: inputController,
      decoration: InputDecoration(
        labelText: title,
      ),
    );
  }

  _markInputOk() {
    setState(() {
      inputOk = true;
      isExpanded = false;
    });
  }

  @override
  void dispose() {
    animeNameController.dispose();
    noteContentController.dispose();
    super.dispose();
  }
}

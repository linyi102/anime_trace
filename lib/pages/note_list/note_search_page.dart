import 'package:animetrace/models/enum/note_type.dart';
import 'package:animetrace/pages/note_list/widgets/rate_note_list_page.dart';
import 'package:flutter/material.dart';
import 'package:animetrace/models/note_filter.dart';
import 'package:animetrace/pages/note_list/widgets/episode_note_list_page.dart';
import 'package:animetrace/utils/extensions/color.dart';
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
            backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
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
          const SizedBox(height: 20),
          Row(
            children: [
              const Text('搜索类型：'),
              DropdownButton<NoteType>(
                value: noteType,
                items: NoteType.values
                    .map((e) => DropdownMenuItem(
                          value: e,
                          child: Text(e.title),
                        ))
                    .toList(),
                onChanged: (value) {
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
        labelStyle: TextStyle(fontSize: 14, color: Theme.of(context).hintColor),
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(color: Theme.of(context).colorScheme.primary),
          borderRadius: BorderRadius.circular(12),
        ),
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(
              color: Theme.of(context).hintColor.withOpacityFactor(0.2)),
          borderRadius: BorderRadius.circular(12),
        ),
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

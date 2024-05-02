import 'package:flutter/material.dart';
import 'package:flutter_test_future/components/website_logo.dart';
import 'package:flutter_test_future/models/enum/search_source.dart';
import 'package:flutter_test_future/pages/local_search/controllers/local_search_controller.dart';
import 'package:flutter_test_future/pages/local_search/models/local_select_filter.dart';
import 'package:get/get.dart';

class SelectSourceView extends StatefulWidget {
  const SelectSourceView({required this.localSearchController, super.key});
  final LocalSearchController localSearchController;

  @override
  State<SelectSourceView> createState() => _SelectSourceViewState();
}

class _SelectSourceViewState extends State<SelectSourceView> {
  LocalSelectFilter get localSelectFilter =>
      widget.localSearchController.localSelectFilter;

  @override
  Widget build(BuildContext context) {
    return GetBuilder(
      init: widget.localSearchController,
      builder: (_) => Scaffold(
        body: ListView.builder(
          itemCount: AnimeSource.values.length,
          itemBuilder: (context, index) {
            final source = AnimeSource.values[index];
            final website = AnimeSource.getWebsite(source);

            return RadioListTile<AnimeSource>(
                title: Text(source.label),
                toggleable: true,
                controlAffinity: ListTileControlAffinity.trailing,
                secondary: website == null
                    ? null
                    : WebSiteLogo(
                        url: AnimeSource.getWebsite(source)!.iconUrl, size: 25),
                value: source,
                groupValue: localSelectFilter.source,
                onChanged: (value) {
                  widget.localSearchController.setSource(value);
                });
          },
        ),
      ),
    );
  }
}

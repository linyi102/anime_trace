import 'package:flutter/material.dart';
import 'package:flutter_test_future/components/website_logo.dart';
import 'package:flutter_test_future/models/climb_website.dart';
import 'package:flutter_test_future/pages/local_search/controllers/local_search_controller.dart';
import 'package:flutter_test_future/pages/local_search/models/local_select_filter.dart';
import 'package:flutter_test_future/utils/global_data.dart';
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

  final websites = [
    customSource,
    ...climbWebsites,
  ];

  @override
  Widget build(BuildContext context) {
    return GetBuilder(
      init: widget.localSearchController,
      builder: (_) => Scaffold(
        body: ListView.builder(
          itemCount: websites.length,
          itemBuilder: (context, index) {
            final website = websites[index];

            return RadioListTile<ClimbWebsite>(
                title: Text(website.name),
                toggleable: true,
                controlAffinity: ListTileControlAffinity.leading,
                secondary: website.iconUrl.isEmpty
                    ? null
                    : WebSiteLogo(url: website.iconUrl, size: 24),
                value: website,
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

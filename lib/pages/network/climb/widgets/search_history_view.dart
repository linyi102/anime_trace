import 'package:animetrace/dao/config_dao.dart';
import 'package:animetrace/values/theme.dart';
import 'package:flutter/material.dart';

class SearchHistoryView extends StatelessWidget {
  const SearchHistoryView({
    super.key,
    required this.controller,
    required this.onTapKeyword,
  });
  final SearchHistoryController controller;
  final void Function(String keyword) onTapKeyword;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, child) {
        if (controller._keywords.isEmpty) return const SizedBox();
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ListTile(
                title: const Text(
                  '搜索历史',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                trailing: IconButton(
                    onPressed: () => _showClearAllDialog(context),
                    icon: const Icon(Icons.delete_outline_outlined)),
              ),
              Container(
                constraints: BoxConstraints(
                    maxHeight: 96 + (AppTheme.wrapRunSpacing * 2)),
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: SingleChildScrollView(
                  child: Wrap(
                    spacing: AppTheme.wrapSacing,
                    runSpacing: AppTheme.wrapRunSpacing,
                    children: [
                      for (final keyword in controller._keywords.reversed)
                        InputChip(
                          label: Text(keyword,
                              style: const TextStyle(fontSize: 14, height: 1)),
                          onPressed: () => onTapKeyword(keyword),
                          onDeleted: () => controller.removeKeyword(keyword),
                          deleteIconColor: Theme.of(context).hintColor,
                          deleteIcon: const Icon(Icons.close, size: 16),
                          deleteButtonTooltipMessage: '',
                        )
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<dynamic> _showClearAllDialog(BuildContext context) {
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('提示'),
        content: const Text('确定删除全部搜索历史？'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context), child: const Text('取消')),
          TextButton(
              onPressed: () {
                Navigator.pop(context);
                controller.clearKeywords();
              },
              child: Text(
                '删除',
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              )),
        ],
      ),
    );
  }
}

class SearchHistoryController extends ChangeNotifier {
  List<String> _keywords = [];
  final int maxKeywordCnt = 5;

  SearchHistoryController() {
    _init();
  }

  Future<void> _init() async {
    _keywords = await ConfigDao.getSearchHistoryKeywords();
    notifyListeners();
  }

  void addKeyword(String keyword) {
    if (_keywords.contains(keyword)) {
      _keywords.remove(keyword);
    }
    _keywords.add(keyword);
    if (_keywords.length > maxKeywordCnt) {
      _keywords = _keywords.sublist(_keywords.length - maxKeywordCnt);
    }
    notifyListeners();
    ConfigDao.setSearchHistoryKeywords(_keywords);
  }

  void removeKeyword(String keyword) {
    _keywords.remove(keyword);
    notifyListeners();
    ConfigDao.setSearchHistoryKeywords(_keywords);
  }

  void clearKeywords() {
    _keywords.clear();
    notifyListeners();
    ConfigDao.setSearchHistoryKeywords(_keywords);
  }
}

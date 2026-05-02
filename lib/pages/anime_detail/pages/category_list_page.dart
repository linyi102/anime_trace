import 'package:animetrace/controllers/category_controller.dart';
import 'package:animetrace/utils/platform.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class AnimeCategoryListPage extends StatefulWidget {
  const AnimeCategoryListPage({super.key});

  @override
  State<AnimeCategoryListPage> createState() => _AnimeCategoryListPageState();
}

class _AnimeCategoryListPageState extends State<AnimeCategoryListPage> {
  final controller = CategoryController.to;

  @override
  Widget build(BuildContext context) {
    return GetBuilder(
      init: controller,
      builder: (controller) {
        return Scaffold(
          appBar: AppBar(title: const Text('动漫类别')),
          body: ReorderableListView(
            children: List.generate(controller.categories.length, (index) {
              final category = controller.categories[index];

              return ListTile(
                key: ValueKey(index),
                title: Text(category),
                leading: PlatformUtil.isDesktop
                    ? _buildDeleteButton(index)
                    : const Icon(Icons.drag_indicator),
                trailing:
                    PlatformUtil.isDesktop ? null : _buildDeleteButton(index),
                onTap: controller.isReadonly(controller.categories[index])
                    ? null
                    : () => showUpdateDialog(context, index),
              );
            }),
            onReorder: controller.updateOrder,
          ),
          floatingActionButton: FloatingActionButton(
            onPressed: () => showCreateDialog(context),
            child: const Icon(Icons.add),
          ),
        );
      },
    );
  }

  Widget _buildDeleteButton(int index) {
    return IconButton(
      onPressed: controller.isReadonly(controller.categories[index])
          ? null
          : () => showDeleteDialog(context, index),
      icon: const Icon(Icons.delete_outline),
    );
  }

  void showCreateDialog(BuildContext context) async {
    final inputController = TextEditingController();

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('添加类别'),
          content: TextField(
            controller: inputController,
            autofocus: true,
            decoration: const InputDecoration(labelText: '类别名称'),
            maxLength: 10,
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('取消')),
            TextButton(
                onPressed: () {
                  final r = controller.addCategory(inputController.text);
                  if (r) Navigator.pop(context);
                },
                child: const Text('确定')),
          ],
        );
      },
    );

    // NOTE: Windows 使用 ESC 隐藏对话框时直接销毁文本控制器会报错：
    // Once you have called dispose() on a TextEditingController, it can no longer be used.
    // 因此推迟到下一帧
    WidgetsBinding.instance.addPostFrameCallback((_) {
      inputController.dispose();
    });
  }

  void showUpdateDialog(BuildContext context, int index) async {
    final category = controller.categories[index];
    final inputController = TextEditingController(text: category);

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('修改类别'),
          content: TextField(
            controller: inputController,
            autofocus: true,
            decoration: const InputDecoration(labelText: '类别名称'),
            maxLength: 10,
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('取消')),
            TextButton(
                onPressed: () {
                  final r =
                      controller.updateCategory(index, inputController.text);
                  if (r) Navigator.pop(context);
                },
                child: const Text('确定')),
          ],
        );
      },
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      inputController.dispose();
    });
  }

  void showDeleteDialog(BuildContext context, int index) {
    showDialog(
      context: context,
      builder: (context) {
        final category = controller.categories[index];

        return AlertDialog(
          title: const Text('确定删除吗？'),
          content: Text('将要删除的类别：$category'),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('取消')),
            TextButton(
              onPressed: () async {
                controller.removeCategory(category);
                Navigator.pop(context);
              },
              child: Text(
                '删除',
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ),
          ],
        );
      },
    );
  }
}

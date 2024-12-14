import 'package:flutter/material.dart';
import 'package:flutter_test_future/controllers/remote_controller.dart';
import 'package:flutter_test_future/pages/settings/backup_restore/remote.dart';
import 'package:flutter_test_future/values/theme.dart';
import 'package:flutter_test_future/widgets/bottom_sheet.dart';
import 'package:get/get.dart';

class RemoteStatusIconButton extends StatelessWidget {
  const RemoteStatusIconButton({super.key});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        IconButton(
          onPressed: () {
            showCommonModalBottomSheet(
              context: context,
              isScrollControlled: true,
              builder: (context) => Material(
                color: Theme.of(context).scaffoldBackgroundColor,
                child: const RemoteBackupPage(fromHome: true),
              ),
            );
          },
          icon: const Icon(Icons.cloud_outlined),
          tooltip: "云端数据",
        ),
        Positioned(
          right: 4,
          bottom: 8,
          child: IgnorePointer(
            child: Container(
              height: 12,
              width: 12,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Theme.of(context).appBarTheme.backgroundColor,
              ),
              child: GetBuilder(
                init: RemoteController.to,
                builder: (controller) => Icon(
                  Icons.circle,
                  size: 10,
                  color: controller.isOnline
                      ? AppTheme.connectableColor
                      : Colors.grey,
                ),
              ),
            ),
          ),
        )
      ],
    );
  }
}

import 'package:flutter/material.dart';
import 'package:status_mate/core/utils/permission_utils.dart';

class PermissionDialog extends StatelessWidget {
  const PermissionDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Permission Required'),
      content: const Text(
        'Storage permission is required to access WhatsApp statuses.\n\nPlease grant the permission in app settings or use the file picker to select the WhatsApp status folder.',
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('CANCEL'),
        ),
        TextButton(
          onPressed: () {
            Navigator.of(context).pop(true);
            PermissionUtils.openAppSettingsPage();
          },
          child: const Text('OPEN SETTINGS'),
        ),
      ],
    );
  }

  static Future<bool> show(BuildContext context) async {
    return await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) => const PermissionDialog(),
    ) ?? false;
  }
}

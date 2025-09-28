import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ConfirmSaveDialog extends StatelessWidget {
  const ConfirmSaveDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Unsaved Changes'),
      content: const Text(
        'You have unsaved changes. Save before closing?',
      ),
      actions: [
        TextButton(
          onPressed: () => Get.back(result: false),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () {
            Get.back(result: true);
          },
          child: const Text('Save & Close'),
        ),
        TextButton(
          onPressed: () => Get.back(result: true),
          child: const Text('Discard'),
        ),
      ],
    );
  }
}

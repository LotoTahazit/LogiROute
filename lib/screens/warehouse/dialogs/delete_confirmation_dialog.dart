import 'package:flutter/material.dart';

/// Универсальный диалог подтверждения удаления
///
/// Параметры:
/// - [title] - заголовок диалога
/// - [content] - текст подтверждения
/// - [onConfirm] - callback при подтверждении удаления
class DeleteConfirmationDialog extends StatelessWidget {
  final String title;
  final String content;
  final Future<void> Function() onConfirm;

  const DeleteConfirmationDialog({
    super.key,
    required this.title,
    required this.content,
    required this.onConfirm,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(title),
      content: Text(content),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('ביטול'),
        ),
        ElevatedButton(
          onPressed: () async {
            try {
              await onConfirm();

              if (context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('נמחק בהצלחה!'),
                    backgroundColor: Colors.green,
                  ),
                );
              }
            } catch (e) {
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('שגיאה: $e'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red,
          ),
          child: const Text('מחק'),
        ),
      ],
    );
  }

  /// Показать диалог удаления
  static Future<void> show({
    required BuildContext context,
    required String title,
    required String content,
    required Future<void> Function() onConfirm,
  }) {
    return showDialog(
      context: context,
      builder: (context) => DeleteConfirmationDialog(
        title: title,
        content: content,
        onConfirm: onConfirm,
      ),
    );
  }
}

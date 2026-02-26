import 'package:flutter/material.dart';

/// Хелпер для стандартных диалогов
class DialogHelper {
  /// Показать диалог подтверждения
  static Future<bool> showConfirmation({
    required BuildContext context,
    required String title,
    required String content,
    String confirmText = 'אישור',
    String cancelText = 'ביטול',
    Color? confirmColor,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(content),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(cancelText),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: confirmColor != null
                ? ElevatedButton.styleFrom(backgroundColor: confirmColor)
                : null,
            child: Text(confirmText),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  /// Показать диалог удаления (красная кнопка)
  static Future<bool> showDeleteConfirmation({
    required BuildContext context,
    required String title,
    required String content,
    String confirmText = 'מחק',
    String cancelText = 'ביטול',
  }) async {
    return showConfirmation(
      context: context,
      title: title,
      content: content,
      confirmText: confirmText,
      cancelText: cancelText,
      confirmColor: Colors.red,
    );
  }

  /// Показать информационный диалог
  static Future<void> showInfo({
    required BuildContext context,
    required String title,
    required String content,
    String buttonText = 'הבנתי',
  }) async {
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(content),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: Text(buttonText),
          ),
        ],
      ),
    );
  }

  /// Показать диалог с текстовым полем
  static Future<String?> showTextInput({
    required BuildContext context,
    required String title,
    String? hint,
    String? initialValue,
    String confirmText = 'אישור',
    String cancelText = 'ביטול',
    int maxLines = 1,
    bool required = false,
  }) async {
    final controller = TextEditingController(text: initialValue);
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(
            hintText: hint,
            border: const OutlineInputBorder(),
          ),
          maxLines: maxLines,
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(cancelText),
          ),
          ElevatedButton(
            onPressed: () {
              final text = controller.text.trim();
              if (required && text.isEmpty) {
                return;
              }
              Navigator.pop(context, text);
            },
            child: Text(confirmText),
          ),
        ],
      ),
    );
    controller.dispose();
    return result;
  }
}

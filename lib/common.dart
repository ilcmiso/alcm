// common.dart

import 'package:intl/intl.dart';
import 'package:logger/logger.dart';
import 'package:flutter/material.dart'; // Flutter UI用

final Logger logger = Logger();

/// デバッグログ出力用関数
void dprint(String message) {
  final String timestamp =
      DateFormat('yyyy/MM/dd HH:mm:ss').format(DateTime.now());
  logger.i('DBG:$timestamp - $message');
}

/// メッセージ表示用のダイアログ
void cmnDialog(BuildContext context, String message) {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: const Text("通知"),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(); // ダイアログを閉じる
            },
            child: const Text("OK"),
          ),
        ],
      );
    },
  );
}

/// トースト風通知（SnackBar）
void cmnSnackBar(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(message),
      duration: const Duration(seconds: 1),
    ),
  );
}

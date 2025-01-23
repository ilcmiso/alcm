import 'package:flutter/material.dart';
import 'ui_fplan.dart'; // UI部分を別ファイルに分割

void main() {
  // アプリを起動するエントリーポイント
  runApp(const MaterialApp(
    home: PropertyInputForm(), // UIを表示
  ));
}

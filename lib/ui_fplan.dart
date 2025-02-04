// ignore_for_file: use_super_parameters, avoid_print

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:yaml/yaml.dart';
import 'package:alcm/common.dart';
import 'package:alcm/sqlcmn.dart';

class PropertyInputForm extends StatefulWidget {
  const PropertyInputForm({Key? key}) : super(key: key);

  @override
  State<PropertyInputForm> createState() => _PropertyInputFormState();
}

class _PropertyInputFormState extends State<PropertyInputForm>
    with SingleTickerProviderStateMixin {
  TabController? _tabController; // nullable に変更
  Map<String, dynamic>? formConfig; // null許容型

  // 追加: 各入力フィールドの値を管理するMap
  final Map<String, String> _formData = {};
  // 追加: 各入力フィールド用のTextEditingControllerを管理するMap
  final Map<String, TextEditingController> _controllers = {};

  @override
  void initState() {
    super.initState();
    loadYamlConfig(); // YAMLの読み込みを開始
  }

  @override
  void dispose() {
    // TabControllerが存在していれば破棄
    _tabController?.dispose();
    // 追加: 全てのコントローラーを破棄
    for (var controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> loadYamlConfig() async {
    try {
      final yamlString = await rootBundle.loadString('assets/menu.yaml');
      final yamlMap = loadYaml(yamlString);
      setState(() {
        formConfig =
            Map<String, dynamic>.from(json.decode(json.encode(yamlMap)));
        // 既存のTabControllerを破棄してから新しく作成
        _tabController?.dispose();
        _tabController = TabController(
          length: formConfig!['tabs'].length,
          vsync: this,
        );
      });
    } catch (e, stackTrace) {
      dprint("Error loading YAML: $e");
      dprint("Stack Trace: $stackTrace");
    }
  }

  @override
  Widget build(BuildContext context) {
    if (formConfig == null) {
      // ローディング中の画面
      return Scaffold(
        appBar: AppBar(title: const Text("Loading...")),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("ALCM 資金計画 各種入力"),
      ),
      body: TabBarView(
        controller: _tabController,
        children: formConfig!['tabs']
            .map<Widget>(
                (tab) => buildFormFields(tab['fields'], tabKey: tab['title']))
            .toList(),
      ),
      bottomNavigationBar: TabBar(
        controller: _tabController,
        isScrollable: true,
        tabs: formConfig!['tabs']
            .map<Widget>((tab) => Tab(text: tab['title']))
            .toList(),
      ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min, // ボタンを下部にまとめる
        children: [
          FloatingActionButton(
            onPressed: () async {
              dprint("データ保存ボタンが押されました");
              // データ保存処理をここに記述
              final task = {
                'title': '入力フォームデータ',
                'description': json.encode(_formData),
              };
              final db = SQLiteCommon();
              await db.insertTask(task);
              cmnSnackBar(context, "保存が完了しました");
            },
            heroTag: "save", // ユニークなタグを設定
            tooltip: "データ保存",
            child: const Icon(Icons.save),
          ),
          const SizedBox(height: 10), // ボタン間のスペース
          FloatingActionButton(
            onPressed: () {
              dprint("他の操作ボタンが押されました");
              // 他の操作をここに記述
              cmnSnackBar(context, "保存が完了しました2");
            },
            heroTag: "other", // ユニークなタグを設定
            tooltip: "他の操作",
            child: const Icon(Icons.print),
          ),
          const SizedBox(height: 10), // ボタン間のスペース
          FloatingActionButton(
            onPressed: () {
              dprint("他の操作ボタンが押されました");
              // 他の操作をここに記述
              cmnSnackBar(context, "保存が完了しました3");
            },
            heroTag: "other", // ユニークなタグを設定
            tooltip: "他の操作",
            child: const Icon(Icons.cloud_upload),
          ),
        ],
      ),
    );
  }

  // 追加: tabKeyを引数に追加して、タブごとにキーが重複しないようにする
  Widget buildFormFields(List<dynamic> fields, {required String tabKey}) {
    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: fields.map<Widget>((field) {
        switch (field['type']) {
          case 'text':
            {
              final key = '${tabKey}_${field['label']}';
              if (!_controllers.containsKey(key)) {
                _controllers[key] =
                    TextEditingController(text: field['default'] ?? '');
                _formData[key] = field['default'] ?? '';
              }
              return TextField(
                controller: _controllers[key],
                decoration: InputDecoration(
                  labelText: field['label'],
                  hintText: field['default'] ?? '',
                ),
                onChanged: (value) {
                  _formData[key] = value;
                },
              );
            }
          case 'number':
            {
              final key = '${tabKey}_${field['label']}';
              if (!_controllers.containsKey(key)) {
                _controllers[key] =
                    TextEditingController(text: field['placeholder'] ?? '');
                _formData[key] = field['placeholder'] ?? '';
              }
              return TextField(
                controller: _controllers[key],
                decoration: InputDecoration(
                  labelText: field['label'],
                  hintText: field['placeholder'] ?? '',
                ),
                keyboardType: TextInputType.number,
                onChanged: (value) {
                  _formData[key] = value;
                },
              );
            }
          case 'select':
            {
              final key = '${tabKey}_${field['label']}';
              _formData.putIfAbsent(key, () => field['default'] ?? '');
              return DropdownButtonFormField<String>(
                decoration: InputDecoration(labelText: field['label']),
                value: field['default'],
                items: (field['options'] as List<dynamic>)
                    .map<DropdownMenuItem<String>>((option) {
                  return DropdownMenuItem(
                    value: option,
                    child: Text(option),
                  );
                }).toList(),
                onChanged: (value) {
                  _formData[key] = value ?? '';
                  setState(() {});
                },
              );
            }
          default:
            return Container();
        }
      }).toList(),
    );
  }
}

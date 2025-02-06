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

  // 追加: SQLiteCommonのインスタンス作成
  final SQLiteCommon _db = SQLiteCommon();

  // 各入力フィールドの値を管理するMap
  final Map<String, String> _formData = {};
  // 各入力フィールド用のTextEditingControllerを管理するMap
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

  // YAMLファイルから画面構成をロード
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
      // DBからデータをロード
      await _loadDataFromDB();
    } catch (e, stackTrace) {
      dprint("Error loading YAML: $e");
      dprint("Stack Trace: $stackTrace");
    }
  }

  // DBからデータを読み込み、各フィールドにセット
  Future<void> _loadDataFromDB() async {
    if (formConfig == null) return;

    for (var tab in formConfig!['tabs']) {
      String pageName = tab['title'];
      List<Map<String, dynamic>> records = await _db.getFormEntries(pageName);

      for (var record in records) {
        String key = '${record['page_name']}_${record['field_name']}';
        _formData[key] = record['field_value'];
        if (_controllers.containsKey(key)) {
          _controllers[key]!.text = record['field_value'];
        }
      }
    }

    setState(() {}); // UI更新
  }

  // データをDBに保存
  Future<void> _saveDataToDB() async {
    if (formConfig == null) return;

    for (var tab in formConfig!['tabs']) {
      String pageName = tab['title'];

      for (var field in tab['fields']) {
        String key = '${pageName}_${field['label']}';
        String value = _formData[key] ?? '';

        // UPSERTを実行（データがなければINSERT、あればUPDATE）
        await _db.upsertFormEntry(pageName, field['label'], value);
      }
    }

    cmnSnackBar(context, "保存が完了しました");
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
      floatingActionButton: FloatingActionButton(
        onPressed: () => _saveDataToDB(),
        tooltip: "データ保存",
        child: const Icon(Icons.save),
      ),
    );
  }

  Widget buildFormFields(List<dynamic> fields, {required String tabKey}) {
    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: fields.map<Widget>((field) {
        final key = '${tabKey}_${field['label']}';
        if (!_controllers.containsKey(key)) {
          _controllers[key] = TextEditingController(text: '');
          _formData[key] = '';
        }
        return TextField(
          controller: _controllers[key],
          decoration: InputDecoration(labelText: field['label']),
          keyboardType: field['type'] == 'number'
              ? TextInputType.number
              : TextInputType.text,
          onChanged: (value) {
            _formData[key] = value;
          },
        );
      }).toList(),
    );
  }
}

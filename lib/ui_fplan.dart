// ignore_for_file: use_super_parameters, avoid_print

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:convert';
import 'package:yaml/yaml.dart';

class PropertyInputForm extends StatefulWidget {
  const PropertyInputForm({Key? key}) : super(key: key);

  @override
  State<PropertyInputForm> createState() => _PropertyInputFormState();
}

class _PropertyInputFormState extends State<PropertyInputForm>
    with SingleTickerProviderStateMixin {
  TabController? _tabController; // nullable に変更
  Map<String, dynamic>? formConfig; // null許容型

  @override
  void initState() {
    super.initState();
    loadYamlConfig(); // YAMLの読み込みを開始
  }

  @override
  void dispose() {
    // TabControllerが存在していれば破棄
    _tabController?.dispose();
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
      print("Error loading YAML: $e");
      print("Stack Trace: $stackTrace");
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
            .map<Widget>((tab) => buildFormFields(tab['fields']))
            .toList(),
      ),
      bottomNavigationBar: TabBar(
        controller: _tabController,
        isScrollable: true,
        tabs: formConfig!['tabs']
            .map<Widget>((tab) => Tab(text: tab['title']))
            .toList(),
      ),
    );
  }

  Widget buildFormFields(List<dynamic> fields) {
    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: fields.map<Widget>((field) {
        switch (field['type']) {
          case 'text':
            return TextField(
              decoration: InputDecoration(
                labelText: field['label'],
                hintText: field['default'] ?? '',
              ),
            );
          case 'number':
            return TextField(
              decoration: InputDecoration(
                labelText: field['label'],
                hintText: field['placeholder'] ?? '',
              ),
              keyboardType: TextInputType.number,
            );
          case 'select':
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
              onChanged: (value) {},
            );
          default:
            return Container();
        }
      }).toList(),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:alcm/sqlcmn.dart';
import 'package:alcm/common.dart';
import 'ui_chart.dart'; // 償還表画面用のimport追加

class PropertyInputForm extends StatefulWidget {
  const PropertyInputForm({Key? key}) : super(key: key);

  @override
  State<PropertyInputForm> createState() => _PropertyInputFormState();
}

class _PropertyInputFormState extends State<PropertyInputForm>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final SQLiteCommon _db = SQLiteCommon();

  // 各フィールドの値管理用
  final Map<String, String> _formData = {};
  // 各フィールド用のTextEditingController管理用
  final Map<String, TextEditingController> _controllers = {};

  // YAMLの内容を元にした定数設定（直接ウィジェット実装用）
  final List<Map<String, dynamic>> tabsConfig = [
    {
      "title": "物件情報",
      "fields": [
        {"label": "借入金額(単位:円)", "type": "number", "default": "10,000,000"},
        {
          "label": "借入年数(単位:年)",
          "type": "number",
          "default": "35",
          "min": 1,
          "max": 50
        },
        {
          "label": "返済方法",
          "type": "select",
          "options": ["元利均等", "元金均等"],
          "default": "元利均等"
        },
        {"label": "物件名称", "type": "text", "placeholder": "◯◯マンション"},
        {
          "label": "金利(%)",
          "type": "number",
          "decimal_places": 3,
          "min": 0,
          "max": 100,
          "placeholder": "例: 2.345",
          "default": "2.345"
        }
      ]
    },
    {
      "title": "契約者情報",
      "fields": [
        {"label": "借入人名義", "type": "text", "default": ""},
        {"label": "連帯人名義", "type": "text", "default": ""}
      ]
    },
    {
      "title": "金融情報",
      "fields": [
        {
          "label": "金融機関名",
          "type": "select",
          "options": ["三菱UFJ銀行", "三井住友銀行", "りそな銀行"],
          "default": "りそな銀行"
        },
        {
          "label": "ローン名称",
          "type": "select",
          "options": ["固定", "変動"],
          "default": "変動"
        },
        {"label": "元金(単位:万円)", "type": "number", "default": "1,000"}
      ]
    },
    {
      "title": "諸費用",
      "fields": [
        {"label": "融資手数料", "type": "number", "default": ""},
        {"label": "保証料", "type": "number", "default": ""},
        {"label": "金消印紙代1", "type": "number", "default": ""},
        {"label": "金消印紙代2", "type": "number", "default": ""}
      ]
    },
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: tabsConfig.length, vsync: this);

    // 各タブ・フィールドの初期値をコントローラーにセット
    for (var tab in tabsConfig) {
      String pageTitle = tab["title"];
      for (var field in tab["fields"]) {
        String key = '${pageTitle}_${field["label"]}';
        String defaultValue = field["default"]?.toString() ?? '';
        _controllers[key] = TextEditingController(text: defaultValue);
        _formData[key] = defaultValue;
      }
    }

    // DBからデータロード（あれば上書き）
    _loadDataFromDB();
  }

  @override
  void dispose() {
    _tabController.dispose();
    for (var ctrl in _controllers.values) {
      ctrl.dispose();
    }
    super.dispose();
  }

  /// SQLiteから各フィールドの保存データを読み込む
  Future<void> _loadDataFromDB() async {
    for (var tab in tabsConfig) {
      String pageTitle = tab["title"];
      List<Map<String, dynamic>> records = await _db.getFormEntries(pageTitle);
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

  /// 各フィールドのデータをSQLiteに保存する
  Future<void> _saveDataToDB() async {
    for (var tab in tabsConfig) {
      String pageTitle = tab["title"];
      for (var field in tab["fields"]) {
        String key = '${pageTitle}_${field["label"]}';
        String value = _formData[key] ?? '';
        await _db.upsertFormEntry(pageTitle, field["label"], value);
      }
    }
    cmnSnackBar(context, "保存が完了しました");
  }

  /// SQLiteの保存データを削除する
  Future<void> _deleteDataFromDB() async {
    // 各タブごとに保存されたデータを削除
    for (var tab in tabsConfig) {
      String pageTitle = tab["title"];
      await _db.deleteFormEntries(pageTitle);
    }
    // ローカルのフォームデータもクリア
    _formData.clear();
    for (var controller in _controllers.values) {
      controller.clear();
    }
    setState(() {});
    cmnSnackBar(context, "保存データを削除しました");
  }

  /// 償還表画面へ遷移する
  void _navigateToChart() {
    // 物件情報タブから必要な値を取得
    String principalStr = _formData["物件情報_借入金額(単位:円)"] ?? "0";
    String yearsStr = _formData["物件情報_借入年数(単位:年)"] ?? "0";
    String repaymentMethod = _formData["物件情報_返済方法"] ?? "元利均等";
    String interestStr = _formData["物件情報_金利(%)"] ?? "0";

    // カンマを除去して数値変換
    principalStr = principalStr.replaceAll(",", "");
    yearsStr = yearsStr.replaceAll(",", "");
    interestStr = interestStr.replaceAll(",", "");

    double principal = double.tryParse(principalStr) ?? 0;
    int years = int.tryParse(yearsStr) ?? 0;
    double interestRate = double.tryParse(interestStr) ?? 0;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChartScreen(
          principal: principal,
          years: years,
          repaymentMethod: repaymentMethod,
          annualInterestRate: interestRate,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("ALCM 資金計画 各種入力"),
      ),
      body: TabBarView(
        controller: _tabController,
        children: tabsConfig.map((tab) {
          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: buildFields(tab),
          );
        }).toList(),
      ),
      bottomNavigationBar: TabBar(
        controller: _tabController,
        isScrollable: true,
        tabs: tabsConfig
            .map((tab) => Tab(text: tab["title"].toString()))
            .toList(),
      ),
      // 保存ボタン、償還表ボタン、削除ボタンを縦に配置
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FloatingActionButton(
            heroTag: "saveButton",
            onPressed: _saveDataToDB,
            tooltip: "データ保存",
            child: const Icon(Icons.save),
          ),
          const SizedBox(height: 16),
          FloatingActionButton(
            heroTag: "chartButton",
            onPressed: _navigateToChart,
            tooltip: "償還表",
            child: const Icon(Icons.addchart),
          ),
          const SizedBox(height: 16),
          FloatingActionButton(
            heroTag: "deleteButton",
            onPressed: _deleteDataFromDB,
            tooltip: "保存データ削除",
            backgroundColor: Colors.red,
            child: const Icon(Icons.delete),
          ),
        ],
      ),
    );
  }

  /// 指定タブの各フィールドを構築する
  Widget buildFields(Map<String, dynamic> tab) {
    String pageTitle = tab["title"];
    List<dynamic> fields = tab["fields"];
    return ListView.builder(
      itemCount: fields.length,
      itemBuilder: (context, index) {
        var field = fields[index];
        String key = '${pageTitle}_${field["label"]}';
        switch (field["type"]) {
          case "text":
            return Padding(
              padding: const EdgeInsets.only(bottom: 16.0),
              child: TextField(
                controller: _controllers[key],
                decoration: InputDecoration(
                  labelText: field["label"].toString(),
                  hintText: field["placeholder"]?.toString(),
                ),
                onChanged: (value) {
                  _formData[key] = value;
                },
              ),
            );
          case "number":
            int? decimalPlaces = field["decimal_places"] != null
                ? int.tryParse(field["decimal_places"].toString())
                : null;
            // 組み合わせる inputFormatters をリストで生成
            List<TextInputFormatter> inputFormatters = [];
            // もし min, max が設定されてたら、RangeInputFormatter（double対応）を追加
            if (field["min"] != null && field["max"] != null) {
              inputFormatters.add(RangeInputFormatter(
                min: double.parse(field["min"].toString()),
                max: double.parse(field["max"].toString()),
              ));
            }
            // 小数点指定があれば DecimalNumberFormatter、なければ整数用の ThousandsFormatter を追加
            if (decimalPlaces != null && decimalPlaces > 0) {
              inputFormatters
                  .add(DecimalNumberFormatter(decimalPlaces: decimalPlaces));
            } else {
              inputFormatters.add(ThousandsFormatter());
            }
            return Padding(
              padding: const EdgeInsets.only(bottom: 16.0),
              child: TextField(
                controller: _controllers[key],
                decoration: InputDecoration(
                  labelText: field["label"].toString(),
                  hintText: field["placeholder"]?.toString(),
                ),
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: inputFormatters,
                onChanged: (value) {
                  _formData[key] = value;
                },
              ),
            );
          case "select":
            List<dynamic> options = field["options"] ?? [];
            return Padding(
              padding: const EdgeInsets.only(bottom: 16.0),
              child: DropdownButtonFormField<String>(
                decoration: InputDecoration(
                  labelText: field["label"].toString(),
                ),
                value: ((_formData[key] ?? '').isEmpty) ? null : _formData[key],
                items: options.map<DropdownMenuItem<String>>((option) {
                  return DropdownMenuItem<String>(
                    value: option.toString(),
                    child: Text(option.toString()),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _formData[key] = value ?? '';
                    _controllers[key]!.text = value ?? '';
                  });
                },
              ),
            );
          default:
            return const SizedBox.shrink();
        }
      },
    );
  }
}

/// 数値（整数）入力時に3桁カンマ表示するためのTextInputFormatter
class ThousandsFormatter extends TextInputFormatter {
  final NumberFormat formatter = NumberFormat.decimalPattern();

  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    String digitsOnly = newValue.text.replaceAll(RegExp(r','), '');
    if (digitsOnly.isEmpty) return newValue.copyWith(text: '');
    int? number = int.tryParse(digitsOnly);
    if (number == null) return oldValue;
    String formatted = formatter.format(number);
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

/// 小数対応の数値入力フォーマッター（グルーピング無効、en_USロケール）
class DecimalNumberFormatter extends TextInputFormatter {
  final int decimalPlaces;
  final NumberFormat formatter;

  DecimalNumberFormatter({required this.decimalPlaces})
      : formatter = NumberFormat.decimalPattern('en_US')..turnOffGrouping();

  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    // 入力値からカンマを除去
    String newText = newValue.text.replaceAll(',', '');
    // 数字と小数点のみ許可
    if (!RegExp(r'^\d*\.?\d*$').hasMatch(newText)) {
      return oldValue;
    }
    List<String> parts = newText.split('.');
    String integerPart = parts[0];
    String decimalPart = parts.length > 1 ? parts[1] : '';
    if (decimalPart.length > decimalPlaces) {
      decimalPart = decimalPart.substring(0, decimalPlaces);
    }
    String formattedInteger = '';
    if (integerPart.isNotEmpty) {
      try {
        formattedInteger = formatter.format(int.parse(integerPart));
      } catch (e) {
        formattedInteger = integerPart;
      }
    }
    String formatted = formattedInteger;
    if (newText.contains('.') && decimalPlaces > 0) {
      formatted = '$formatted.$decimalPart';
    }
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

/// 指定した範囲内の数値のみ許可する TextInputFormatter（double対応）
class RangeInputFormatter extends TextInputFormatter {
  final double min;
  final double max;

  RangeInputFormatter({required this.min, required this.max});

  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    // 途中入力を許容するため、空文字はそのまま返す
    if (newValue.text.isEmpty) return newValue;
    // カンマ除去後、doubleに変換
    String newText = newValue.text.replaceAll(RegExp(r','), '');
    double? value = double.tryParse(newText);
    if (value == null) return oldValue;
    if (value < min || value > max) {
      return oldValue;
    }
    return newValue;
  }
}

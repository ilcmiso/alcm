import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // 入力制限に必要

// 入力フォームUIを定義するStatefulWidget
class PropertyInputForm extends StatefulWidget {
  const PropertyInputForm({Key? key}) : super(key: key);

  @override
  State<PropertyInputForm> createState() => _PropertyInputFormState();
}

class _PropertyInputFormState extends State<PropertyInputForm> {
  // 各入力フィールドの値を管理するためのコントローラー
  final TextEditingController propertyNameController = TextEditingController();
  final TextEditingController roomNumberController = TextEditingController();
  final TextEditingController layoutController = TextEditingController();
  final TextEditingController contractAmountController =
      TextEditingController();
  final TextEditingController downPaymentController = TextEditingController();
  final TextEditingController extraCostController = TextEditingController();
  final TextEditingController borrowerNameController = TextEditingController();

  // 確定ボタンが押されたときの処理
  void _submitForm() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        // 確認ダイアログを表示
        return AlertDialog(
          title: const Text("確定しますか？"),
          content: const Text("入力内容を確定してもよろしいですか？"),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // ダイアログを閉じる
              },
              child: const Text("No"),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // ダイアログを閉じる
                _processInputData(); // 入力内容を処理
              },
              child: const Text("Yes"),
            ),
          ],
        );
      },
    );
  }

  // 入力データを処理する関数（デバッグ用）
  void _processInputData() {
    final propertyName = propertyNameController.text;
    final roomNumber = roomNumberController.text;
    final layout = layoutController.text;
    final contractAmount = contractAmountController.text;
    final downPayment = downPaymentController.text;
    final extraCost = extraCostController.text;
    final borrowerName = borrowerNameController.text;

    // デバッグ用に入力内容をコンソールに出力
    debugPrint("物件名称: $propertyName");
    debugPrint("号室: $roomNumber");
    debugPrint("間取り: $layout");
    debugPrint("契約額: $contractAmount");
    debugPrint("頭金額: $downPayment");
    debugPrint("諸費用: $extraCost");
    debugPrint("借入名義: $borrowerName");
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("資金計画入力"), // アプリのタイトル
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildTextField("物件名称", propertyNameController), // テキスト入力
              _buildTextField("号室", roomNumberController), // テキスト入力
              _buildTextField("間取り", layoutController), // テキスト入力
              _buildNumberField("契約額", contractAmountController), // 数値のみ入力
              _buildNumberField("頭金額", downPaymentController), // 数値のみ入力
              _buildTextField("諸費用", extraCostController), // テキスト入力
              _buildTextField("借入名義", borrowerNameController), // テキスト入力
              const SizedBox(height: 20), // 確定ボタン前の余白
              Center(
                child: ElevatedButton(
                  onPressed: _submitForm, // 確定ボタンの処理
                  child: const Text("確定"),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // テキスト入力フィールドを作成
  Widget _buildTextField(String label, TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: TextField(
        controller: controller, // 入力値を管理
        decoration: InputDecoration(
          labelText: label, // フィールドのラベル
          border: const OutlineInputBorder(),
        ),
      ),
    );
  }

  // 数字入力フィールドを作成
  Widget _buildNumberField(String label, TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: TextField(
        controller: controller, // 入力値を管理
        decoration: InputDecoration(
          labelText: label, // フィールドのラベル
          border: const OutlineInputBorder(),
        ),
        keyboardType: TextInputType.number, // 数字キーボードを表示
        inputFormatters: [
          FilteringTextInputFormatter.digitsOnly, // 数字のみ入力可能に制限
        ],
      ),
    );
  }
}

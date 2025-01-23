import 'package:flutter/material.dart';

void main() {
  runApp(const MaterialApp(
    home: PropertyInputForm(),
  ));
}

class PropertyInputForm extends StatefulWidget {
  const PropertyInputForm({Key? key}) : super(key: key);

  @override
  State<PropertyInputForm> createState() => _PropertyInputFormState();
}

class _PropertyInputFormState extends State<PropertyInputForm> {
  // テキストコントローラー
  final TextEditingController propertyNameController = TextEditingController();
  final TextEditingController roomNumberController = TextEditingController();
  final TextEditingController layoutController = TextEditingController();
  final TextEditingController contractAmountController =
      TextEditingController();
  final TextEditingController downPaymentController = TextEditingController();
  final TextEditingController extraCostController = TextEditingController();
  final TextEditingController borrowerNameController = TextEditingController();

  // フォーム送信時の処理
  void _submitForm() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
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
                // ここで入力内容を処理
                _processInputData();
              },
              child: const Text("Yes"),
            ),
          ],
        );
      },
    );
  }

  // 入力データの処理
  void _processInputData() {
    final propertyName = propertyNameController.text;
    final roomNumber = roomNumberController.text;
    final layout = layoutController.text;
    final contractAmount = contractAmountController.text;
    final downPayment = downPaymentController.text;
    final extraCost = extraCostController.text;
    final borrowerName = borrowerNameController.text;

    // デバッグ用に入力内容をコンソールに表示
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
        title: const Text("資金計画入力"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildTextField("物件名称", propertyNameController),
              _buildTextField("号室", roomNumberController),
              _buildTextField("間取り", layoutController),
              _buildNumberField("契約額", contractAmountController),
              _buildNumberField("頭金額", downPaymentController),
              _buildTextField("諸費用", extraCostController),
              _buildTextField("借入名義", borrowerNameController),
              const SizedBox(height: 20),
              Center(
                child: ElevatedButton(
                  onPressed: _submitForm,
                  child: const Text("確定"),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // テキストフィールドウィジェットを作成
  Widget _buildTextField(String label, TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
      ),
    );
  }

  // 数値入力フィールドウィジェットを作成
  Widget _buildNumberField(String label, TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: TextField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
        keyboardType: TextInputType.number,
        inputFormatters: [
          // 数値入力のみを許可（必要なら追加のパッケージが必要）
        ],
      ),
    );
  }
}

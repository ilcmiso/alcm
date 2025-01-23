// ui_fplan.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class PropertyInputForm extends StatefulWidget {
  const PropertyInputForm({Key? key}) : super(key: key);

  @override
  State<PropertyInputForm> createState() => _PropertyInputFormState();
}

class _PropertyInputFormState extends State<PropertyInputForm>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("資金計画入力"),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildPropertyTab(),
          _buildContractorTab(),
          _buildFinancialTab(),
          _buildCostTab(),
          _buildDataCreationTab(),
        ],
      ),
      bottomNavigationBar: TabBar(
        controller: _tabController,
        isScrollable: true,
        tabs: const [
          Tab(text: "物件情報"),
          Tab(text: "契約者情報"),
          Tab(text: "金融機関"),
          Tab(text: "諸費用"),
          Tab(text: "データ作成"),
        ],
      ),
    );
  }

  Widget _buildPropertyTab() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildTextField("物件名称"),
          _buildTextField("号室"),
          _buildTextField("間取り"),
        ],
      ),
    );
  }

  Widget _buildContractorTab() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildTextField("契約者名"),
          _buildTextField("連絡先"),
        ],
      ),
    );
  }

  Widget _buildFinancialTab() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildTextField("金融機関名称"),
          _buildNumberField("融資額"),
        ],
      ),
    );
  }

  Widget _buildCostTab() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildNumberField("諸費用合計"),
        ],
      ),
    );
  }

  Widget _buildDataCreationTab() {
    return Center(
      child: ElevatedButton(
        onPressed: () {
          // データ作成処理を実装
        },
        child: const Text("データ作成"),
      ),
    );
  }

  Widget _buildTextField(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: TextField(
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
      ),
    );
  }

  Widget _buildNumberField(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: TextField(
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
        keyboardType: TextInputType.number,
        inputFormatters: [
          FilteringTextInputFormatter.digitsOnly,
        ],
      ),
    );
  }
}

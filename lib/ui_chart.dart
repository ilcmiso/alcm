import 'package:flutter/material.dart';
import 'dart:math';
import 'package:intl/intl.dart';

// 追加パッケージ
import 'package:excel/excel.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class ChartScreen extends StatelessWidget {
  final double principal;
  final int years;
  final String repaymentMethod;
  final double annualInterestRate;

  ChartScreen({
    required this.principal,
    required this.years,
    required this.repaymentMethod,
    required this.annualInterestRate,
  });

  // 各列の設定情報（ラベル、幅、AmortizationRowのフィールド名、テキスト配置）
  final List<Map<String, dynamic>> columnsConfig = const [
    {"label": "月数", "width": 30.0, "field": "month", "alignment": "right"},
    {"label": "返済額", "width": 50.0, "field": "payment", "alignment": "left"},
    {"label": "金利額", "width": 50.0, "field": "interest", "alignment": "right"},
    {
      "label": "元金額",
      "width": 50.0,
      "field": "principalPayment",
      "alignment": "right"
    },
    {
      "label": "金利累計",
      "width": 70.0,
      "field": "cumulativeInterest",
      "alignment": "right"
    },
    {
      "label": "返済残高",
      "width": 70.0,
      "field": "remainingBalance",
      "alignment": "right"
    },
  ];

  @override
  Widget build(BuildContext context) {
    // 償還表のスケジュール生成
    final List<AmortizationRow> schedule = _generateSchedule();
    // 整数表示用のフォーマッター
    final formatter = NumberFormat("#,##0");

    return Scaffold(
      appBar: AppBar(
        title: const Text("償還表"),
      ),
      body: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: SingleChildScrollView(
          child: DataTable(
            dataRowHeight: 30.0, // 行の高さを狭める
            headingRowHeight: 30.0, // ヘッダー行の高さを狭める
            columns: columnsConfig.map((col) {
              // alignmentパラメータからTextAlignを決定
              TextAlign textAlign;
              switch (col["alignment"]) {
                case "left":
                  textAlign = TextAlign.left;
                  break;
                case "center":
                  textAlign = TextAlign.center;
                  break;
                default:
                  textAlign = TextAlign.right;
              }
              return DataColumn(
                label: Container(
                  width: col["width"],
                  child: Text(
                    col["label"],
                    textAlign: textAlign,
                  ),
                ),
              );
            }).toList(),
            rows: schedule.map((row) {
              final rowData = row.toMap();
              return DataRow(
                cells: columnsConfig.map((col) {
                  final field = col["field"];
                  // 月数はそのまま、他は.floor()で整数に切り捨て
                  final dynamic rawValue = rowData[field];
                  final value =
                      (field == "month") ? rawValue : rawValue.floor();
                  // alignmentパラメータからTextAlignを決定
                  TextAlign textAlign;
                  switch (col["alignment"]) {
                    case "left":
                      textAlign = TextAlign.left;
                      break;
                    case "center":
                      textAlign = TextAlign.center;
                      break;
                    default:
                      textAlign = TextAlign.right;
                  }
                  return DataCell(
                    Container(
                      width: col["width"],
                      child: Text(
                        formatter.format(value),
                        textAlign: textAlign,
                      ),
                    ),
                  );
                }).toList(),
              );
            }).toList(),
          ),
        ),
      ),
      // FAB2個：Excel出力とPDF出力
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FloatingActionButton(
            heroTag: "excelExport",
            onPressed: () async {
              await _exportToExcel(context);
            },
            tooltip: "Excel出力",
            child: const Icon(Icons.table_chart),
          ),
          const SizedBox(height: 16),
          FloatingActionButton(
            heroTag: "pdfExport",
            onPressed: () async {
              await _exportToPDF(context);
            },
            tooltip: "PDF出力",
            child: const Icon(Icons.picture_as_pdf),
          ),
        ],
      ),
    );
  }

  /// 償還表のスケジュールを生成する
  List<AmortizationRow> _generateSchedule() {
    List<AmortizationRow> schedule = [];
    int totalMonths = years * 12;
    double monthlyRate = annualInterestRate / 100 / 12;
    double remainingBalance = principal;
    double cumulativeInterest = 0.0;

    if (repaymentMethod == "元利均等") {
      double monthlyPayment = principal *
          monthlyRate *
          pow(1 + monthlyRate, totalMonths) /
          (pow(1 + monthlyRate, totalMonths) - 1);

      for (int month = 1; month <= totalMonths; month++) {
        double interestAmount = remainingBalance * monthlyRate;
        double principalAmount = monthlyPayment - interestAmount;
        cumulativeInterest += interestAmount;
        remainingBalance -= principalAmount;
        if (month == totalMonths) {
          principalAmount += remainingBalance;
          monthlyPayment = principalAmount + interestAmount;
          remainingBalance = 0;
        }
        schedule.add(AmortizationRow(
          month: month,
          payment: monthlyPayment,
          interest: interestAmount,
          principalPayment: principalAmount,
          cumulativeInterest: cumulativeInterest,
          remainingBalance: remainingBalance,
        ));
      }
    } else if (repaymentMethod == "元金均等") {
      double monthlyPrincipal = principal / totalMonths;
      for (int month = 1; month <= totalMonths; month++) {
        double interestAmount = remainingBalance * monthlyRate;
        double monthlyPayment = monthlyPrincipal + interestAmount;
        cumulativeInterest += interestAmount;
        remainingBalance -= monthlyPrincipal;
        if (month == totalMonths) {
          monthlyPayment = monthlyPrincipal + interestAmount;
          remainingBalance = 0;
        }
        schedule.add(AmortizationRow(
          month: month,
          payment: monthlyPayment,
          interest: interestAmount,
          principalPayment: monthlyPrincipal,
          cumulativeInterest: cumulativeInterest,
          remainingBalance: remainingBalance,
        ));
      }
    }
    return schedule;
  }

  /// Excel出力処理（excelパッケージを利用）
  Future<void> _exportToExcel(BuildContext context) async {
    List<AmortizationRow> schedule = _generateSchedule();

    // Excelファイル作成
    var excel = Excel.createExcel();
    Sheet sheetObject = excel['Sheet1'];

    // ヘッダー行追加
    List<String> headers =
        columnsConfig.map((col) => col["label"].toString()).toList();
    sheetObject.appendRow(headers);

    // 各行追加（各セルは月数はそのまま、他は.floor()して整数値）
    for (var row in schedule) {
      Map<String, dynamic> rowData = row.toMap();
      List<dynamic> rowValues = [];
      for (var col in columnsConfig) {
        String field = col["field"];
        dynamic value = rowData[field];
        if (field != "month") {
          value = value.floor();
        }
        rowValues.add(value);
      }
      sheetObject.appendRow(rowValues);
    }

    // Excelファイルのバイト列取得
    var fileBytes = excel.encode();

    if (fileBytes != null) {
      // ここでは単純にSnackBarでバイト数を表示
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Excelファイル出力成功（バイト数: ${fileBytes.length}）")),
      );
      // 実際は、path_providerで保存場所を確保したり、shareプラグインで共有したりする
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Excelファイル出力失敗")),
      );
    }
  }

  /// PDF出力処理（pdf, printingパッケージを利用）
  Future<void> _exportToPDF(BuildContext context) async {
    List<AmortizationRow> schedule = _generateSchedule();

    final pdf = pw.Document();

    // ヘッダーとデータ行作成
    List<String> headers =
        columnsConfig.map((col) => col["label"].toString()).toList();
    List<List<String>> dataRows = [];
    for (var row in schedule) {
      Map<String, dynamic> rowData = row.toMap();
      List<String> rowValues = [];
      for (var col in columnsConfig) {
        String field = col["field"];
        dynamic value = rowData[field];
        if (field != "month") {
          value = value.floor();
        }
        rowValues.add(value.toString());
      }
      dataRows.add(rowValues);
    }

    // PDF用テーブル作成
    pdf.addPage(
      pw.Page(
        build: (pw.Context context) {
          return pw.Table.fromTextArray(
            data: <List<String>>[
              headers,
              ...dataRows,
            ],
            headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
            headerDecoration: const pw.BoxDecoration(color: PdfColors.grey300),
            cellHeight: 20,
            // 簡易的なセル配置（各列ごとの個別設定は、Table.fromTextArrayではインデックス指定で可能）
            cellAlignments: {
              0: pw.Alignment.centerRight,
              1: pw.Alignment.centerLeft,
              2: pw.Alignment.centerRight,
              3: pw.Alignment.centerRight,
              4: pw.Alignment.centerRight,
              5: pw.Alignment.centerRight,
            },
          );
        },
      ),
    );

    final pdfBytes = await pdf.save();
    // PrintingパッケージでPDF共有（端末の共有ダイアログが出る）
    await Printing.sharePdf(bytes: pdfBytes, filename: "amortization.pdf");
  }
}

/// 償還表の1行分のデータを保持するクラス
class AmortizationRow {
  final int month;
  final double payment;
  final double interest;
  final double principalPayment;
  final double cumulativeInterest;
  final double remainingBalance;

  AmortizationRow({
    required this.month,
    required this.payment,
    required this.interest,
    required this.principalPayment,
    required this.cumulativeInterest,
    required this.remainingBalance,
  });

  /// 各フィールドをMap形式で返す
  Map<String, dynamic> toMap() {
    return {
      "month": month,
      "payment": payment,
      "interest": interest,
      "principalPayment": principalPayment,
      "cumulativeInterest": cumulativeInterest,
      "remainingBalance": remainingBalance,
    };
  }
}

import 'package:flutter/material.dart';
import 'dart:math';
import 'package:intl/intl.dart';

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

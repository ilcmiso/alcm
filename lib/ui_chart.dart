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

  @override
  Widget build(BuildContext context) {
    // 償還表のスケジュールを生成
    final List<AmortizationRow> schedule = _generateSchedule();
    final formatter = NumberFormat("#,##0.00");

    return Scaffold(
      appBar: AppBar(
        title: const Text("償還表"),
      ),
      body: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: SingleChildScrollView(
          child: DataTable(
            columns: const [
              DataColumn(label: Text("月数")),
              DataColumn(label: Text("返済額")),
              DataColumn(label: Text("金利額")),
              DataColumn(label: Text("元金額")),
              DataColumn(label: Text("金利累計")),
              DataColumn(label: Text("返済残高")),
            ],
            rows: schedule.map((row) {
              return DataRow(
                cells: [
                  DataCell(Text(row.month.toString())),
                  DataCell(Text(formatter.format(row.payment))),
                  DataCell(Text(formatter.format(row.interest))),
                  DataCell(Text(formatter.format(row.principalPayment))),
                  DataCell(Text(formatter.format(row.cumulativeInterest))),
                  DataCell(Text(formatter.format(row.remainingBalance))),
                ],
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
      // 元利均等返済方式の計算
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
          // 最終月の調整
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
      // 元金均等返済方式の計算
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
}

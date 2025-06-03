import 'package:flutter/material.dart';

class SpendingStatus {
  final String status;
  final Color color;

  SpendingStatus({required this.status, required this.color});
}

SpendingStatus calculateSpendingStatus({
  required int monthlyGoal,
  required int todaySpending,
  DateTime? todayDate,
}) {
  todayDate ??= DateTime.now();
  final int dayPassed = todayDate.day;
  final double dailyGoal = monthlyGoal / 30;

  final double recommendedSpending = dailyGoal * dayPassed;

  if (todaySpending > recommendedSpending * 1.1) {
    return SpendingStatus(status: '과소비', color: Colors.red);
  } else if (todaySpending < recommendedSpending * 0.9) {
    return SpendingStatus(status: '절약', color: Colors.green);
  } else {
    return SpendingStatus(status: '평균', color: Colors.blue);
  }
}

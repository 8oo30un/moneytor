import 'package:flutter/material.dart';

class SpendingStatus {
  final String status;
  final Color color;

  SpendingStatus({required this.status, required this.color});
}

// monthlyGoal, todaySpending 외에 선택된 카드가 있을 때 그 카드의 값으로 계산할 수 있게 수정
SpendingStatus calculateSpendingStatus({
  required int? monthlyGoal,
  required int todaySpending,
  DateTime? todayDate,
}) {
  todayDate ??= DateTime.now();

  if (monthlyGoal == null || monthlyGoal == 0) {
    return SpendingStatus(
      status: '미설정',
      color: const Color.fromRGBO(247, 247, 249, 1), // 기본 회색
    );
  }

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

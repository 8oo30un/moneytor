import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../state/app_state.dart';
import '../model/register_card_model.dart';

class SpendingStatus {
  final String status;
  final Color color;
  final int spending;

  SpendingStatus({
    required this.status,
    required this.color,
    required this.spending,
  });
}

SpendingStatus calculateSpendingStatus(BuildContext context) {
  final appState = Provider.of<AppState>(context, listen: false);
  final int? goal = appState.selectedCard?.spendingGoal ?? appState.monthlyGoal;

  // selectedCard가 null일 때 registerCards 총합을 todaySpending에 할당
  final int todaySpending =
      appState.selectedCard != null
          ? appState.selectedCard!.totalAmount
          : appState.totalSpending;

  if (goal == null || goal == 0) {
    return SpendingStatus(
      status: '미설정',
      color: const Color.fromRGBO(247, 247, 249, 1), // 기본 회색
      spending: todaySpending,
    );
  }

  final DateTime todayDate = DateTime.now();
  final int dayPassed = todayDate.day;
  final double dailyGoal = goal / 30;
  final double recommendedSpending = dailyGoal * dayPassed;

  if (todaySpending > recommendedSpending * 1.1) {
    return SpendingStatus(
      status: '과소비',
      color: Color.fromRGBO(255, 187, 135, 1),
      spending: todaySpending,
    );
  } else if (todaySpending < recommendedSpending * 0.9) {
    return SpendingStatus(
      status: '절약',
      color: Color.fromRGBO(161, 227, 249, 1),
      spending: todaySpending,
    );
  } else {
    return SpendingStatus(
      status: '평균',
      color: Color.fromRGBO(152, 219, 204, 1),
      spending: todaySpending,
    );
  }
}

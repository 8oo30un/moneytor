import 'package:flutter/material.dart';
import '../model/register_card_model.dart';
import '../utils/spending_calculator.dart'; // 상태 계산 함수

class SpendingStatusDisplay extends StatelessWidget {
  final String userName;
  final int monthlyGoal;
  final int todaySpending;
  final int totalSpending;
  final RegisterCardModel? selectedCard;
  final List<RegisterCardModel> registerCards;

  const SpendingStatusDisplay({
    super.key,
    required this.userName,
    required this.monthlyGoal,
    required this.todaySpending,
    required this.registerCards,
    required this.totalSpending,
    this.selectedCard,
  });

  @override
  Widget build(BuildContext context) {
    final int currentDay = DateTime.now().day;
    final int daysInMonth =
        DateTime(DateTime.now().year, DateTime.now().month + 1, 0).day;

    final int baseSpending =
        selectedCard?.totalAmount ??
        registerCards.fold<int>(0, (sum, card) => sum + card.totalAmount);

    final int estimatedMonthlySpending =
        (baseSpending / currentDay * daysInMonth).round();

    final int? goal =
        selectedCard?.spendingGoal ?? (monthlyGoal == 0 ? null : monthlyGoal);
    final int? estimatedGoalSpending =
        goal != null ? (goal / daysInMonth * currentDay).round() : null;

    if (goal == null || goal == 0) {
      return const Padding(
        padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        child: Text(
          '지출 금액을 설정해주세요',
          style: TextStyle(
            fontSize: 18.0,
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
      );
    }

    final status = calculateSpendingStatus(context);

    print('[DEBUG] status: ${status.status}, color: ${status.color}');

    final isAverage = status.status == '평균';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      child: RichText(
        text: TextSpan(
          style: const TextStyle(fontSize: 20.0, color: Colors.black),
          children: [
            TextSpan(text: '$userName님,\n'),
            if (selectedCard != null) ...[
              TextSpan(
                text: selectedCard!.name,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              const TextSpan(text: ' 카테고리에서\n'),
            ] else
              ...[],
            if (isAverage) ...[
              const TextSpan(text: '권장지출만큼 '),
              TextSpan(
                text: '적절히',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: status.color,
                ),
              ),
              const TextSpan(text: ' 소비하고 있어요!'),
            ] else ...[
              const TextSpan(text: '권장 지출보다 '),
              TextSpan(
                text: status.status,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: status.color,
                ),
              ),
              const TextSpan(text: '하고 있어요!'),
            ],
          ],
        ),
      ),
    );
  }
}

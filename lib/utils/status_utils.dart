import 'package:flutter/material.dart';
import '../model/register_card_model.dart';
import 'spending_calculator.dart';

class StatusResult {
  final int goal;
  final int spending;
  final String status;
  final Color color;

  StatusResult({
    required this.goal,
    required this.spending,
    required this.status,
    required this.color,
  });
}

StatusResult calculateStatusFromCard({
  RegisterCardModel? selectedCard,
  int defaultGoal = 1000000,
  //TODO: 목데이터 수정
  int? defaultSpending,
  List<RegisterCardModel>? allCards,
}) {
  int goal;
  int spending;

  if (selectedCard != null &&
      selectedCard.spendingGoal != null &&
      selectedCard.spendingGoal! > 0) {
    goal = selectedCard.spendingGoal!;
    spending = selectedCard.totalAmount;
  } else {
    goal = defaultGoal;
    spending =
        defaultSpending ??
        (allCards != null
            ? RegisterCardModel.calculateTotalSpending(allCards)
            : 0);
  }

  final status = calculateSpendingStatus(
    monthlyGoal: goal,
    todaySpending: spending,
  );

  return StatusResult(
    goal: goal,
    spending: spending,
    status: status.status,
    color: status.color,
  );
}

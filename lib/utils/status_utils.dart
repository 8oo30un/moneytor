import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../model/register_card_model.dart';
import 'spending_calculator.dart';
import '../state/app_state.dart';

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

Future<StatusResult> calculateStatusFromCard(
  BuildContext context, {
  RegisterCardModel? selectedCard,
}) async {
  final appState = Provider.of<AppState>(context, listen: false);
  int goal;
  int spending;

  if (selectedCard != null &&
      selectedCard.spendingGoal != null &&
      selectedCard.spendingGoal! > 0) {
    goal = selectedCard.spendingGoal!;
    spending = selectedCard.totalAmount;
  } else {
    goal = appState.monthlyGoal;
    spending = appState.todaySpending;
  }

  final status = calculateSpendingStatus(context);

  return StatusResult(
    goal: goal,
    spending: spending,
    status: status.status,
    color: status.color,
  );
}

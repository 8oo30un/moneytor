import 'package:flutter/material.dart';
import '../model/register_card_model.dart';
import 'spending_calculator.dart';
import '../data/register_card_repository.dart';
import 'package:firebase_auth/firebase_auth.dart';

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

Future<StatusResult> calculateStatusFromCard({
  RegisterCardModel? selectedCard,
  int? defaultGoal,
  int? defaultSpending,
  List<RegisterCardModel>? allCards,
}) async {
  int goal;
  int spending;

  if (selectedCard != null &&
      selectedCard.spendingGoal != null &&
      selectedCard.spendingGoal! > 0) {
    goal = selectedCard.spendingGoal!;
    spending = selectedCard.totalAmount;
  } else {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    final repo = RegisterCardRepository(userId: userId!);
    final fetchedGoal = defaultGoal ?? await repo.getDefaultGoal();

    goal = fetchedGoal;
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

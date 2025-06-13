import 'package:moneytor/widgets/card_spending_summary.dart';
import 'package:flutter/material.dart';

class ListPage extends StatelessWidget {
  const ListPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: null,
      body: Column(
        children: [
          CardSpendingSummary(
            selectedCard: null,
            todaySpending: 0,
            monthlyGoal: 1000000,
            statusColor: const Color.fromRGBO(247, 247, 249, 1),
            userId: 'dummy_user',
            onGoalSaved: (updatedCard) {},
            registerCards: [],
          ),
          // ... other widgets go here
        ],
      ),
    );
  }
}

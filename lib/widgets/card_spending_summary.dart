import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../utils/progress_bar.dart';
import '../model/register_card_model.dart';
import '../data/register_card_repository.dart';
import '../utils/status_utils.dart';
import '../utils/spending_calculator.dart';

class CardSpendingSummary extends StatefulWidget {
  final RegisterCardModel? selectedCard;
  final int todaySpending;
  final int monthlyGoal;
  final Color statusColor;
  final String userId;
  final Function(RegisterCardModel updatedCard) onGoalSaved;
  final List<RegisterCardModel> registerCards;

  const CardSpendingSummary({
    super.key,
    required this.selectedCard,
    required this.todaySpending,
    required this.monthlyGoal,
    required this.statusColor,
    required this.userId,
    required this.onGoalSaved,
    required this.registerCards,
  });

  @override
  State<CardSpendingSummary> createState() => _CardSpendingSummaryState();
}

class _CardSpendingSummaryState extends State<CardSpendingSummary> {
  bool isEditingGoal = false;
  final TextEditingController _goalController = TextEditingController();

  Future<void> _saveSpendingGoal(int goal) async {
    final updatedCard = widget.selectedCard!.copyWith(spendingGoal: goal);
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;

    final repo = RegisterCardRepository(userId: userId);
    await repo.updateRegisterCard(updatedCard);
    widget.onGoalSaved(updatedCard);
  }

  void _calculateStatus() {
    final result = calculateStatusFromCard(
      selectedCard: widget.selectedCard,
      defaultGoal: widget.monthlyGoal,
      defaultSpending: widget.todaySpending,
      allCards: widget.registerCards,
    );

    setState(() {
      _goalController.text = result.goal.toString();
      isEditingGoal = true;
    });

    print(
      '📊 상태 계산됨 ➜ goal: ${result.goal}, spending: ${result.spending}, status: ${result.status}',
    );
  }

  @override
  Widget build(BuildContext context) {
    final totalSpending = RegisterCardModel.calculateTotalSpending(
      widget.registerCards,
    );
    final card = widget.selectedCard;
    final goal = card?.spendingGoal;
    final status = calculateSpendingStatus(
      monthlyGoal: goal ?? widget.monthlyGoal,
      todaySpending: card?.totalAmount ?? widget.todaySpending,
    );

    final Color backgroundColor =
        goal == null ? const Color.fromRGBO(247, 247, 249, 1) : status.color;

    if (card == null) {
      return _buildSummaryUI(
        title: DateFormat('yyyy년 M월 지출').format(DateTime.now()),
        spending: totalSpending,
        goal: widget.monthlyGoal,
        status: calculateSpendingStatus(
          monthlyGoal: widget.monthlyGoal,
          todaySpending: totalSpending,
        ),
        backgroundColor: const Color.fromRGBO(247, 247, 249, 1),
      );
    }

    if (card.spendingGoal == null || isEditingGoal) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8),
        child: Container(
          decoration: BoxDecoration(
            color: Color.fromRGBO(247, 247, 249, 1),
            borderRadius: BorderRadius.circular(16),
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '목표 지출을 설정해주세요',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _goalController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: '목표 지출 (원)',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () {
                      final goal = int.tryParse(_goalController.text);
                      print('🎯 입력된 목표 지출(goal): $goal');
                      if (goal != null && goal > 0) {
                        _saveSpendingGoal(goal);
                        setState(() {
                          isEditingGoal = false;
                          if (widget.selectedCard != null) {
                            final updatedCard = widget.selectedCard!.copyWith(
                              spendingGoal: goal,
                            );
                            final newStatus = calculateSpendingStatus(
                              monthlyGoal: goal,
                              todaySpending: updatedCard.totalAmount,
                            );
                            widget.onGoalSaved(updatedCard);
                          }
                        });
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(60, 36),
                      backgroundColor: const Color.fromRGBO(247, 247, 249, 1),
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 8,
                      ),
                    ),
                    child: const Text('등록'),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    }

    return _buildSummaryUI(
      title: '${DateFormat('yyyy년 M월').format(DateTime.now())} ${card.name} 지출',
      spending: card.totalAmount,
      goal: card.spendingGoal ?? 0,
      status: calculateSpendingStatus(
        monthlyGoal: card.spendingGoal ?? widget.monthlyGoal,
        todaySpending: card.totalAmount,
      ),
      backgroundColor: Color.fromRGBO(247, 247, 249, 1),
    );
  }

  Widget _buildSummaryUI({
    required String title,
    required int spending,
    required int goal,
    required SpendingStatus status, // 추가
    required Color backgroundColor, // 추가
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8),
      child: Container(
        decoration: BoxDecoration(
          color: Color.fromRGBO(247, 247, 249, 1),
          borderRadius: BorderRadius.circular(16),
        ),
        padding: const EdgeInsets.all(16),
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const SizedBox(width: 4),
                    const BentoLabelBox(label: '월간 지출'),
                    const SizedBox(width: 12),
                    Expanded(
                      child: LabeledProgressBox(
                        progress: goal > 0 ? spending / goal : 0,
                        color: status.color.withOpacity(0.6),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const SizedBox(width: 4),
                    const BentoLabelBox(label: '권장 지출'),
                    const SizedBox(width: 12),
                    Expanded(
                      child: LabeledProgressBox(
                        progress:
                            goal > 0
                                ? ((goal / 30) * DateTime.now().day) / goal
                                : 0,
                        color: status.color.withOpacity(1),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            if (widget.selectedCard != null)
              Positioned(
                top: -10,
                right: -6,
                child: IconButton(
                  icon: const Icon(Icons.edit, size: 18),
                  onPressed: _calculateStatus,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

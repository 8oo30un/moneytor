import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../utils/progress_bar.dart';
import '../model/register_card_model.dart';
import '../utils/spending_calculator.dart' as spending_calculator;
import 'package:provider/provider.dart';
import '../state/app_state.dart';

class CardSpendingSummary extends StatefulWidget {
  final RegisterCardModel? selectedCard;
  final int todaySpending;
  final int monthlyGoal;
  final Color statusColor;
  final String userId;
  final List<RegisterCardModel> registerCards;
  final Function(int updatedDefaultGoal)? onDefaultGoalChanged;

  const CardSpendingSummary({
    super.key,
    required this.selectedCard,
    required this.todaySpending,
    required this.monthlyGoal,
    required this.statusColor,
    required this.userId,
    required this.registerCards,
    this.onDefaultGoalChanged,
  });

  @override
  State<CardSpendingSummary> createState() => _CardSpendingSummaryState();
}

class _CardSpendingSummaryState extends State<CardSpendingSummary> {
  bool isEditingGoal = false;
  final TextEditingController _goalController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final List<RegisterCardModel> registerCards = appState.registerCards;
    final int defaultGoal = appState.defaultGoal;

    final totalSpending = RegisterCardModel.calculateTotalSpending(
      registerCards,
    );
    final card = widget.selectedCard;
    final goal =
        card == null
            ? appState.monthlyGoal
            : (card.spendingGoal ??
                appState.monthlyGoal); // null일 경우 defaultGoal 사용
    final int parsedGoal =
        int.tryParse(_goalController.text) ?? (goal ?? defaultGoal);

    final now = DateTime.now();
    final int daysInMonth = DateUtils.getDaysInMonth(now.year, now.month);
    final int today = now.day;

    final int adjustedGoal = ((goal / daysInMonth) * today).round();

    final int spending =
        card?.totalAmount ??
        RegisterCardModel.calculateTotalSpending(registerCards);

    final int adjustedSpending =
        card == null
            ? ((RegisterCardModel.calculateTotalSpending(registerCards) /
                        daysInMonth) *
                    today)
                .round()
            : ((card.totalAmount / daysInMonth) * today).round();

    final status = spending_calculator.calculateSpendingStatus(context);

    if (card == null) {
      return _buildSummaryUI(
        title: DateFormat('yyyy년 M월 지출').format(DateTime.now()),
        spending: adjustedSpending,
        goal: adjustedGoal,
        status: status,
        backgroundColor: const Color.fromRGBO(247, 247, 249, 1),
      );
    }

    if (card.spendingGoal == null || isEditingGoal || card.spendingGoal == 0) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _goalController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: '한달 목표 지출 (원)',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () {
                      final goal = int.tryParse(_goalController.text);
                      if (goal != null && goal >= 0) {
                        final appState = Provider.of<AppState>(
                          context,
                          listen: false,
                        );
                        if (widget.selectedCard == null) {
                          appState.setMonthlyGoal(goal);
                        } else {
                          final updatedCard = widget.selectedCard!.copyWith(
                            spendingGoal: goal,
                          );
                          appState.updateCard(updatedCard, context);
                        }
                        setState(() {
                          isEditingGoal = false;
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
      spending: adjustedSpending,
      goal: adjustedGoal,
      status: status,
      backgroundColor: Color.fromRGBO(247, 247, 249, 1),
    );
  }

  Widget _buildSummaryUI({
    required String title,
    required int spending,
    required int goal,
    required spending_calculator.SpendingStatus status, // 추가
    required Color backgroundColor, // 추가
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
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
            Positioned(
              top: -10,
              right: -6,
              child: IconButton(
                icon: const Icon(Icons.edit, size: 18),
                onPressed: () {
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(20),
                      ),
                    ),
                    builder: (_) {
                      final isCardMode = widget.selectedCard != null;
                      return Padding(
                        padding: EdgeInsets.only(
                          bottom: MediaQuery.of(context).viewInsets.bottom,
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Wrap(
                            children: [
                              Text(
                                isCardMode
                                    ? '한달 카테고리 목표 지출 설정'
                                    : '한달 전체 목표 지출 설정',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 30),
                              TextField(
                                controller: _goalController,
                                keyboardType: TextInputType.number,
                                decoration: const InputDecoration(
                                  border: OutlineInputBorder(),
                                ),
                              ),
                              const SizedBox(height: 16),
                              ElevatedButton(
                                onPressed: () {
                                  final int? newGoal = int.tryParse(
                                    _goalController.text,
                                  );
                                  print('[DEBUG] newGoal: $newGoal');
                                  print(
                                    '[DEBUG] selectedCard is null: ${widget.selectedCard == null}',
                                  );
                                  final appState = Provider.of<AppState>(
                                    context,
                                    listen: false,
                                  );
                                  if (newGoal != null && newGoal >= 0) {
                                    if (widget.selectedCard == null) {
                                      appState.setMonthlyGoal(newGoal);
                                      if (widget.onDefaultGoalChanged != null) {
                                        widget.onDefaultGoalChanged!(newGoal);
                                      }
                                    } else {
                                      final updatedCard = widget.selectedCard!
                                          .copyWith(spendingGoal: newGoal);
                                      appState.updateCard(updatedCard, context);
                                    }
                                    setState(() {
                                      _goalController.text = newGoal.toString();
                                      isEditingGoal = false;
                                    });
                                    Navigator.pop(context);
                                  }
                                },
                                style: ElevatedButton.styleFrom(
                                  minimumSize: const Size(60, 36),
                                  backgroundColor: const Color.fromRGBO(
                                    247,
                                    247,
                                    249,
                                    1,
                                  ),
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
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

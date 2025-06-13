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
                          appState.selectCard(
                            updatedCard,
                          ); // 선택된 카드 다시 설정하여 상태 계산
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

                      _goalController.text =
                          isCardMode
                              ? (widget.selectedCard?.spendingGoal
                                      ?.toString() ??
                                  '')
                              : context.read<AppState>().monthlyGoal.toString();

                      return Padding(
                        padding: EdgeInsets.only(
                          bottom: MediaQuery.of(context).viewInsets.bottom,
                        ),
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.all(16),
                          child: SingleChildScrollView(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                vertical: 12.0,
                              ),
                              child: Column(
                                children: [
                                  Center(
                                    child: Text(
                                      isCardMode
                                          ? '한달 카테고리 목표 지출 설정'
                                          : '한달 전체 목표 지출 설정',
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.black87,
                                        letterSpacing: 0.5,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                  const SizedBox(height: 30),
                                  Row(
                                    children: [
                                      Expanded(
                                        flex: 4,
                                        child: TextField(
                                          controller: _goalController,
                                          keyboardType: TextInputType.number,
                                          decoration: InputDecoration(
                                            border: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                              borderSide: BorderSide.none,
                                            ),
                                            filled: true,
                                            fillColor: const Color.fromRGBO(
                                              247,
                                              247,
                                              249,
                                              1,
                                            ),
                                            contentPadding:
                                                const EdgeInsets.symmetric(
                                                  horizontal: 16,
                                                  vertical: 14,
                                                ),
                                            hintText: '목표 지출을 입력하세요',
                                            hintStyle: TextStyle(
                                              color: Colors.grey.shade500,
                                              fontWeight: FontWeight.w400,
                                            ),
                                          ),
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w500,
                                            color: Colors.black87,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 24),
                                      Expanded(
                                        flex: 1,
                                        child: ElevatedButton(
                                          onPressed: () async {
                                            final int? newGoal = int.tryParse(
                                              _goalController.text,
                                            );
                                            print('🛠️ 입력된 목표 지출 값: $newGoal');
                                            print('🛠️ 선택된 카드 모드: $isCardMode');
                                            print(
                                              '🛠️ 선택된 카드: ${widget.selectedCard?.name}',
                                            );
                                            final appState =
                                                Provider.of<AppState>(
                                                  context,
                                                  listen: false,
                                                );
                                            if (newGoal != null &&
                                                newGoal >= 0) {
                                              if (isCardMode &&
                                                  widget.selectedCard != null) {
                                                final updatedCard = widget
                                                    .selectedCard!
                                                    .copyWith(
                                                      spendingGoal: newGoal,
                                                    );
                                                await appState.updateCard(
                                                  updatedCard,
                                                  context,
                                                );
                                                print(
                                                  '📝 업데이트된 카드 목표 지출: ${updatedCard.spendingGoal}',
                                                );
                                                await appState.selectCard(
                                                  updatedCard,
                                                );
                                              } else {
                                                appState.setMonthlyGoal(
                                                  newGoal,
                                                );
                                                print(
                                                  '📌 전체 monthlyGoal 설정됨: $newGoal',
                                                );
                                                if (widget
                                                        .onDefaultGoalChanged !=
                                                    null) {
                                                  widget.onDefaultGoalChanged!(
                                                    newGoal,
                                                  );
                                                }
                                              }
                                              setState(() {
                                                _goalController.text =
                                                    newGoal.toString();
                                                isEditingGoal = false;
                                              });
                                              Navigator.pop(context);
                                            }
                                          },
                                          style: ElevatedButton.styleFrom(
                                            minimumSize: const Size(60, 48),
                                            backgroundColor:
                                                const Color.fromRGBO(
                                                  247,
                                                  247,
                                                  249,
                                                  1,
                                                ),
                                            foregroundColor: Colors.black87,
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                            ),
                                            elevation: 0,
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 12,
                                              vertical: 12,
                                            ),
                                            textStyle: const TextStyle(
                                              fontWeight: FontWeight.w600,
                                              fontSize: 16,
                                            ),
                                          ),
                                          child: const Text(
                                            '등록',
                                            textAlign: TextAlign.center,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 24),
                                ],
                              ),
                            ),
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

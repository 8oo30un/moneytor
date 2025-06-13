import 'package:cloud_firestore/cloud_firestore.dart';
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
  final Function(RegisterCardModel? updatedCard) onGoalSaved;
  final List<RegisterCardModel> registerCards;
  final Function(int updatedDefaultGoal)? onDefaultGoalChanged;

  const CardSpendingSummary({
    super.key,
    required this.selectedCard,
    required this.todaySpending,
    required this.monthlyGoal,
    required this.statusColor,
    required this.userId,
    required this.onGoalSaved,
    required this.registerCards,
    this.onDefaultGoalChanged,
  });

  @override
  State<CardSpendingSummary> createState() => _CardSpendingSummaryState();
}

class _CardSpendingSummaryState extends State<CardSpendingSummary> {
  bool isEditingGoal = false;
  final TextEditingController _goalController = TextEditingController();

  Future<void> _loadDefaultGoal() async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;

    try {
      final doc =
          await FirebaseFirestore.instance
              .collection('users')
              .doc(userId)
              .get();
      if (doc.exists) {
        final data = doc.data();
        final int defaultGoal = data?['defaultGoal'] ?? 0;
        setState(() {
          _goalController.text = defaultGoal.toString();
        });
        if (widget.onDefaultGoalChanged != null) {
          widget.onDefaultGoalChanged!(defaultGoal);
        }
        print('[DEBUG] Firestore에서 불러온 defaultGoal: $defaultGoal');
      }
    } catch (e) {
      print('[ERROR] defaultGoal 불러오기 실패: $e');
    }
  }

  Future<void> _saveSpendingGoal(int goal) async {
    final updatedCard = widget.selectedCard!.copyWith(
      spendingGoal: goal,
      totalAmount: widget.selectedCard!.totalAmount,
    );
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;

    final repo = RegisterCardRepository(userId: userId);
    await repo.updateRegisterCard(updatedCard);
    widget.onGoalSaved(updatedCard);
    setState(() {
      _goalController.text = goal.toString();
      isEditingGoal = false;
    });
  }

  Future<void> _calculateStatus() async {
    final result = await calculateStatusFromCard(
      selectedCard: widget.selectedCard,
      defaultGoal: widget.monthlyGoal,
      defaultSpending: widget.todaySpending,
      allCards: widget.registerCards,
    );

    print('Calculated monthlyGoal: ${result.goal}');

    setState(() {
      _goalController.text = result.goal.toString();
      isEditingGoal = true;
    });
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
    print(
      '❤️ Status 계산됨 → goal: ${goal ?? widget.monthlyGoal}, spending: ${card?.totalAmount ?? widget.todaySpending}, status: ${status.status}, color: ${status.color}',
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
              // const Text(
              //   '목표 지출을 설정해주세요',
              //   style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              // ),
              // const SizedBox(height: 12),
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
                      print('🎯 입력된 목표 지출(goal): $goal');
                      if (goal != null && goal >= 0) {
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
                              const SizedBox(height: 16),
                              TextField(
                                controller: _goalController,
                                keyboardType: TextInputType.number,
                                decoration: const InputDecoration(
                                  border: OutlineInputBorder(),
                                ),
                              ),
                              const SizedBox(height: 16),
                              ElevatedButton(
                                onPressed: () async {
                                  final int? newGoal = int.tryParse(
                                    _goalController.text,
                                  );
                                  // Debug print statements for logging
                                  print('[DEBUG] newGoal: $newGoal');
                                  print(
                                    '[DEBUG] selectedCard is null: ${widget.selectedCard == null}',
                                  );
                                  if (newGoal != null && newGoal >= 0) {
                                    if (widget.selectedCard == null) {
                                      final userId =
                                          FirebaseAuth
                                              .instance
                                              .currentUser
                                              ?.uid;
                                      if (userId != null) {
                                        final repo = RegisterCardRepository(
                                          userId: userId,
                                        );
                                        await repo.updateDefaultGoal(newGoal);

                                        await _loadDefaultGoal(); // 업데이트 후 최신 값 다시 불러오기
                                        print(
                                          '[DEBUG] 전체 목표 지출 수정 완료, onGoalSaved(null) 호출 전',
                                        );

                                        widget.onGoalSaved(null);
                                        print(
                                          '[DEBUG] onGoalSaved(null) 호출 완료',
                                        );
                                        setState(() {
                                          _goalController.text =
                                              newGoal.toString();
                                          print(
                                            '[DEBUG] setState 완료: _goalController.text=${_goalController.text}, isEditingGoal=$isEditingGoal',
                                          );
                                        });
                                        Navigator.pop(context);
                                      }
                                    } else {
                                      setState(() {
                                        _goalController.text =
                                            newGoal.toString();
                                        isEditingGoal = true;
                                      });

                                      final updatedCard = widget.selectedCard!
                                          .copyWith(spendingGoal: newGoal);
                                      print(
                                        '[DEBUG] updatedCard: $updatedCard',
                                      );

                                      // Save updatedCard to Firestore
                                      final userId =
                                          FirebaseAuth
                                              .instance
                                              .currentUser
                                              ?.uid;
                                      if (userId != null) {
                                        final repo = RegisterCardRepository(
                                          userId: userId,
                                        );
                                        await repo.updateRegisterCard(
                                          updatedCard,
                                        );

                                        // Also update monthlyGoal field in Firestore (optional logic)
                                        await FirebaseFirestore.instance
                                            .collection('users')
                                            .doc(userId)
                                            .update({'monthlyGoal': newGoal});
                                        print(
                                          '[DEBUG] monthlyGoal 업데이트 완료: $newGoal',
                                        );
                                      }

                                      widget.onGoalSaved(updatedCard);
                                      Navigator.pop(context);
                                    }
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

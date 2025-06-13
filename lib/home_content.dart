// lib/home_content.dart
import 'package:flutter/material.dart';
import 'model/register_card_model.dart';
import 'widgets/spending_status_display.dart';
import 'widgets/card_spending_summary.dart' as summary;
import 'widgets/card_spending_detail_grid.dart';
import 'utils/spending_calculator.dart' as calc;
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'data/register_card_repository.dart';
import 'home.dart'; // for SortType enum

class HomeContent extends StatefulWidget {
  final String userName;
  final int monthlyGoal;
  final int todaySpending;
  final RegisterCardModel? selectedCard;
  final Color statusColor;
  final List<RegisterCardModel> registerCards;
  final bool isEditing;
  final Function(bool) onEditingChanged;
  final Function(RegisterCardModel) onGoalSaved;
  final Function(int) onCardDeleted;
  final Function(RegisterCardModel) onCardSelected;
  final VoidCallback onShowAddCategoryDialog;
  final PageController pageController;
  final int currentPageIndex;
  final Function(int) onBackToCardGrid;
  final SortType selectedSort;
  final bool isAscending;
  final Function(SortType) onSortToggle;
  final Animation<double> shakeAnimation;
  final VoidCallback onAddExpense; // 또는 Function() onAddExpense;
  final void Function(int index, String newName) onExpenseNameChanged;
  final void Function(int index) onExpenseDeleted;
  final RegisterCardRepository registerCardRepo;

  const HomeContent({
    Key? key,
    required this.userName,
    required this.monthlyGoal,
    required this.todaySpending,
    required this.selectedCard,
    required this.statusColor,
    required this.registerCards,
    required this.isEditing,
    required this.onEditingChanged,
    required this.onGoalSaved,
    required this.onCardDeleted,
    required this.onCardSelected,
    required this.onShowAddCategoryDialog,
    required this.pageController,
    required this.currentPageIndex,
    required this.onBackToCardGrid,
    required this.selectedSort,
    required this.isAscending,
    required this.onSortToggle,
    required this.shakeAnimation,
    required this.onAddExpense,
    required this.onExpenseNameChanged,
    required this.onExpenseDeleted,
    required this.registerCardRepo,
  }) : super(key: key);

  @override
  _HomeContentState createState() => _HomeContentState();
}

class _HomeContentState extends State<HomeContent> {
  late RegisterCardRepository _registerCardRepo;
  RegisterCardModel? cachedSelectedCard;
  int defaultGoal = 0;
  int monthlyGoal = 0;
  int todaySpending = 0;
  Color statusColor = Colors.grey;
  bool _isRegisteringTotalGoal = false;
  List<RegisterCardModel> registerCards = [];

  @override
  void initState() {
    super.initState();
    final userId = FirebaseAuth.instance.currentUser?.uid ?? '';
    _registerCardRepo = RegisterCardRepository(userId: userId);
    // 초기 상태 계산 및 캐싱
    cachedSelectedCard = widget.selectedCard;
    _loadDefaultGoal();
  }

  @override
  void didUpdateWidget(covariant HomeContent oldWidget) {
    super.didUpdateWidget(oldWidget);
    // selectedCard가 변경되면 상태를 다시 계산
    if (widget.selectedCard != oldWidget.selectedCard) {
      cachedSelectedCard = widget.selectedCard;
      _calculateStatus();
    }
  }

  void onGoalSaved(RegisterCardModel? card) async {
    if (card != null) {
      setState(() {
        cachedSelectedCard = card;

        // 🔧 registerCards 리스트 내 해당 카드만 교체
        registerCards =
            registerCards.map((c) {
              return c.id == card.id ? card : c;
            }).toList();
      });
    }

    await _loadUserGoals();
    await _loadRegisterCards(); // 🔄 Firestore에서 카드 불러오기
    _calculateStatus();
  }

  void onDefaultGoalChanged(int updatedGoal) {
    setState(() {
      defaultGoal = updatedGoal;
    });
    _calculateStatus();
  }

  void _calculateStatus() {
    final monthlyGoal = cachedSelectedCard?.spendingGoal ?? defaultGoal;
    final todaySpending =
        cachedSelectedCard?.totalAmount ??
        registerCards.fold<int>(0, (sum, card) => sum + card.totalAmount);

    print('[DEBUG] _calculateStatus 호출!!!!!!');
    print('[DEBUG] monthlyGoal: $monthlyGoal');
    print('[DEBUG] todaySpending: $todaySpending');
    print('[DEBUG] cachedSelectedCard: $cachedSelectedCard');

    setState(() {
      this.monthlyGoal = monthlyGoal;
      this.todaySpending = todaySpending; // 추가: todaySpending 상태 변수 업데이트

      statusColor =
          (monthlyGoal == 0)
              ? const Color.fromRGBO(247, 247, 249, 1)
              : calc
                  .calculateSpendingStatus(
                    monthlyGoal: monthlyGoal,
                    todaySpending: todaySpending,
                  )
                  .color;

      print('[DEBUG] setState 내부 monthlyGoal: $monthlyGoal , $todaySpending');
    });
  }

  Future<void> _loadDefaultGoal() async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;

    final doc =
        await FirebaseFirestore.instance.collection('users').doc(userId).get();
    if (doc.exists) {
      final data = doc.data();
      setState(() {
        defaultGoal = data?['defaultGoal'] ?? 0;
      });
      _calculateStatus(); // 상태가 바뀐 후 호출
    }
  }

  Future<void> _loadRegisterCards() async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) {
      print('[DEBUG] ❌ userId is null');
      return;
    }

    try {
      final repo = RegisterCardRepository(userId: userId);
      final cards = await repo.fetchRegisterCards();

      setState(() {
        registerCards = cards;
      });
      print('[DEBUG] ✅ Firestore에서 registerCards 불러오기 완료: ${cards.length}개');
    } catch (e) {
      print('[ERROR] 🔥 fetchRegisterCards 실패: $e');
    }
  }

  Future<void> _loadUserGoals() async {
    try {
      final goals = await _registerCardRepo.fetchUserGoals();
      setState(() {
        monthlyGoal = goals['monthlyGoal']!;
        todaySpending = goals['todaySpending']!;
      });
    } catch (e) {}
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1) SpendingStatusDisplay
        SpendingStatusDisplay(
          userName: widget.userName,
          monthlyGoal: monthlyGoal,
          todaySpending: widget.todaySpending,
          selectedCard: _isRegisteringTotalGoal ? null : cachedSelectedCard,
          registerCards: registerCards, // ✅ 리스트 전달
        ),

        // 2) CardSpendingSummary
        summary.CardSpendingSummary(
          selectedCard: cachedSelectedCard,
          todaySpending: todaySpending,
          monthlyGoal: monthlyGoal,
          statusColor: statusColor,
          userId: FirebaseAuth.instance.currentUser?.uid ?? '',
          registerCards: widget.registerCards,
          onGoalSaved: onGoalSaved,
          onDefaultGoalChanged: onDefaultGoalChanged,
        ),

        // 3) Expanded 영역: 정렬 버튼 + PageView 및 카드 상세 화면
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 정렬 + 수정 버튼 Row
                  Row(
                    children: [
                      // 가격 정렬 버튼
                      OutlinedButton(
                        onPressed: () {
                          widget.onSortToggle(SortType.price);
                        },
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size(80, 36),
                          backgroundColor: const Color.fromRGBO(
                            247,
                            247,
                            249,
                            1,
                          ),
                          foregroundColor:
                              widget.selectedSort == SortType.price
                                  ? Colors.black
                                  : Colors.grey,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                          side: BorderSide.none,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 0,
                            vertical: 8,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text('가격'),
                            const SizedBox(width: 4),
                            Icon(
                              widget.selectedSort == SortType.price
                                  ? (widget.isAscending
                                      ? Icons.arrow_upward
                                      : Icons.arrow_downward)
                                  : Icons.arrow_downward,
                              size: 18,
                              color:
                                  widget.selectedSort == SortType.price
                                      ? Colors.black
                                      : Colors.grey,
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(width: 8),

                      // 날짜 정렬 버튼
                      OutlinedButton(
                        onPressed: () {
                          widget.onSortToggle(SortType.date);
                        },
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size(80, 36),
                          backgroundColor: const Color.fromRGBO(
                            247,
                            247,
                            249,
                            1,
                          ),
                          foregroundColor:
                              widget.selectedSort == SortType.date
                                  ? Colors.black
                                  : Colors.grey,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                          side: BorderSide.none,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 0,
                            vertical: 8,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text('날짜'),
                            const SizedBox(width: 4),
                            Icon(
                              widget.selectedSort == SortType.date
                                  ? (widget.isAscending
                                      ? Icons.arrow_upward
                                      : Icons.arrow_downward)
                                  : Icons.arrow_downward,
                              size: 18,
                              color:
                                  widget.selectedSort == SortType.date
                                      ? Colors.black
                                      : Colors.grey,
                            ),
                          ],
                        ),
                      ),

                      const Spacer(),

                      // 수정 버튼
                      OutlinedButton(
                        onPressed: () {
                          widget.onEditingChanged(!widget.isEditing);
                        },
                        style: OutlinedButton.styleFrom(
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
                          side: BorderSide.none,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 8,
                          ),
                        ),
                        child: Text(widget.isEditing ? '완료' : '수정'),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // PageView (카드 그리드, 카드 상세)
                  Expanded(
                    child: PageView(
                      controller: widget.pageController,
                      physics: const NeverScrollableScrollPhysics(),
                      children: [
                        // 3-1) 카드 그리드 페이지
                        _buildCardGrid(),

                        // 3-2) 카드 상세 페이지
                        _buildCardDetail(context),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCardGrid() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.all(0),
      child: GridView.count(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 1.25,
        children: [
          ...widget.registerCards.asMap().entries.map((entry) {
            int index = entry.key;
            RegisterCardModel card = entry.value;
            return AnimatedBuilder(
              animation: widget.shakeAnimation,
              builder: (context, child) {
                return Transform.rotate(
                  angle:
                      widget.isEditing ? widget.shakeAnimation.value * 0.01 : 0,
                  child: child,
                );
              },
              child: GestureDetector(
                onTap: () {
                  widget.onCardSelected(card);
                },
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color:
                        (card.spendingGoal ?? 0) == 0
                            ? const Color.fromRGBO(247, 247, 249, 1)
                            : calc
                                .calculateSpendingStatus(
                                  monthlyGoal: card.spendingGoal!,
                                  todaySpending: card.totalAmount,
                                )
                                .color,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  alignment: Alignment.topLeft,
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Positioned.fill(
                        child: Align(
                          alignment: Alignment.topLeft,
                          child:
                              widget.isEditing
                                  ? Padding(
                                    padding: const EdgeInsets.only(right: 36.0),
                                    child: IntrinsicWidth(
                                      child: TextFormField(
                                        initialValue: card.name,
                                        onChanged: (value) async {
                                          final updatedCard = widget
                                              .registerCards[index]
                                              .copyWith(name: value);
                                          widget.registerCards[index] =
                                              updatedCard;
                                          try {
                                            await widget.registerCardRepo
                                                .updateRegisterCard(
                                                  updatedCard,
                                                );
                                          } catch (e) {}
                                        },
                                        decoration: const InputDecoration(
                                          isDense: true,
                                          isCollapsed: true,
                                          enabledBorder: UnderlineInputBorder(
                                            borderSide: BorderSide(
                                              color: Colors.black38,
                                              width: 1.5,
                                            ),
                                          ),
                                          focusedBorder: UnderlineInputBorder(
                                            borderSide: BorderSide(
                                              color: Colors.black87,
                                              width: 2,
                                            ),
                                          ),
                                          contentPadding: EdgeInsets.only(
                                            bottom: 4,
                                          ),
                                        ),
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  )
                                  // Name will be saved to Firestore on '완료' button tap
                                  : Stack(
                                    children: [
                                      Align(
                                        alignment: Alignment.topLeft,
                                        child: Text(
                                          card.name,
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                      Positioned(
                                        bottom: 0,
                                        right: 0,
                                        child: Text(
                                          '${card.totalAmount}원',
                                          style: const TextStyle(
                                            fontSize: 12,
                                            color: Colors.black,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                        ),
                      ),
                      if (widget.isEditing)
                        Positioned(
                          top: -5,
                          right: -5,
                          child: GestureDetector(
                            onTap: () => widget.onCardDeleted(index),
                            child: Container(
                              width: 20,
                              height: 20,
                              decoration: BoxDecoration(
                                color: Colors.red[200],
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.close,
                                size: 16,
                                color: Colors.black54,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
          GestureDetector(
            onTap: widget.onShowAddCategoryDialog,
            child: Container(
              decoration: BoxDecoration(
                color: const Color.fromRGBO(247, 247, 249, 1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Center(
                child: Icon(Icons.add, size: 48, color: Colors.grey),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCardDetail(BuildContext context) {
    if (widget.selectedCard == null) {
      return Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color:
            (widget.selectedCard!.spendingGoal ?? 0) == 0
                ? const Color.fromRGBO(247, 247, 249, 1)
                : statusColor,
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.all(0),
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 상단 바: 뒤로가기, 제목, 추가 버튼
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () {
                    widget.onBackToCardGrid(0); // 상위에서 구현해서 넘겨줘야 함
                  },
                ),
                Expanded(
                  child: Center(
                    child: Text(
                      widget.selectedCard?.name ?? '선택된 카드 없음',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.add),
                  onPressed: widget.onAddExpense,
                ),
              ],
            ),
            const SizedBox(height: 12),

            // 지출 리스트
            if (widget.selectedCard!.expenses.isNotEmpty)
              ...widget.selectedCard!.expenses.asMap().entries.map((entry) {
                final index = entry.key;
                final expense = entry.value;
                final controller = TextEditingController(text: expense['name']);

                return ListTile(
                  title:
                      widget.isEditing
                          ? TextFormField(
                            controller: controller,
                            onChanged: (newName) {
                              widget.onExpenseNameChanged(index, newName);
                            },
                            decoration: const InputDecoration(
                              border: UnderlineInputBorder(),
                              isDense: true,
                              contentPadding: EdgeInsets.symmetric(vertical: 8),
                            ),
                          )
                          : Text(expense['name']),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('${expense['price']}원'),
                      const SizedBox(width: 8),
                      if (expense['date'] != null)
                        Text(
                          DateFormat('M월 d일 HH:mm').format(
                            DateTime.tryParse(expense['date']) ??
                                DateTime.now(),
                          ),
                        ),
                      if (widget.isEditing)
                        IconButton(
                          icon: const Icon(
                            Icons.close,
                            size: 18,
                            color: Colors.red,
                          ),
                          onPressed: () {
                            widget.onExpenseDeleted(index);
                          },
                        ),
                    ],
                  ),
                );
              }).toList(),

            // 카드 상세 그리드
            CardSpendingDetailGrid(
              card: cachedSelectedCard!,
              statusColor: statusColor,
            ),
          ],
        ),
      ),
    );
  }
}

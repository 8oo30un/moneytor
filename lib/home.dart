// lib/home.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'utils/spending_calculator.dart';
import 'utils/progress_bar.dart';
import 'widgets/card_spending_summary.dart';
import 'widgets/spending_status_display.dart';
import 'model/register_card_model.dart';
import 'data/register_card_repository.dart';
import 'utils/status_utils.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

enum SortType { price, date }

class _HomePageState extends State<HomePage>
    with SingleTickerProviderStateMixin {
  int currentPageIndex = 0;
  PageController pageController = PageController();
  RegisterCardModel? selectedCard;
  int _selectedIndex = 2;
  bool isEditing = false;
  String userName = '';
  String? photoUrl;
  int monthlyGoal = 1000000;
  int todaySpending = 20000;
  String spendingStatus = '절약'; // 절약, 평균, 과소비 중 하나
  Color statusColor = Colors.green; // 절약: 초록, 평균: 파랑, 과소비: 빨강

  SortType selectedSort = SortType.price;
  bool isAscending = false;

  late final RegisterCardRepository _registerCardRepo;

  // List<String> categories => List<RegisterCardModel> registerCards 로 변경
  List<RegisterCardModel> registerCards = [];

  late final AnimationController _shakeController;
  late final Animation<double> _shakeAnimation;

  @override
  void initState() {
    super.initState();
    registerCards.sort((a, b) => b.totalAmount.compareTo(a.totalAmount));

    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      userName = user.displayName ?? '';
      photoUrl = user.photoURL;
      _registerCardRepo = RegisterCardRepository(userId: user.uid);
    } else {
      _registerCardRepo = RegisterCardRepository(userId: '');
    }

    String? selectedCardName = selectedCard?.name;

    final status = calculateSpendingStatus(
      monthlyGoal: monthlyGoal,
      todaySpending: todaySpending,
    );
    spendingStatus = status.status;
    statusColor = status.color;

    _shakeController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    )..repeat(reverse: true);

    _shakeAnimation = Tween<double>(begin: 0.0, end: 2.0).animate(
      CurvedAnimation(parent: _shakeController, curve: Curves.elasticIn),
    );
    _shakeController.stop();

    _loadRegisterCards();
    _calculateStatus();
  }

  Future<void> _loadRegisterCards() async {
    try {
      final cards = await _registerCardRepo.fetchRegisterCards();
      setState(() {
        registerCards = cards;
        registerCards.sort((a, b) => b.totalAmount.compareTo(a.totalAmount));
      });
      print('Firestore 등록카드 로드 완료, 개수: ${cards.length}');
    } catch (e) {
      print('Firestore 등록카드 로드 실패: $e');
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
      // Add navigation logic here if needed
    });
  }

  void _showAddCategoryDialog() {
    String newCategory = '';
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('카테고리 추가'),
          content: TextField(
            autofocus: true,
            decoration: const InputDecoration(hintText: '카테고리 이름'),
            onChanged: (value) {
              newCategory = value;
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('취소'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (newCategory.trim().isNotEmpty) {
                  try {
                    final newCard = RegisterCardModel(
                      id: '', // Firestore 자동 생성
                      name: newCategory.trim(),
                      totalAmount: 0,
                      expenses: [],
                    );
                    await _registerCardRepo.addRegisterCard(newCard);
                    await _loadRegisterCards();
                  } catch (e) {
                    print('Firestore 저장 실패: $e');
                  }
                }
                Navigator.of(context).pop();
              },
              child: const Text('등록'),
            ),
          ],
        );
      },
    );
  }

  void _calculateStatus() {
    final result = calculateStatusFromCard(
      selectedCard: selectedCard,
      allCards: registerCards, // ✅ 이걸 꼭 전달해야 함
    );

    setState(() {
      monthlyGoal = result.goal;
      todaySpending = result.spending;
      spendingStatus = result.status;
      statusColor = result.color;
    });

    print(
      '상태 계산됨 ➜ goal: ${result.goal}, spending: ${result.spending}, status: ${result.status}',
    );
  }

  void togglePriceSort() {
    print('🟡 togglePriceSort 호출됨');

    setState(() {
      selectedSort = SortType.price;
      isAscending = !isAscending;

      if (selectedCard == null) {
        registerCards.sort(
          (a, b) =>
              isAscending
                  ? a.totalAmount.compareTo(b.totalAmount)
                  : b.totalAmount.compareTo(a.totalAmount),
        );
        print('✅ registerCards 가격 정렬 완료');
      } else {
        selectedCard = selectedCard!.copyWith(
          expenses: List<Map<String, dynamic>>.from(selectedCard!.expenses)
            ..sort(
              (a, b) =>
                  isAscending
                      ? (a['price'] as int).compareTo(b['price'] as int)
                      : (b['price'] as int).compareTo(a['price'] as int),
            ),
        );
        print('✅ selectedCard.expenses 가격 정렬 완료');
      }
    });
  }

  void toggleDateSort() {
    setState(() {
      if (selectedSort == SortType.date) {
        isAscending = !isAscending;
      } else {
        selectedSort = SortType.date;
        isAscending = false;
      }
      // Sort by the latest expense date if available, otherwise leave as is
      registerCards.sort((a, b) {
        DateTime? aDate =
            a.expenses.isNotEmpty && a.expenses.last['date'] != null
                ? DateTime.tryParse(a.expenses.last['date'].toString())
                : null;
        DateTime? bDate =
            b.expenses.isNotEmpty && b.expenses.last['date'] != null
                ? DateTime.tryParse(b.expenses.last['date'].toString())
                : null;
        if (aDate == null && bDate == null) return 0;
        if (aDate == null) return isAscending ? 1 : -1;
        if (bDate == null) return isAscending ? -1 : 1;
        return isAscending ? aDate.compareTo(bDate) : bDate.compareTo(aDate);
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final selectedCardColor =
        (selectedCard == null || selectedCard!.spendingGoal == null)
            ? const Color.fromRGBO(247, 247, 249, 1)
            : statusColor;

    return Scaffold(
      backgroundColor: const Color.fromRGBO(247, 247, 249, 1),
      appBar: AppBar(
        backgroundColor: const Color.fromRGBO(247, 247, 249, 1),
        title: Row(
          children: [
            Image.asset('assets/icon/appBarIcon.png', width: 53, height: 53),
            const Spacer(),
            IconButton(
              icon: const Icon(Icons.notifications_none),
              onPressed: () {
                // TODO: 알림 페이지 이동
              },
            ),
            IconButton(
              icon: const Icon(Icons.settings_outlined),
              onPressed: () {
                // TODO: 설정 페이지 이동
              },
            ),
          ],
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SpendingStatusDisplay(
            userName: userName,
            monthlyGoal: monthlyGoal,
            todaySpending: todaySpending,
            selectedCard: selectedCard, // 선택된 카드가 있을 경우 전달
          ),
          //TODO: 그래프 카드 완료
          CardSpendingSummary(
            selectedCard: selectedCard,
            todaySpending: todaySpending,
            monthlyGoal: monthlyGoal,
            statusColor: statusColor,
            userId: FirebaseAuth.instance.currentUser?.uid ?? '',
            registerCards: registerCards,
            onGoalSaved: (updatedCard) {
              setState(() {
                selectedCard = updatedCard;
                int idx = registerCards.indexWhere(
                  (c) => c.id == updatedCard.id,
                );
                if (idx != -1) registerCards[idx] = updatedCard;
              });

              _calculateStatus(); // ✅ 이거 꼭 추가
            },
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
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
                        // 가격 정렬 버튼
                        OutlinedButton(
                          onPressed: () {
                            setState(() {
                              if (selectedSort == SortType.price) {
                                isAscending = !isAscending;
                              } else {
                                selectedSort = SortType.price;
                                isAscending = false;
                              }

                              if (selectedCard == null) {
                                // 전체 카드 정렬
                                registerCards.sort(
                                  (a, b) =>
                                      isAscending
                                          ? a.totalAmount.compareTo(
                                            b.totalAmount,
                                          )
                                          : b.totalAmount.compareTo(
                                            a.totalAmount,
                                          ),
                                );
                                print('✅ 전체 카드 가격 정렬 완료');
                              } else {
                                // 선택된 카드 지출 정렬
                                final sortedExpenses =
                                    List<Map<String, dynamic>>.from(
                                      selectedCard!.expenses,
                                    )..sort(
                                      (a, b) =>
                                          isAscending
                                              ? (a['price'] as int).compareTo(
                                                b['price'] as int,
                                              )
                                              : (b['price'] as int).compareTo(
                                                a['price'] as int,
                                              ),
                                    );

                                selectedCard = selectedCard!.copyWith(
                                  expenses: sortedExpenses,
                                );
                                print('✅ 상세 카드 지출 가격 정렬 완료');
                              }
                            });
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
                                selectedSort == SortType.price
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
                                selectedSort == SortType.price
                                    ? (isAscending
                                        ? Icons.arrow_upward
                                        : Icons.arrow_downward)
                                    : Icons.arrow_downward,
                                size: 18,
                                color:
                                    selectedSort == SortType.price
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
                            setState(() {
                              if (selectedSort == SortType.date) {
                                isAscending = !isAscending;
                              } else {
                                selectedSort = SortType.date;
                                isAscending = false;
                              }

                              if (selectedCard == null) {
                                registerCards.sort((a, b) {
                                  DateTime? aDate =
                                      a.expenses.isNotEmpty &&
                                              a.expenses.last['date'] != null
                                          ? DateTime.tryParse(
                                            a.expenses.last['date'],
                                          )
                                          : null;
                                  DateTime? bDate =
                                      b.expenses.isNotEmpty &&
                                              b.expenses.last['date'] != null
                                          ? DateTime.tryParse(
                                            b.expenses.last['date'],
                                          )
                                          : null;

                                  if (aDate == null && bDate == null) return 0;
                                  if (aDate == null)
                                    return isAscending ? 1 : -1;
                                  if (bDate == null)
                                    return isAscending ? -1 : 1;
                                  return isAscending
                                      ? aDate.compareTo(bDate)
                                      : bDate.compareTo(aDate);
                                });
                                print('✅ 전체 카드 날짜 정렬 완료');
                              } else {
                                final sortedExpenses = List<
                                  Map<String, dynamic>
                                >.from(selectedCard!.expenses)..sort((a, b) {
                                  DateTime? aDate = DateTime.tryParse(
                                    a['date'] ?? '',
                                  );
                                  DateTime? bDate = DateTime.tryParse(
                                    b['date'] ?? '',
                                  );

                                  if (aDate == null && bDate == null) return 0;
                                  if (aDate == null)
                                    return isAscending ? 1 : -1;
                                  if (bDate == null)
                                    return isAscending ? -1 : 1;
                                  return isAscending
                                      ? aDate.compareTo(bDate)
                                      : bDate.compareTo(aDate);
                                });

                                selectedCard = selectedCard!.copyWith(
                                  expenses: sortedExpenses,
                                );
                                print('✅ 상세 카드 지출 날짜 정렬 완료');
                              }
                            });
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
                                selectedSort == SortType.date
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
                                selectedSort == SortType.date
                                    ? (isAscending
                                        ? Icons.arrow_upward
                                        : Icons.arrow_downward)
                                    : Icons.arrow_downward,
                                size: 18,
                                color:
                                    selectedSort == SortType.date
                                        ? Colors.black
                                        : Colors.grey,
                              ),
                            ],
                          ),
                        ),

                        const Spacer(),

                        // 수정 버튼
                        OutlinedButton(
                          onPressed: () async {
                            if (!isEditing) {
                              setState(() {
                                isEditing = true;
                                _shakeController.repeat(reverse: true);
                              });
                            } else {
                              for (int i = 0; i < registerCards.length; i++) {
                                final card = registerCards[i];
                                if (card.name.trim().isEmpty) continue;

                                final updatedCard = card.copyWith(
                                  name: card.name.trim(),
                                );

                                try {
                                  await _registerCardRepo.updateRegisterCard(
                                    updatedCard,
                                  );

                                  setState(() {
                                    registerCards[i] = updatedCard;
                                    if (selectedCard?.id == updatedCard.id) {
                                      selectedCard = updatedCard;
                                    }
                                  });
                                } catch (e) {
                                  print('🔥 Firestore 업데이트 실패: $e');
                                }
                              }

                              setState(() {
                                isEditing = false;
                                _shakeController.stop();
                              });
                            }
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
                          child: Text(isEditing ? '완료' : '수정'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.all(0),
                        child: PageView(
                          controller: pageController,
                          physics: NeverScrollableScrollPhysics(),
                          children: [
                            // TODO:  등록카드 그리드 완료
                            Container(
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
                                  ...registerCards.asMap().entries.map((entry) {
                                    int index = entry.key;
                                    RegisterCardModel card = entry.value;
                                    return AnimatedBuilder(
                                      animation: _shakeAnimation,
                                      builder: (context, child) {
                                        return Transform.rotate(
                                          angle:
                                              isEditing
                                                  ? _shakeAnimation.value * 0.01
                                                  : 0,
                                          child: child,
                                        );
                                      },
                                      child: GestureDetector(
                                        onTap: () {
                                          setState(() {
                                            selectedCard = registerCards[index];
                                            currentPageIndex = 1;
                                          });
                                          _calculateStatus();

                                          pageController.animateToPage(
                                            1,
                                            duration: Duration(
                                              milliseconds: 300,
                                            ),
                                            curve: Curves.easeInOut,
                                          );
                                        },
                                        child: Container(
                                          padding: const EdgeInsets.all(12),
                                          decoration: BoxDecoration(
                                            color:
                                                card.spendingGoal == null
                                                    ? const Color.fromRGBO(
                                                      247,
                                                      247,
                                                      249,
                                                      1,
                                                    )
                                                    : calculateSpendingStatus(
                                                      monthlyGoal:
                                                          card.spendingGoal!,
                                                      todaySpending:
                                                          card.totalAmount,
                                                    ).color,
                                            borderRadius: BorderRadius.circular(
                                              16,
                                            ),
                                          ),
                                          alignment: Alignment.topLeft,
                                          child: Stack(
                                            clipBehavior: Clip.none,
                                            children: [
                                              Positioned.fill(
                                                child: Align(
                                                  alignment: Alignment.topLeft,
                                                  child:
                                                      isEditing
                                                          ? Padding(
                                                            padding:
                                                                const EdgeInsets.only(
                                                                  right: 36.0,
                                                                ),
                                                            child: IntrinsicWidth(
                                                              child: TextFormField(
                                                                initialValue:
                                                                    card.name,
                                                                onChanged: (
                                                                  value,
                                                                ) {
                                                                  setState(() {
                                                                    registerCards[index] = RegisterCardModel(
                                                                      id: card.id,
                                                                      name:
                                                                          value,
                                                                      totalAmount:
                                                                          card.totalAmount,
                                                                      expenses:
                                                                          card.expenses,
                                                                      spendingGoal:
                                                                          card.spendingGoal, // ✅ 이거 추가해야 기존 값 유지됨
                                                                    );
                                                                  });
                                                                },
                                                                decoration: const InputDecoration(
                                                                  isDense: true,
                                                                  isCollapsed:
                                                                      true,
                                                                  enabledBorder: UnderlineInputBorder(
                                                                    borderSide: BorderSide(
                                                                      color:
                                                                          Colors
                                                                              .black38,
                                                                      width:
                                                                          1.5,
                                                                    ),
                                                                  ),
                                                                  focusedBorder: UnderlineInputBorder(
                                                                    borderSide:
                                                                        BorderSide(
                                                                          color:
                                                                              Colors.black87,
                                                                          width:
                                                                              2,
                                                                        ),
                                                                  ),
                                                                  contentPadding:
                                                                      EdgeInsets.only(
                                                                        bottom:
                                                                            4,
                                                                      ),
                                                                ),
                                                                style: const TextStyle(
                                                                  fontSize: 16,
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .bold,
                                                                ),
                                                              ),
                                                            ),
                                                          )
                                                          : Stack(
                                                            children: [
                                                              Align(
                                                                alignment:
                                                                    Alignment
                                                                        .topLeft,
                                                                child: Text(
                                                                  card.name,
                                                                  style: const TextStyle(
                                                                    fontSize:
                                                                        16,
                                                                    fontWeight:
                                                                        FontWeight
                                                                            .bold,
                                                                  ),
                                                                ),
                                                              ),
                                                              Positioned(
                                                                bottom: 0,
                                                                right: 0,
                                                                child: Text(
                                                                  '${card.totalAmount}원',
                                                                  style: const TextStyle(
                                                                    fontSize:
                                                                        12,
                                                                    color:
                                                                        Colors
                                                                            .black,
                                                                  ),
                                                                ),
                                                              ),
                                                            ],
                                                          ),
                                                ),
                                              ),
                                              if (isEditing)
                                                Positioned(
                                                  top: -5,
                                                  right: -5,
                                                  child: GestureDetector(
                                                    onTap: () {
                                                      setState(() {
                                                        registerCards.removeAt(
                                                          index,
                                                        );
                                                      });
                                                    },
                                                    child: Container(
                                                      width: 20,
                                                      height: 20,
                                                      decoration: BoxDecoration(
                                                        color: Colors.red[200],
                                                        shape: BoxShape.circle,
                                                        boxShadow: [
                                                          BoxShadow(
                                                            color:
                                                                Colors.black12,
                                                            blurRadius: 4,
                                                            offset: Offset(
                                                              0,
                                                              0,
                                                            ),
                                                          ),
                                                        ],
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
                                    onTap: _showAddCategoryDialog,
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: Color.fromRGBO(247, 247, 249, 1),
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      child: const Center(
                                        child: Icon(
                                          Icons.add,
                                          size: 48,
                                          color: Colors.grey,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            // TODO: 두 번째 페이지: 선택된 카드 상세 UI (예: 지출 추가 폼)
                            selectedCard == null
                                ? Container(
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                )
                                : Container(
                                  decoration: BoxDecoration(
                                    color:
                                        selectedCard!.spendingGoal == null
                                            ? const Color.fromRGBO(
                                              247,
                                              247,
                                              249,
                                              1,
                                            )
                                            : statusColor,
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  padding: const EdgeInsets.all(0),
                                  child: Builder(
                                    builder: (_) {
                                      return Column(
                                        children: [
                                          // Top bar with back button and title
                                          Row(
                                            children: [
                                              IconButton(
                                                icon: const Icon(
                                                  Icons.arrow_back,
                                                ),
                                                onPressed: () {
                                                  pageController.animateToPage(
                                                    0,
                                                    duration: const Duration(
                                                      milliseconds: 300,
                                                    ),
                                                    curve: Curves.easeInOut,
                                                  );
                                                  setState(() {
                                                    currentPageIndex = 0;
                                                    selectedCard = null;
                                                    registerCards.sort(
                                                      (a, b) => b.totalAmount
                                                          .compareTo(
                                                            a.totalAmount,
                                                          ),
                                                    );
                                                  });
                                                  _calculateStatus();
                                                },
                                              ),
                                              Expanded(
                                                child: Center(
                                                  child: Text(
                                                    selectedCard?.name ??
                                                        '선택된 카드 없음',
                                                    style: const TextStyle(
                                                      fontSize: 18,
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                              IconButton(
                                                icon: const Icon(Icons.add),
                                                onPressed: () {
                                                  String expenseName = '';
                                                  String expensePrice = '';

                                                  showDialog(
                                                    context: context,
                                                    builder: (
                                                      BuildContext context,
                                                    ) {
                                                      return AlertDialog(
                                                        title: const Text(
                                                          '지출 추가',
                                                        ),
                                                        content: Column(
                                                          mainAxisSize:
                                                              MainAxisSize.min,
                                                          children: [
                                                            TextField(
                                                              decoration:
                                                                  const InputDecoration(
                                                                    labelText:
                                                                        '지출 항목 이름',
                                                                  ),
                                                              onChanged: (
                                                                value,
                                                              ) {
                                                                expenseName =
                                                                    value;
                                                              },
                                                            ),
                                                            TextField(
                                                              decoration:
                                                                  const InputDecoration(
                                                                    labelText:
                                                                        '금액',
                                                                  ),
                                                              keyboardType:
                                                                  TextInputType
                                                                      .number,
                                                              onChanged: (
                                                                value,
                                                              ) {
                                                                expensePrice =
                                                                    value;
                                                              },
                                                            ),
                                                          ],
                                                        ),
                                                        actions: [
                                                          TextButton(
                                                            onPressed:
                                                                () =>
                                                                    Navigator.of(
                                                                      context,
                                                                    ).pop(),
                                                            child: const Text(
                                                              '취소',
                                                            ),
                                                          ),
                                                          TextButton(
                                                            onPressed: () async {
                                                              if (expenseName
                                                                      .trim()
                                                                      .isNotEmpty &&
                                                                  int.tryParse(
                                                                        expensePrice,
                                                                      ) !=
                                                                      null &&
                                                                  selectedCard !=
                                                                      null) {
                                                                final newExpense = {
                                                                  'name':
                                                                      expenseName
                                                                          .trim(),
                                                                  'price':
                                                                      int.parse(
                                                                        expensePrice,
                                                                      ),
                                                                  'date':
                                                                      DateTime.now()
                                                                          .toIso8601String(),
                                                                };

                                                                final updatedExpenses = List<
                                                                  Map<
                                                                    String,
                                                                    dynamic
                                                                  >
                                                                >.from(
                                                                  selectedCard!
                                                                      .expenses,
                                                                )..add(
                                                                  newExpense,
                                                                );

                                                                final updatedTotal =
                                                                    updatedExpenses.fold<
                                                                      int
                                                                    >(
                                                                      0,
                                                                      (
                                                                        sum,
                                                                        item,
                                                                      ) =>
                                                                          sum +
                                                                          (item['price']
                                                                              as int),
                                                                    );

                                                                final updatedCard = RegisterCardModel(
                                                                  id:
                                                                      selectedCard!
                                                                          .id,
                                                                  name:
                                                                      selectedCard!
                                                                          .name,
                                                                  expenses:
                                                                      updatedExpenses,
                                                                  totalAmount:
                                                                      updatedTotal,
                                                                  spendingGoal:
                                                                      selectedCard!
                                                                          .spendingGoal,
                                                                );

                                                                try {
                                                                  await _registerCardRepo
                                                                      .updateRegisterCard(
                                                                        updatedCard,
                                                                      );
                                                                  setState(() {
                                                                    selectedCard =
                                                                        updatedCard;
                                                                    int
                                                                    idx = registerCards.indexWhere(
                                                                      (card) =>
                                                                          card.id ==
                                                                          updatedCard
                                                                              .id,
                                                                    );
                                                                    if (idx !=
                                                                        -1) {
                                                                      registerCards[idx] =
                                                                          updatedCard;
                                                                    }
                                                                    todaySpending =
                                                                        RegisterCardModel.calculateTotalSpending(
                                                                          registerCards,
                                                                        );
                                                                  });
                                                                  Navigator.of(
                                                                    context,
                                                                  ).pop();
                                                                } catch (e) {
                                                                  print(
                                                                    '❌ Firestore 저장 실패: $e',
                                                                  );
                                                                  Navigator.of(
                                                                    context,
                                                                  ).pop();
                                                                }
                                                              }
                                                            },
                                                            child: const Text(
                                                              '추가',
                                                            ),
                                                          ),
                                                        ],
                                                      );
                                                    },
                                                  );
                                                },
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 12),
                                          Expanded(
                                            child: ListView(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 0,
                                                    vertical: 12,
                                                  ),
                                              children: [
                                                if (selectedCard != null)
                                                  ...selectedCard!.expenses.map((
                                                    expense,
                                                  ) {
                                                    return ListTile(
                                                      title: Text(
                                                        expense['name'],
                                                      ),
                                                      trailing: Text(
                                                        '${expense['price']}원',
                                                      ),
                                                    );
                                                  }).toList(),
                                              ],
                                            ),
                                          ),
                                        ],
                                      );
                                    },
                                  ),
                                ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: Colors.white,
        currentIndex: _selectedIndex,
        selectedItemColor: const Color.fromRGBO(142, 198, 230, 1),
        unselectedItemColor: Colors.grey,
        onTap: _onItemTapped,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.list), label: '리스트'),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_today),
            label: '캘린더',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.home), label: '홈'),
          BottomNavigationBarItem(icon: Icon(Icons.show_chart), label: '그래프'),
          BottomNavigationBarItem(
            icon: Icon(Icons.notifications_none),
            label: '알림',
          ),
        ],
      ),
    );
  }
}

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
import 'widgets/card_spending_detail_grid.dart';
import 'calendar_page.dart';
import 'home_content.dart'; // <-- Add this import for HomeContent
import 'graph_page.dart';
import 'notification_page.dart';
import 'user_page.dart';
import 'list_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

enum SortType { price, date }

class _HomePageState extends State<HomePage> with TickerProviderStateMixin {
  int monthlyGoal = 0;
  int todaySpending = 0;
  late AnimationController _shakeController;

  int _selectedIndex = 2; // 홈이 기본 선택된 탭
  late PageController _pageController;

  int currentPageIndex = 0;
  PageController pageController = PageController();
  RegisterCardModel? selectedCard;
  bool isEditing = false;
  String userName = '';
  String? photoUrl;
  String spendingStatus = '절약'; // 절약, 평균, 과소비 중 하나
  Color statusColor = Colors.green; // 절약: 초록, 평균: 파랑, 과소비: 빨강

  SortType selectedSort = SortType.price;
  bool isAscending = false;

  late final RegisterCardRepository _registerCardRepo;

  // List<String> categories => List<RegisterCardModel> registerCards 로 변경
  List<RegisterCardModel> registerCards = [];
  late final Animation<double> _shakeAnimation;

  @override
  void initState() {
    super.initState();
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      userName = user.displayName ?? '';
      photoUrl = user.photoURL;
      _registerCardRepo = RegisterCardRepository(userId: user.uid);
    } else {
      _registerCardRepo = RegisterCardRepository(userId: '');
    }

    _pageController = PageController(initialPage: _selectedIndex);
    registerCards.sort((a, b) => b.totalAmount.compareTo(a.totalAmount));

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

    // Load user goals, then status
    _loadUserGoals().then((_) {
      _calculateStatus();
    });
    _loadRegisterCards();
  }

  Future<void> _loadUserGoals() async {
    print('🔵 _loadUserGoals: Loading user goals...');
    try {
      final goals = await _registerCardRepo.fetchUserGoals();
      // Fetch defaultGoal from Firestore and assign to monthlyGoal
      setState(() {
        monthlyGoal = goals['defaultGoal'] ?? goals['monthlyGoal'] ?? 0;
      });
      await _calculateStatus();
    } catch (e) {}
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _loadRegisterCards() async {
    try {
      final cards = await _registerCardRepo.fetchRegisterCards();
      // Calculate the sum of totalAmount from all registerCards
      int totalSpending = cards.fold<int>(
        0,
        (sum, card) => sum + (card.totalAmount ?? 0),
      );
      setState(() {
        registerCards = cards;
        registerCards.sort((a, b) => b.totalAmount.compareTo(a.totalAmount));
        todaySpending = totalSpending;
      });
      print('Firestore 등록카드 로드 완료, 개수: ${cards.length}');
      print('✅ todaySpending calculated from registerCards: $todaySpending');
      await _calculateStatus();
    } catch (e) {
      print('Firestore 등록카드 로드 실패: $e');
    }
  }

  void _onItemTapped(int index) {
    if (index == 1) {
      // 캘린더 페이지로 이동
      Navigator.push(
        context,
        MaterialPageRoute(
          builder:
              (context) => CalendarPage(
                registerCards: registerCards,
                monthlyGoal: monthlyGoal,
              ),
        ),
      );
    } else {
      setState(() {
        _selectedIndex = index;
      });
    }
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

  Future<void> _calculateStatus() async {
    final result = await calculateStatusFromCard(
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
      if (selectedCard == null) {
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
      } else {
        // selectedCard.expenses 날짜 정렬
        final sortedExpenses = List<Map<String, dynamic>>.from(
          selectedCard!.expenses,
        )..sort((a, b) {
          DateTime? aDate = DateTime.tryParse(a['date'] ?? '');
          DateTime? bDate = DateTime.tryParse(b['date'] ?? '');
          if (aDate == null && bDate == null) return 0;
          if (aDate == null) return isAscending ? 1 : -1;
          if (bDate == null) return isAscending ? -1 : 1;
          return isAscending ? aDate.compareTo(bDate) : bDate.compareTo(aDate);
        });
        selectedCard = selectedCard!.copyWith(expenses: sortedExpenses);
      }
    });
  }

  // HomePage 내부에 지출 추가 함수 구현
  void _showAddExpenseDialog() {
    String expenseName = '';
    String expensePrice = '';

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('지출 추가'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                decoration: const InputDecoration(labelText: '지출 항목 이름'),
                onChanged: (value) => expenseName = value,
              ),
              TextField(
                decoration: const InputDecoration(labelText: '금액'),
                keyboardType: TextInputType.number,
                onChanged: (value) => expensePrice = value,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('취소'),
            ),
            TextButton(
              onPressed: () async {
                if (expenseName.trim().isNotEmpty &&
                    int.tryParse(expensePrice) != null &&
                    selectedCard != null) {
                  final newExpense = {
                    'name': expenseName.trim(),
                    'price': int.parse(expensePrice),
                    'date': DateTime.now().toIso8601String(),
                  };

                  final updatedExpenses = List<Map<String, dynamic>>.from(
                    selectedCard!.expenses,
                  )..add(newExpense);
                  final updatedTotal = updatedExpenses.fold<int>(
                    0,
                    (sum, e) => sum + (e['price'] as int),
                  );

                  final updatedCard = selectedCard!.copyWith(
                    expenses: updatedExpenses,
                    totalAmount: updatedTotal,
                  );

                  try {
                    await _registerCardRepo.updateRegisterCard(updatedCard);
                    setState(() {
                      selectedCard = updatedCard;
                      int idx = registerCards.indexWhere(
                        (c) => c.id == updatedCard.id,
                      );
                      if (idx != -1) registerCards[idx] = updatedCard;

                      // ✅ Update status color after adding expense
                      statusColor =
                          calculateSpendingStatus(
                            monthlyGoal:
                                updatedCard.spendingGoal ?? monthlyGoal,
                            todaySpending: updatedCard.totalAmount,
                          ).color;
                    });
                    Navigator.of(context).pop();
                  } catch (e) {
                    print('Firestore 저장 실패: $e');
                    Navigator.of(context).pop();
                  }
                }
              },
              child: const Text('추가'),
            ),
          ],
        );
      },
    );
  }

  @override
  @override
  Widget build(BuildContext context) {
    final titles = ['리스트', '캘린더', '홈', '그래프', '알림'];

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
                setState(() {
                  _selectedIndex = 4;
                  _pageController.jumpToPage(4);
                });
              },
            ),
            IconButton(
              icon: const Icon(Icons.settings_outlined),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const UserPage()),
                );
              },
            ),
          ],
        ),
      ),
      body: PageView(
        controller: _pageController,
        onPageChanged: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        children: [
          ListPage(),
          CalendarPage(registerCards: registerCards, monthlyGoal: monthlyGoal),
          HomeContent(
            registerCardRepo: _registerCardRepo,
            userName: userName,
            monthlyGoal: monthlyGoal,
            todaySpending: todaySpending,
            selectedCard: selectedCard,
            statusColor: statusColor,
            registerCards: registerCards,
            isEditing: isEditing,
            onEditingChanged: (bool editing) {
              setState(() {
                isEditing = editing;
                if (isEditing) {
                  _shakeController.repeat(reverse: true);
                } else {
                  _shakeController.stop();
                }
              });
            },
            onGoalSaved: (RegisterCardModel updatedCard) {
              setState(() {
                selectedCard = updatedCard;
                int idx = registerCards.indexWhere(
                  (c) => c.id == updatedCard.id,
                );
                if (idx != -1) registerCards[idx] = updatedCard;
              });
              _calculateStatus();
            },
            onCardDeleted: (int index) async {
              final cardId = registerCards[index].id;
              try {
                await _registerCardRepo.deleteRegisterCard(
                  cardId,
                ); // Firestore 삭제 요청
                setState(() {
                  registerCards.removeAt(index); // UI 상태에서 카드 제거
                  if (selectedCard?.id == cardId) {
                    selectedCard = null; // 삭제된 카드가 선택된 카드면 해제
                  }
                });
                print('✅ Firestore에서 카드 삭제 성공');
              } catch (e) {
                print('🔥 Firestore 카드 삭제 실패: $e');
              }
            },
            onCardSelected: (RegisterCardModel card) {
              setState(() {
                selectedCard = card;
                currentPageIndex = 1;
                pageController.animateToPage(
                  1,
                  duration: Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                );
              });
              _calculateStatus();
            },
            onShowAddCategoryDialog: _showAddCategoryDialog,
            onAddExpense: _showAddExpenseDialog,
            pageController: pageController,
            currentPageIndex: currentPageIndex,
            onBackToCardGrid: (int pageIndex) {
              setState(() {
                currentPageIndex = pageIndex;
                if (pageIndex == 0) selectedCard = null;
              });
              _calculateStatus(); // ✅ Update total spending and status
              pageController.animateToPage(
                pageIndex,
                duration: Duration(milliseconds: 300),
                curve: Curves.easeInOut,
              );
            },
            selectedSort: selectedSort,
            isAscending: isAscending,
            onSortToggle: (SortType sortType) {
              setState(() {
                if (selectedSort == sortType) {
                  isAscending = !isAscending;
                } else {
                  selectedSort = sortType;
                  isAscending = false;
                }
                if (selectedSort == SortType.price) {
                  togglePriceSort();
                } else {
                  toggleDateSort();
                }
              });
            },
            shakeAnimation: _shakeAnimation,
            onExpenseDeleted: (int index) async {
              if (selectedCard == null) return;

              final updatedExpenses = List<Map<String, dynamic>>.from(
                selectedCard!.expenses,
              )..removeAt(index);
              final updatedTotal = updatedExpenses.fold<int>(
                0,
                (sum, e) => sum + (e['price'] as int),
              );
              final updatedCard = selectedCard!.copyWith(
                expenses: updatedExpenses,
                totalAmount: updatedTotal,
              );

              try {
                await _registerCardRepo.updateRegisterCard(updatedCard);
                setState(() {
                  selectedCard = updatedCard;
                  final idx = registerCards.indexWhere(
                    (c) => c.id == updatedCard.id,
                  );
                  if (idx != -1) registerCards[idx] = updatedCard;
                });
                _calculateStatus();
              } catch (e) {
                print('🔥 Firestore 지출 삭제 실패: $e');
              }
            },
            onExpenseNameChanged: (int index, String newName) async {
              if (selectedCard == null) return;

              final updatedExpenses = List<Map<String, dynamic>>.from(
                selectedCard!.expenses,
              );
              updatedExpenses[index]['name'] = newName;

              final updatedCard = selectedCard!.copyWith(
                expenses: updatedExpenses,
              );

              try {
                await _registerCardRepo.updateRegisterCard(updatedCard);
                setState(() {
                  selectedCard = updatedCard;
                  final idx = registerCards.indexWhere(
                    (c) => c.id == updatedCard.id,
                  );
                  if (idx != -1) registerCards[idx] = updatedCard;
                });
                print('✅ Firestore에 지출 이름 수정됨');
              } catch (e) {
                print('🔥 Firestore 지출 이름 수정 실패: $e');
              }
            },
          ),
          GraphPage(registerCards: registerCards),
          NotificationPage(),
        ],
      ),

      // 기존 바텀바 코드 유지
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: Colors.white,
        currentIndex: _selectedIndex,
        selectedItemColor: const Color.fromRGBO(142, 198, 230, 1),
        unselectedItemColor: Colors.grey,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
          _pageController.animateToPage(
            index,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
          );
        },
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

// lib/home.dart
import 'package:flutter/material.dart';
import 'state/app_state.dart';
import 'utils/spending_calculator.dart';
import 'model/register_card_model.dart';
import 'utils/status_utils.dart';
import 'calendar_page.dart';
import 'home_content.dart'; // <-- Add this import for HomeContent
import 'graph_page.dart';
import 'notification_page.dart';
import 'user_page.dart';
import 'list_page.dart';
import 'package:provider/provider.dart';
import '../state/app_state.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

enum SortType { price, date }

class _HomePageState extends State<HomePage> with TickerProviderStateMixin {
  late AnimationController _shakeController;

  int _selectedIndex = 2; // 홈이 기본 선택된 탭
  late PageController _pageController;

  int currentPageIndex = 0;
  PageController pageController = PageController();
  bool isEditing = false;
  String userName = '';
  String? photoUrl;
  String spendingStatus = '절약'; // 절약, 평균, 과소비 중 하나

  SortType selectedSort = SortType.price;
  bool isAscending = false;

  late final Animation<double> _shakeAnimation;

  @override
  void initState() {
    super.initState();

    // Initialize UI related controllers
    _pageController = PageController(initialPage: _selectedIndex);
    _shakeController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    )..repeat(reverse: true);
    _shakeAnimation = Tween<double>(begin: 0.0, end: 2.0).animate(
      CurvedAnimation(parent: _shakeController, curve: Curves.elasticIn),
    );
    _shakeController.stop();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
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
              onPressed: () {
                if (newCategory.trim().isNotEmpty) {
                  final appState = Provider.of<AppState>(
                    context,
                    listen: false,
                  );
                  final newCard = RegisterCardModel(
                    id: DateTime.now().millisecondsSinceEpoch.toString(),
                    name: newCategory.trim(),
                    totalAmount: 0,
                    expenses: [],
                  );
                  final newCards = List<RegisterCardModel>.from(
                    appState.registerCards,
                  )..add(newCard);
                  appState.setRegisterCards(newCards);
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
    final appState = Provider.of<AppState>(context, listen: false);

    if (appState.monthlyGoal == 0) {
      await appState.loadMonthlyGoalFromFirestore();
    }

    final result = await calculateStatusFromCard(context);

    // selectedCard가 null일 때 goal을 registerCards 전체 목표로 세팅
    final int goal =
        result.goal == 0 && appState.selectedCard == null
            ? appState
                .monthlyGoal // appState의 전체 목표 월간 지출 값
            : result.goal;

    appState.setMonthlyGoal(goal);
    appState.setTodaySpending(result.spending);
    spendingStatus = result.status;
    appState.setStatusColor(result.color);

    print(
      '상태 계산됨 ➜ goal: $goal, spending: ${result.spending}, status: ${result.status}',
    );
  }

  void togglePriceSort() {
    final appState = Provider.of<AppState>(context, listen: false);
    if (appState.selectedCard == null) {
      final sorted = List<RegisterCardModel>.from(appState.registerCards)..sort(
        (a, b) =>
            isAscending
                ? a.totalAmount.compareTo(b.totalAmount)
                : b.totalAmount.compareTo(a.totalAmount),
      );
      appState.setRegisterCards(sorted);
    } else {
      final updatedCard = appState.selectedCard!.copyWith(
        expenses: List<Map<String, dynamic>>.from(
          appState.selectedCard!.expenses,
        )..sort(
          (a, b) =>
              isAscending
                  ? (a['price'] as int).compareTo(b['price'] as int)
                  : (b['price'] as int).compareTo(a['price'] as int),
        ),
      );
      appState.selectCard(updatedCard);
    }
  }

  void toggleDateSort() {
    final appState = Provider.of<AppState>(context, listen: false);
    if (appState.selectedCard == null) {
      final sorted = List<RegisterCardModel>.from(appState.registerCards)
        ..sort((a, b) {
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
      appState.setRegisterCards(sorted);
    } else {
      // selectedCard.expenses 날짜 정렬
      final sortedExpenses = List<Map<String, dynamic>>.from(
        appState.selectedCard!.expenses,
      )..sort((a, b) {
        DateTime? aDate = DateTime.tryParse(a['date'] ?? '');
        DateTime? bDate = DateTime.tryParse(b['date'] ?? '');
        if (aDate == null && bDate == null) return 0;
        if (aDate == null) return isAscending ? 1 : -1;
        if (bDate == null) return isAscending ? -1 : 1;
        return isAscending ? aDate.compareTo(bDate) : bDate.compareTo(aDate);
      });
      final updatedCard = appState.selectedCard!.copyWith(
        expenses: sortedExpenses,
      );
      appState.selectCard(updatedCard);
    }
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
              onPressed: () {
                final appState = Provider.of<AppState>(context, listen: false);
                if (expenseName.trim().isNotEmpty &&
                    int.tryParse(expensePrice) != null &&
                    appState.selectedCard != null) {
                  final newExpense = {
                    'name': expenseName.trim(),
                    'price': int.parse(expensePrice),
                    'date': DateTime.now().toIso8601String(),
                  };

                  final updatedExpenses = List<Map<String, dynamic>>.from(
                    appState.selectedCard!.expenses,
                  )..add(newExpense);
                  final updatedTotal = updatedExpenses.fold<int>(
                    0,
                    (sum, e) => sum + (e['price'] as int),
                  );

                  final updatedCard = appState.selectedCard!.copyWith(
                    expenses: updatedExpenses,
                    totalAmount: updatedTotal,
                  );

                  appState.selectCard(updatedCard);
                  final idx = appState.registerCards.indexWhere(
                    (c) => c.id == updatedCard.id,
                  );
                  if (idx != -1) {
                    final newCards = List<RegisterCardModel>.from(
                      appState.registerCards,
                    );
                    newCards[idx] = updatedCard;
                    appState.setRegisterCards(newCards);
                  }
                  // Update status color after adding expense
                  final color =
                      (updatedCard.spendingGoal ?? 0) == 0
                          ? const Color.fromRGBO(247, 247, 249, 1)
                          : calculateSpendingStatus(context).color;
                  appState.setStatusColor(color);
                  Navigator.of(context).pop();
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
    final appState = Provider.of<AppState>(context);

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
          CalendarPage(
            registerCards: appState.registerCards,
            monthlyGoal: appState.monthlyGoal,
          ),
          HomeContent(
            pageController: pageController,
            currentPageIndex: currentPageIndex,
            onBackToCardGrid: (int pageIndex) {
              setState(() {
                currentPageIndex = pageIndex;
              });
              if (pageIndex == 0) appState.selectCard(null);
              _calculateStatus();
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
          ),
          GraphPage(registerCards: appState.registerCards),
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

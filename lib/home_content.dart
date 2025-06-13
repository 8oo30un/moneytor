// lib/home_content.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'model/register_card_model.dart';
import 'widgets/spending_status_display.dart';
import 'widgets/card_spending_summary.dart' as summary;
import 'package:tuple/tuple.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'widgets/card_spending_detail_grid.dart';
import 'utils/spending_calculator.dart' as calc;
import 'state/app_state.dart';
import 'home.dart'; // for SortType enum

class HomeContent extends StatefulWidget {
  final PageController pageController;
  final int currentPageIndex;
  final Function(int) onBackToCardGrid;
  final SortType selectedSort;
  final bool isAscending;
  final Function(SortType) onSortToggle;
  final Animation<double> shakeAnimation;

  const HomeContent({
    Key? key,
    required this.pageController,
    required this.currentPageIndex,
    required this.onBackToCardGrid,
    required this.selectedSort,
    required this.isAscending,
    required this.onSortToggle,
    required this.shakeAnimation,
  }) : super(key: key);

  @override
  _HomeContentState createState() => _HomeContentState();
}

class _HomeContentState extends State<HomeContent> {
  @override
  void initState() {
    super.initState();
    // Provider 초기화
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AppState>().initialize();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppState>(
      builder: (context, appState, child) {
        if (appState.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1) SpendingStatusDisplay (Selector)
            Selector<
              AppState,
              Tuple6<
                String,
                int,
                int,
                RegisterCardModel?,
                List<RegisterCardModel>,
                int
              >
            >(
              selector:
                  (_, appState) => Tuple6(
                    appState.userName,
                    appState.monthlyGoal,
                    appState.todaySpending,
                    appState.selectedCard,
                    appState.registerCards,
                    appState.totalSpending,
                  ),
              builder: (context, data, child) {
                final userName = data.item1;
                final monthlyGoal = data.item2;
                final todaySpending = data.item3;
                final selectedCard = data.item4;
                final registerCards = data.item5;
                final totalSpending = data.item6;

                return SpendingStatusDisplay(
                  userName: userName,
                  monthlyGoal: monthlyGoal,
                  todaySpending: todaySpending,
                  selectedCard: selectedCard,
                  registerCards: registerCards,
                  totalSpending: totalSpending,
                );
              },
            ),

            // 2) CardSpendingSummary (Selector)
            Selector<AppState, Tuple4<RegisterCardModel?, int, int, Color>>(
              selector:
                  (_, appState) => Tuple4(
                    appState.selectedCard,
                    appState.todaySpending,
                    appState.monthlyGoal,
                    appState.statusColor,
                  ),
              builder: (context, data, child) {
                final selectedCard = data.item1;
                final todaySpending = data.item2;
                final monthlyGoal = data.item3;
                final statusColor = data.item4;

                return summary.CardSpendingSummary(
                  selectedCard: selectedCard,
                  todaySpending: todaySpending,
                  monthlyGoal: monthlyGoal,
                  statusColor: statusColor,
                  registerCards: context.read<AppState>().registerCards,
                  userId: FirebaseAuth.instance.currentUser?.uid ?? '',
                  onDefaultGoalChanged: (goal) {
                    context.read<AppState>().setDefaultGoal(goal, context);
                  },
                );
              },
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
                      _buildControlButtons(appState),
                      const SizedBox(height: 16),

                      // PageView (카드 그리드, 카드 상세)
                      Expanded(
                        child: PageView(
                          controller: widget.pageController,
                          physics: const NeverScrollableScrollPhysics(),
                          children: [
                            // 3-1) 카드 그리드 페이지
                            _buildCardGrid(appState),
                            // 3-2) 카드 상세 페이지
                            _buildCardDetail(context, appState),
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
      },
    );
  }

  Widget _buildControlButtons(AppState appState) {
    return Row(
      children: [
        // 가격 정렬 버튼
        _buildSortButton(
          '가격',
          SortType.price,
          widget.selectedSort == SortType.price,
        ),
        const SizedBox(width: 8),

        // 날짜 정렬 버튼
        _buildSortButton(
          '날짜',
          SortType.date,
          widget.selectedSort == SortType.date,
        ),

        const Spacer(),

        // 수정 버튼
        OutlinedButton(
          onPressed: () {
            appState.toggleEditing();
          },
          style: OutlinedButton.styleFrom(
            minimumSize: const Size(60, 36),
            backgroundColor: const Color.fromRGBO(247, 247, 249, 1),
            foregroundColor: Colors.black,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 0,
            side: BorderSide.none,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          ),
          child: Text(appState.isEditing ? '완료' : '수정'),
        ),
      ],
    );
  }

  Widget _buildSortButton(String text, SortType sortType, bool isSelected) {
    return OutlinedButton(
      onPressed: () => widget.onSortToggle(sortType),
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(80, 36),
        backgroundColor: const Color.fromRGBO(247, 247, 249, 1),
        foregroundColor: isSelected ? Colors.black : Colors.grey,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 0,
        side: BorderSide.none,
        padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(text),
          const SizedBox(width: 4),
          Icon(
            isSelected
                ? (widget.isAscending
                    ? Icons.arrow_upward
                    : Icons.arrow_downward)
                : Icons.arrow_downward,
            size: 18,
            color: isSelected ? Colors.black : Colors.grey,
          ),
        ],
      ),
    );
  }

  Widget _buildCardGrid(AppState appState) {
    return GridView.count(
      crossAxisCount: 2,
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      childAspectRatio: 1.25,
      children: [
        ...appState.registerCards.asMap().entries.map((entry) {
          int index = entry.key;
          RegisterCardModel card = entry.value;

          return AnimatedBuilder(
            animation: widget.shakeAnimation,
            builder: (context, child) {
              return Transform.rotate(
                angle:
                    appState.isEditing ? widget.shakeAnimation.value * 0.01 : 0,
                child: child,
              );
            },
            child: _buildCardItem(card, index, appState),
          );
        }).toList(),

        // 카드 추가 버튼
        GestureDetector(
          onTap: () => _showAddCategoryDialog(appState),
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
    );
  }

  Widget _buildCardItem(RegisterCardModel card, int index, AppState appState) {
    final status = appState.getCardStatus(card.id);
    final color = appState.getCardStatusColor(card.id);

    return GestureDetector(
      onTap: () {
        appState.selectCard(card);
        widget.pageController.animateToPage(
          1,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned.fill(
              child: Align(
                alignment: Alignment.topLeft,
                child:
                    appState.isEditing
                        ? _buildEditableCardName(card, appState)
                        : _buildCardContent(card),
              ),
            ),
            if (appState.isEditing)
              Positioned(
                top: -5,
                right: -5,
                child: GestureDetector(
                  onTap: () => appState.deleteCard(index, context),
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
    );
  }

  Widget _buildEditableCardName(RegisterCardModel card, AppState appState) {
    return Padding(
      padding: const EdgeInsets.only(right: 36.0),
      child: IntrinsicWidth(
        child: TextFormField(
          initialValue: card.name,
          onChanged: (value) {
            appState.updateCardName(card.id, value);
          },
          decoration: const InputDecoration(
            isDense: true,
            isCollapsed: true,
            enabledBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: Colors.black38, width: 1.5),
            ),
            focusedBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: Colors.black87, width: 2),
            ),
            contentPadding: EdgeInsets.only(bottom: 4),
          ),
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _buildCardContent(RegisterCardModel card) {
    return Stack(
      children: [
        Align(
          alignment: Alignment.topLeft,
          child: Text(
            card.name,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ),
        Positioned(
          bottom: 0,
          right: 0,
          child: Text(
            '${card.totalAmount}원',
            style: const TextStyle(fontSize: 12, color: Colors.black),
          ),
        ),
      ],
    );
  }

  Widget _buildCardDetail(BuildContext context, AppState appState) {
    final selectedCard = appState.selectedCard;
    if (selectedCard == null) {
      return Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
      );
    }

    final cardStatusColor = appState.getCardStatusColor(selectedCard.id);

    return Container(
      decoration: BoxDecoration(
        color:
            (selectedCard.spendingGoal ?? 0) == 0
                ? const Color.fromRGBO(247, 247, 249, 1)
                : cardStatusColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 상단 바
            _buildDetailHeader(selectedCard, appState),
            const SizedBox(height: 12),

            // 지출 리스트
            if (selectedCard.expenses.isNotEmpty)
              ..._buildExpenseList(selectedCard, appState),

            // 카드 상세 그리드
            CardSpendingDetailGrid(
              card: selectedCard,
              statusColor: cardStatusColor, // 상세 그리드에도 상태 색상 전달
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailHeader(RegisterCardModel card, AppState appState) {
    return Row(
      children: [
        IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            appState.selectCard(null);
            if (!mounted) return; // mounted 체크

            appState.reloadAllData(
              context,
            ); // 초기 데이터 다시 로드 함수 호출 (필요에 따라 async 처리)
            if (!mounted) return; // mounted 체크

            widget.onBackToCardGrid(0);
          },
        ),
        Expanded(
          child: Center(
            child: Text(
              card.name,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
        ),
        IconButton(
          icon: const Icon(Icons.add),
          onPressed: () => _showAddExpenseDialog(card, appState),
        ),
      ],
    );
  }

  List<Widget> _buildExpenseList(RegisterCardModel card, AppState appState) {
    return card.expenses.asMap().entries.map((entry) {
      final index = entry.key;
      final expense = entry.value;

      return ListTile(
        title:
            appState.isEditing
                ? TextFormField(
                  initialValue: expense['name'],
                  onChanged: (newName) {
                    appState.updateExpenseName(card.id, index, newName);
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
                DateFormat(
                  'M월 d일 HH:mm',
                ).format(DateTime.tryParse(expense['date']) ?? DateTime.now()),
              ),
            if (appState.isEditing)
              IconButton(
                icon: const Icon(Icons.close, size: 18, color: Colors.red),
                onPressed: () {
                  appState.deleteExpense(card.id, index, context);
                },
              ),
          ],
        ),
      );
    }).toList();
  }

  void _showAddCategoryDialog(AppState appState) {
    final controller = TextEditingController();

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('새 카테고리 추가'),
            content: TextField(
              controller: controller,
              decoration: const InputDecoration(hintText: '카테고리 이름'),
              autofocus: true,
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('취소'),
              ),
              TextButton(
                onPressed: () {
                  if (controller.text.isNotEmpty) {
                    appState.addCard(controller.text, context);
                    Navigator.pop(context);
                  }
                },
                child: const Text('추가'),
              ),
            ],
          ),
    );
  }

  void _showAddExpenseDialog(RegisterCardModel card, AppState appState) {
    final nameController = TextEditingController();
    final priceController = TextEditingController();

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('지출 추가'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(hintText: '지출 이름'),
                  autofocus: true,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: priceController,
                  decoration: const InputDecoration(hintText: '금액'),
                  keyboardType: TextInputType.number,
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('취소'),
              ),
              TextButton(
                onPressed: () {
                  if (nameController.text.isNotEmpty &&
                      priceController.text.isNotEmpty) {
                    final price = int.tryParse(priceController.text) ?? 0;
                    appState.addExpense(
                      card.id,
                      nameController.text,
                      price,
                      context,
                    );
                    Navigator.pop(context);
                  }
                },
                child: const Text('추가'),
              ),
            ],
          ),
    );
  }
}

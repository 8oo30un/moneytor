// lib/home.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'utils/spending_calculator.dart';
import 'utils/progress_bar.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

enum SortType { price, date }

class _HomePageState extends State<HomePage>
    with SingleTickerProviderStateMixin {
  int _selectedIndex = 2;

  bool isEditing = false;

  String userName = '';
  String? photoUrl;

  String spendingStatus = '절약'; // 절약, 평균, 과소비 중 하나
  Color statusColor = Colors.green; // 절약: 초록, 평균: 파랑, 과소비: 빨강

  int monthlyGoal = 0;
  int todaySpending = 0;

  SortType selectedSort = SortType.price;
  bool isAscending = false;

  // 카테고리 목록
  List<String> categories = [];

  late final AnimationController _shakeController;
  late final Animation<double> _shakeAnimation;
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
                  setState(() {
                    categories.add(newCategory.trim());
                  });
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

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
    // TODO: 페이지 전환 로직 추가 가능
  }

  void togglePriceSort() {
    setState(() {
      if (selectedSort == SortType.price) {
        isAscending = !isAscending;
      } else {
        selectedSort = SortType.price;
        isAscending = false;
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
    });
  }

  @override
  void initState() {
    super.initState();
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      setState(() {
        userName = user.displayName ?? '';
        photoUrl = user.photoURL;
      });
    }
    // 예시 데이터로 한 달 목표 및 현재 지출 지정
    monthlyGoal = 1000000; // 1,000,000원 목표
    todaySpending = 130000; // 현재까지 250,000원 지출

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
  }

  @override
  void dispose() {
    _shakeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 12.0,
            ),
            child: RichText(
              text: TextSpan(
                style: const TextStyle(fontSize: 20.0, color: Colors.black),
                children: [
                  TextSpan(text: '$userName님,\n'),
                  if (spendingStatus == '평균') ...[
                    const TextSpan(text: '권장지출만큼 '),
                    TextSpan(
                      text: '적절히',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: statusColor,
                      ),
                    ),
                    const TextSpan(text: ' 소비하고 있어요!'),
                  ] else ...[
                    const TextSpan(text: '권장지출보다 '),
                    TextSpan(
                      text: spendingStatus,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: statusColor,
                      ),
                    ),
                    const TextSpan(text: '하고 있어요!'),
                  ],
                ],
              ),
            ),
          ),
          Padding(
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
                  Text(
                    DateFormat('yyyy년 M월 지출').format(DateTime.now()),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const SizedBox(width: 4),
                      BentoLabelBox(label: '월간 지출'),
                      const SizedBox(width: 12),
                      Expanded(
                        child: LabeledProgressBox(
                          progress: todaySpending / monthlyGoal,
                          color: statusColor,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const SizedBox(width: 4),
                      BentoLabelBox(label: '권장 지출'),
                      const SizedBox(width: 12),
                      Expanded(
                        child: LabeledProgressBox(
                          progress:
                              ((monthlyGoal / 30) * DateTime.now().day) /
                              monthlyGoal,
                          color: statusColor.withOpacity(0.6),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
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
                        OutlinedButton(
                          onPressed: togglePriceSort,
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size(80, 36),
                            backgroundColor: Color.fromRGBO(247, 247, 249, 1),
                            foregroundColor:
                                selectedSort == SortType.price
                                    ? Colors.black
                                    : Colors.grey,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 0,
                            side: BorderSide.none,
                            padding: EdgeInsets.symmetric(
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
                        OutlinedButton(
                          onPressed: toggleDateSort,
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size(80, 36),
                            backgroundColor: Color.fromRGBO(247, 247, 249, 1),
                            foregroundColor:
                                selectedSort == SortType.date
                                    ? Colors.black
                                    : Colors.grey,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 0,
                            side: BorderSide.none,
                            padding: EdgeInsets.symmetric(
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
                        OutlinedButton(
                          onPressed: () {
                            setState(() {
                              isEditing = !isEditing;
                              if (isEditing) {
                                _shakeController.repeat(reverse: true);
                              } else {
                                _shakeController.stop();
                              }
                            });
                          },
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size(60, 36),
                            backgroundColor: Color.fromRGBO(247, 247, 249, 1),
                            foregroundColor: Colors.black,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 0,
                            side: BorderSide.none,
                            padding: EdgeInsets.symmetric(
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
                      child: GridView.count(
                        crossAxisCount: 2,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                        childAspectRatio: 1.25, // 가로:세로 비율 2:1
                        children: [
                          ...categories.asMap().entries.map((entry) {
                            int index = entry.key;
                            String category = entry.value;

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
                              child: Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Color.fromRGBO(247, 247, 249, 1),
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
                                            isEditing
                                                ? Padding(
                                                  padding:
                                                      const EdgeInsets.only(
                                                        right: 36.0,
                                                      ),
                                                  child: IntrinsicWidth(
                                                    child: TextFormField(
                                                      initialValue: category,
                                                      onChanged: (value) {
                                                        setState(() {
                                                          categories[index] =
                                                              value;
                                                        });
                                                      },
                                                      decoration: const InputDecoration(
                                                        isDense: true,
                                                        isCollapsed: true,
                                                        enabledBorder:
                                                            UnderlineInputBorder(
                                                              borderSide:
                                                                  BorderSide(
                                                                    color:
                                                                        Colors
                                                                            .black38,
                                                                    width: 1.5,
                                                                  ),
                                                            ),
                                                        focusedBorder:
                                                            UnderlineInputBorder(
                                                              borderSide:
                                                                  BorderSide(
                                                                    color:
                                                                        Colors
                                                                            .black87,
                                                                    width: 2,
                                                                  ),
                                                            ),
                                                        contentPadding:
                                                            EdgeInsets.only(
                                                              bottom: 4,
                                                            ),
                                                      ),
                                                      style: const TextStyle(
                                                        fontSize: 16,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                      ),
                                                    ),
                                                  ),
                                                )
                                                : Text(
                                                  category,
                                                  style: const TextStyle(
                                                    fontSize: 16,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                      ),
                                    ),
                                    if (isEditing)
                                      Positioned(
                                        top: -20,
                                        right: -20,
                                        child: GestureDetector(
                                          onTap: () {
                                            setState(() {
                                              categories.removeAt(index);
                                            });
                                          },
                                          child: Container(
                                            width: 28,
                                            height: 28,
                                            decoration: BoxDecoration(
                                              color: Colors.grey[300],
                                              shape: BoxShape.circle,
                                              boxShadow: [
                                                BoxShadow(
                                                  color: Colors.black12,
                                                  blurRadius: 4,
                                                  offset: Offset(0, 2),
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

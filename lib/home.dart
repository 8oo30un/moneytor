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

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 2;

  String userName = '';
  String? photoUrl;

  String spendingStatus = '절약'; // 절약, 평균, 과소비 중 하나
  Color statusColor = Colors.green; // 절약: 초록, 평균: 파랑, 과소비: 빨강

  int monthlyGoal = 0;
  int todaySpending = 0;

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
    // TODO: 페이지 전환 로직 추가 가능
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
    todaySpending = 60000; // 현재까지 250,000원 지출

    final status = calculateSpendingStatus(
      monthlyGoal: monthlyGoal,
      todaySpending: todaySpending,
    );

    spendingStatus = status.status;
    statusColor = status.color;
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
            child: Text(
              DateFormat('yyyy년 M월 지출').format(DateTime.now()),
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8),
            child: Row(
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
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8),
            child: Row(
              children: [
                const SizedBox(width: 4),
                BentoLabelBox(label: '권장 지출'),
                const SizedBox(width: 12),
                Expanded(
                  child: LabeledProgressBox(
                    progress:
                        ((monthlyGoal / 30) * DateTime.now().day) / monthlyGoal,
                    color: statusColor.withOpacity(0.6),
                  ),
                ),
              ],
            ),
          ),
          const Expanded(
            child: Center(
              child: Text('환영합니다! 로그인 성공 🎉', style: TextStyle(fontSize: 24)),
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

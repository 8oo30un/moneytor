import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class CalendarPage extends StatefulWidget {
  const CalendarPage({super.key});

  @override
  State<CalendarPage> createState() => _CalendarPageState();
}

class _CalendarPageState extends State<CalendarPage> {
  DateTime selectedMonth = DateTime.now();

  void _changeMonth(int offset) {
    setState(() {
      selectedMonth = DateTime(
        selectedMonth.year,
        selectedMonth.month + offset,
      );
    });
  }

  Widget _buildMonthItem(DateTime month, {required bool isSelected}) {
    final monthStr = DateFormat('yyyy.MM').format(month);
    return GestureDetector(
      onTap: () {
        setState(() {
          selectedMonth = month;
        });
      },
      child: Container(
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(vertical: 12.0),
        color: isSelected ? Colors.blue[100] : Colors.transparent,
        child: Text(
          monthStr,
          style: TextStyle(
            fontSize: 16,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildMonthSelector() {
    final months = [
      selectedMonth.subtract(const Duration(days: 30)),
      selectedMonth,
      selectedMonth.add(const Duration(days: 30)),
      selectedMonth.add(const Duration(days: 60)),
    ];

    return Column(
      children:
          months.map((month) {
            return _buildMonthItem(
              month,
              isSelected:
                  month.year == selectedMonth.year &&
                  month.month == selectedMonth.month,
            );
          }).toList(),
    );
  }

  Widget _buildCalendarPlaceholder() {
    return Container(
      color: Colors.grey[200],
      child: Center(
        child: Text(
          '${DateFormat('yyyy.MM').format(selectedMonth)} 달력 영역',
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    return Scaffold(
      appBar: AppBar(title: const Text('캘린더')),
      body: Column(
        children: [
          SizedBox(height: screenHeight * 0.2, child: _buildMonthSelector()),
          SizedBox(
            height: screenHeight * 0.6,
            child: _buildCalendarPlaceholder(),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: Colors.white,
        currentIndex: 1, // 캘린더는 두 번째 탭
        selectedItemColor: const Color.fromRGBO(142, 198, 230, 1),
        unselectedItemColor: Colors.grey,
        onTap: (index) {
          if (index == 2) {
            Navigator.pushReplacementNamed(context, '/'); // 홈으로 이동
          }
          // 필요한 경우 다른 페이지도 라우팅
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

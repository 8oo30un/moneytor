import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';

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
    final monthStr = DateFormat('yyyy년 MM월', 'ko').format(month);
    return GestureDetector(
      onTap: () {
        setState(() {
          selectedMonth = DateTime(month.year, month.month);
        });
      },
      child: Container(
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 0),
        decoration:
            isSelected
                ? BoxDecoration(
                  color: Colors.blue[100],
                  borderRadius: BorderRadius.circular(12),
                )
                : BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
        child: Text(
          monthStr,
          style: TextStyle(
            fontSize: 14,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            color: isSelected ? Colors.black : const Color(0xFF898989),
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  Widget _buildUpperMonths(DateTime previousMonth, DateTime selected) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          child: _buildMonthItem(previousMonth, isSelected: false),
        ),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          child: _buildMonthItem(selected, isSelected: true),
        ),
      ],
    );
  }

  Widget _buildLowerMonth(DateTime nextMonth) {
    return Column(
      children: [
        const SizedBox(height: 4),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          child: _buildMonthItem(nextMonth, isSelected: false),
        ),
      ],
    );
  }

  Widget _buildCalendar() {
    final monthTitle = DateFormat('MM월', 'ko').format(selectedMonth);
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          Text(
            monthTitle,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          TableCalendar(
            locale: 'ko_KR',
            focusedDay: selectedMonth,
            firstDay: DateTime.utc(2020, 1, 1),
            lastDay: DateTime.utc(2030, 12, 31),
            headerVisible: false,
            calendarFormat: CalendarFormat.month,
            selectedDayPredicate:
                (day) =>
                    day.year == selectedMonth.year &&
                    day.month == selectedMonth.month,
            onDaySelected: (selectedDay, focusedDay) {
              setState(() {
                selectedMonth = DateTime(selectedDay.year, selectedDay.month);
              });
            },
            onPageChanged: (focusedDay) {
              setState(() {
                selectedMonth = DateTime(focusedDay.year, focusedDay.month);
              });
            },
            eventLoader: (day) => [],
            calendarBuilders: CalendarBuilders(
              markerBuilder: (context, date, events) => const SizedBox.shrink(),
              singleMarkerBuilder:
                  (context, date, event) => const SizedBox.shrink(),
              defaultBuilder: (context, day, focusedDay) {
                return Center(
                  child: Text(
                    '${day.day}',
                    style: const TextStyle(fontSize: 12, color: Colors.black),
                  ),
                );
              },
              todayBuilder: (context, day, focusedDay) {
                return Center(
                  child: Text(
                    '${day.day}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                );
              },
              selectedBuilder: (context, day, focusedDay) {
                return Center(
                  child: Text(
                    '${day.day}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final DateTime previousMonth = DateTime(
      selectedMonth.year,
      selectedMonth.month - 1,
    );
    final DateTime nextMonth = DateTime(
      selectedMonth.year,
      selectedMonth.month + 1,
    );

    return Scaffold(
      backgroundColor: const Color.fromRGBO(247, 247, 249, 1),
      appBar: null, // 위 공간 확보 위해 appBar 제거
      body: SafeArea(
        child: Center(
          child: Column(
            children: [
              Expanded(
                flex: 2,
                child: SizedBox(
                  width: MediaQuery.of(context).size.width * 0.87,
                  child: _buildUpperMonths(previousMonth, selectedMonth),
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                flex: 6,
                child: SizedBox(
                  width: MediaQuery.of(context).size.width * 0.82,
                  child: _buildCalendar(),
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                flex: 1,
                child: SizedBox(
                  width: MediaQuery.of(context).size.width * 0.9,
                  child: _buildLowerMonth(nextMonth),
                ),
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }
}

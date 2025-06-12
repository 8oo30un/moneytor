import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';
import 'model/register_card_model.dart';

class CalendarPage extends StatefulWidget {
  final List<RegisterCardModel> registerCards;
  final int monthlyGoal;

  const CalendarPage({
    super.key,
    required this.registerCards,
    required this.monthlyGoal,
  });

  @override
  State<CalendarPage> createState() => _CalendarPageState();
}

class _CalendarPageState extends State<CalendarPage> {
  DateTime selectedMonth = DateTime.now();
  Color _weeklyStatusColor = Colors.transparent;

  @override
  void initState() {
    super.initState();
    _updateWeeklyStatusColorIfNeeded();
  }

  void _changeMonth(int offset) {
    setState(() {
      selectedMonth = DateTime(
        selectedMonth.year,
        selectedMonth.month + offset,
      );
    });
  }

  void _updateWeeklyStatusColorIfNeeded() {
    final now = DateTime.now();
    final isCurrentMonth =
        selectedMonth.year == now.year && selectedMonth.month == now.month;

    if (!isCurrentMonth) {
      return;
    }

    final calculatedColor = _getWeeklyStatusBarColor();
    _weeklyStatusColor = calculatedColor;
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

  Color? _getStatusColorForDay(DateTime day) {
    if (day.isAfter(DateTime.now().add(const Duration(days: 1)))) {
      return null;
    }

    int totalSpent = 0;
    for (final card in widget.registerCards) {
      for (final expense in card.expenses) {
        final expenseDate = DateTime.tryParse(expense['date'] ?? '');
        if (expenseDate != null &&
            expenseDate.year == day.year &&
            expenseDate.month == day.month &&
            expenseDate.day == day.day) {
          totalSpent += expense['price'] as int;
        }
      }
    }

    if (totalSpent == 0) return null;

    final daysInMonth = DateUtils.getDaysInMonth(day.year, day.month);
    final dailyGoal = (widget.monthlyGoal / daysInMonth).round();

    if (totalSpent < dailyGoal * 0.8) {
      return const Color.fromRGBO(161, 227, 249, 1); // 절약
    } else if (totalSpent <= dailyGoal * 1.2) {
      return const Color.fromRGBO(152, 219, 204, 1); // 평균
    } else {
      return const Color.fromRGBO(255, 187, 135, 1); // 과소비
    }
  }

  Color _getWeeklyStatusBarColor() {
    final target = selectedMonth;
    final remainingDays =
        DateUtils.getDaysInMonth(target.year, target.month) - target.day;
    if (remainingDays < 1) return Colors.transparent;

    final dailyGoal =
        widget.monthlyGoal /
        DateUtils.getDaysInMonth(target.year, target.month);
    final weeklyGoal = (dailyGoal * 7).round();

    // 이번 주 월요일(1)부터 일요일(7)까지 범위
    final weekStart = target.subtract(Duration(days: target.weekday - 1));
    final weekEnd = weekStart.add(const Duration(days: 6));

    int projectedSpending = 0;
    for (final card in widget.registerCards) {
      for (final expense in card.expenses) {
        final date = DateTime.tryParse(expense['date'] ?? '');
        if (date != null &&
            !date.isBefore(weekStart) &&
            !date.isAfter(weekEnd)) {
          projectedSpending += expense['price'] as int;
        }
      }
    }

    if (projectedSpending < weeklyGoal * 0.8) {
      return const Color.fromRGBO(152, 219, 204, 1); // 절약
    } else if (projectedSpending <= weeklyGoal * 1.2) {
      return const Color.fromRGBO(161, 227, 249, 1); // 평균
    } else {
      return const Color.fromRGBO(255, 187, 135, 1); // 과소비
    }
  }

  Widget _buildCalendar() {
    final monthTitle = DateFormat('MM월', 'ko').format(selectedMonth);
    final today = DateTime.now();

    // Calculate the week row containing today's date, in the context of the selectedMonth's calendar grid.
    // Get the first day displayed in the calendar grid (may include days from previous month).
    final firstDayOfMonth = DateTime(
      selectedMonth.year,
      selectedMonth.month,
      1,
    );
    final firstDayOfGrid = firstDayOfMonth.subtract(
      Duration(days: firstDayOfMonth.weekday - 1),
    );
    // Replace weekRowOfToday calculation with corrected version:
    int? weekRowOfToday;
    if (today.year == selectedMonth.year &&
        today.month == selectedMonth.month) {
      // Find Sunday of the first week in the calendar grid (grid start)
      final firstDayOfGridSunday = firstDayOfGrid.subtract(
        Duration(days: (firstDayOfGrid.weekday) % 7),
      );
      // Calculate difference in days from that Sunday to today
      final diffDays = today.difference(firstDayOfGridSunday).inDays;
      weekRowOfToday = diffDays ~/ 7 - 1;
    } else {
      weekRowOfToday = null;
    }

    return Container(
      height: 380,
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
          // Stack to draw the week bar behind the calendar grid
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                // TableCalendar's grid is 6 rows (max), so compute row height
                final double calendarHeight = constraints.maxHeight;
                final double rowHeight = calendarHeight / 6.0;

                print('weekRowOfToday: $weekRowOfToday');

                double? topOffset, barHeight;
                if (weekRowOfToday != null) {
                  topOffset = rowHeight * weekRowOfToday! + 20;
                  barHeight = rowHeight - 22;
                }

                // The TableCalendar widget is inside this Expanded.
                return Stack(
                  children: [
                    if (weekRowOfToday != null &&
                        topOffset != null &&
                        barHeight != null)
                      Positioned(
                        top: topOffset,
                        left: 0,
                        right: 0,
                        child: Container(
                          margin: const EdgeInsets.symmetric(horizontal: 0),
                          height: barHeight + 12,
                          decoration: BoxDecoration(
                            color: _weeklyStatusColor.withOpacity(0.6),
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                      ),
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
                        final newMonth = DateTime(
                          selectedDay.year,
                          selectedDay.month,
                        );
                        if (newMonth != selectedMonth) {
                          setState(() {
                            selectedMonth = newMonth;
                          });
                        }
                      },
                      onPageChanged: (focusedDay) {
                        final newMonth = DateTime(
                          focusedDay.year,
                          focusedDay.month,
                        );
                        if (newMonth != selectedMonth) {
                          setState(() {
                            selectedMonth = newMonth;
                          });
                        }
                      },
                      eventLoader: (day) => [],
                      calendarBuilders: CalendarBuilders(
                        markerBuilder:
                            (context, date, events) => const SizedBox.shrink(),
                        singleMarkerBuilder:
                            (context, date, event) => const SizedBox.shrink(),
                        defaultBuilder: (context, day, focusedDay) {
                          final color = _getStatusColorForDay(day);
                          final isInCurrentMonth =
                              day.month == selectedMonth.month &&
                              day.year == selectedMonth.year;
                          return Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: color ?? Colors.transparent,
                              shape: BoxShape.circle,
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              '${day.day}',
                              style: TextStyle(
                                fontSize: 14,
                                color:
                                    isInCurrentMonth
                                        ? Colors.black
                                        : const Color(0xFFB0B0B0),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          );
                        },
                        todayBuilder: (context, day, focusedDay) {
                          final color = _getStatusColorForDay(day);
                          final isInCurrentMonth =
                              day.month == selectedMonth.month &&
                              day.year == selectedMonth.year;
                          return Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: color ?? Colors.transparent,
                              shape: BoxShape.circle,
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              '${day.day}',
                              style: TextStyle(
                                fontSize: 14,
                                color:
                                    isInCurrentMonth
                                        ? Colors.black
                                        : const Color(0xFFB0B0B0),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          );
                        },
                        selectedBuilder: (context, day, focusedDay) {
                          final color = _getStatusColorForDay(day);
                          final isInCurrentMonth =
                              day.month == selectedMonth.month &&
                              day.year == selectedMonth.year;
                          return Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: color ?? Colors.transparent,
                              shape: BoxShape.circle,
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              '${day.day}',
                              style: TextStyle(
                                fontSize: 14,
                                color:
                                    isInCurrentMonth
                                        ? Colors.black
                                        : const Color(0xFFB0B0B0),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          );
                        },
                        outsideBuilder: (context, day, focusedDay) {
                          // 저번달, 다음달 날짜 스타일도 동일하게 검정색, 동일 크기, 위치
                          final color = _getStatusColorForDay(day);
                          return Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: color ?? Colors.transparent,
                              shape: BoxShape.circle,
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              '${day.day}',
                              style: TextStyle(
                                fontSize: 14,
                                color: const Color(0xFFB0B0B0),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
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
      appBar: null,
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

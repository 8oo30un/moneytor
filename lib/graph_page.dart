import 'package:flutter/material.dart';
import 'package:pie_chart/pie_chart.dart'
    as pc; // Make sure to add this package in pubspec.yaml
import 'package:fl_chart/fl_chart.dart';
import 'package:tuple/tuple.dart';
import 'package:provider/provider.dart';
import 'state/app_state.dart';
import 'model/register_card_model.dart'; // Update the path according to your project structure
import 'utils/status_utils.dart'; // or the correct path to calculateStatusFromCard
import '../state/app_state.dart';

/// GraphPage displays a pie chart of expenses per category (register card).
///
class GraphPage extends StatefulWidget {
  final List<RegisterCardModel> registerCards;

  const GraphPage({super.key, required this.registerCards});

  @override
  State<GraphPage> createState() => _GraphPageState();
}

class _GraphPageState extends State<GraphPage> {
  static const List<Color> pieChartColors = [
    Color(0xFF4CAF50), // green
    Color(0xFF2196F3), // blue
    Color(0xFFFFC107), // amber
    Color(0xFFF44336), // red
    Color(0xFF9C27B0), // purple
    Color(0xFF00BCD4), // cyan
  ];
  Map<String, double> categoryExpenseMap = {};
  List<BarChartGroupData> _barChartGroups = [];
  List<String> _sortedMonthKeys = [];

  @override
  void initState() {
    super.initState();
    _prepareChartData();
  }

  /// Prepares the data for the pie chart.
  /// Sums up the expenses per register card (category).
  void _prepareChartData() {
    final map = <String, double>{};

    for (var card in widget.registerCards) {
      double total = 0;
      for (var expense in card.expenses) {
        final price = expense['price'];
        if (price is int || price is double) {
          total += price.toDouble();
        }
      }
      map[card.name] = total;
    }

    final barData = _generateMonthlyBarData();
    setState(() {
      categoryExpenseMap = map;
      _barChartGroups = barData.item1;
      _sortedMonthKeys = barData.item2;
    });
  }

  Tuple2<List<BarChartGroupData>, List<String>> _generateMonthlyBarData() {
    // Group expenses by month (format: yyyy-MM)
    final Map<String, double> monthlyTotals = {};

    for (final card in widget.registerCards) {
      for (final expense in card.expenses) {
        final dateStr = expense['date'] as String?;
        final price = expense['price'];

        if (dateStr != null &&
            (price is int || price is double) &&
            dateStr.isNotEmpty) {
          try {
            final date = DateTime.parse(dateStr);
            final key = '${date.year}-${date.month.toString().padLeft(2, '0')}';
            monthlyTotals[key] = (monthlyTotals[key] ?? 0) + price.toDouble();
          } catch (e) {
            debugPrint('Invalid date format: $dateStr');
          }
        }
      }
    }

    // Sort by date string key and generate bar chart groups
    final sortedKeys = monthlyTotals.keys.toList()..sort();
    int index = 0;
    final groups =
        sortedKeys.map((key) {
          final value = monthlyTotals[key]!;
          return BarChartGroupData(
            x: index++,
            barRods: [
              BarChartRodData(
                toY: value / 10000,
                color: Colors.blue[300],
                width: 16,
                borderRadius: BorderRadius.circular(4),
                rodStackItems: [],
              ),
            ], // Scale for display
          );
        }).toList();
    return Tuple2(groups, sortedKeys);
  }

  Future<String> _getStatusForCard(RegisterCardModel card) async {
    final result = await calculateStatusFromCard(context, selectedCard: card);
    return result.status;
  }

  Color _getWeeklyStatusBarColorForGraph(BuildContext context) {
    final appState = Provider.of<AppState>(context, listen: false);
    final totalGoal = appState.monthlyGoal;
    final target = DateTime.now();
    final remainingDays =
        DateUtils.getDaysInMonth(target.year, target.month) - target.day;
    if (remainingDays < 1) return Colors.transparent;

    final dailyGoal =
        totalGoal / DateUtils.getDaysInMonth(target.year, target.month);
    final weeklyGoal = (dailyGoal * 7).round();

    final weekStart = target.subtract(Duration(days: target.weekday - 1));
    final weekEnd = weekStart.add(const Duration(days: 6));

    double projectedSpending = 0;
    for (final card in widget.registerCards) {
      for (final expense in card.expenses) {
        final date = DateTime.tryParse(expense['date'] ?? '');
        if (date != null &&
            !date.isBefore(weekStart) &&
            !date.isAfter(weekEnd)) {
          final price = expense['price'];
          if (price is int || price is double) {
            projectedSpending += price.toDouble();
          }
        }
      }
    }

    debugPrint('📊 [DEBUG] projectedSpending: $projectedSpending');
    debugPrint('📊 [DEBUG] weeklyGoal: $weeklyGoal');

    if (projectedSpending < weeklyGoal * 0.9) {
      return const Color.fromRGBO(152, 219, 204, 1); // 절약
    } else if (projectedSpending <= weeklyGoal * 1.1) {
      return const Color.fromRGBO(161, 227, 249, 1); // 평균
    } else {
      return const Color.fromRGBO(255, 187, 135, 1); // 과소비
    }
  }

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final totalGoal = appState.monthlyGoal;
    final totalSpending = categoryExpenseMap.values.fold(0.0, (a, b) => a + b);

    return Scaffold(
      backgroundColor: Color.fromRGBO(247, 247, 249, 1),
      appBar: null,
      body: Center(
        child:
            categoryExpenseMap.isEmpty
                ? const Text('지출 데이터가 없습니다.')
                : Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(bottom: 12.0),
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color:
                                  totalSpending < totalGoal
                                      ? const Color.fromRGBO(152, 219, 204, 1)
                                      : const Color.fromRGBO(255, 187, 135, 1),
                              borderRadius: BorderRadius.circular(16),
                              // boxShadow removed
                            ),
                            child: Stack(
                              clipBehavior: Clip.none,
                              children: [
                                Text(
                                  totalSpending < totalGoal
                                      ? '이번 달 목표 지출을 잘 지키고 있어요 🏝️'
                                      : '이번 달 목표 지출을 초과했어요 🚨',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    color: Colors.black87,
                                  ),
                                ),
                                Positioned(
                                  bottom: -22,
                                  left: 6,
                                  child: CustomPaint(size: const Size(20, 10)),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),

                        // 주간 상태 말풍선
                        Builder(
                          builder: (context) {
                            final color = this._getWeeklyStatusBarColorForGraph(
                              context,
                            );
                            final text =
                                color == const Color.fromRGBO(152, 219, 204, 1)
                                    ? '이번 주 지출이 평균적이에요 📊'
                                    : color ==
                                        const Color.fromRGBO(161, 227, 249, 1)
                                    ? '이번 주 지출이 안정적이에요 👍'
                                    : '주의: 이번 주 예상 지출이 초과될 수 있어요 💸';

                            return Container(
                              margin: const EdgeInsets.only(bottom: 16),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: color,
                                borderRadius: BorderRadius.circular(16),
                                // boxShadow removed
                              ),
                              child: Stack(
                                clipBehavior: Clip.none,
                                children: [
                                  Text(
                                    text,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      color: Colors.black87,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 24),

                        const Text(
                          '월별 소비 추이',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 24),
                        SizedBox(
                          height: 180,
                          child: BarChart(
                            BarChartData(
                              barGroups: _barChartGroups,
                              titlesData: FlTitlesData(
                                show: true,
                                bottomTitles: AxisTitles(
                                  sideTitles: SideTitles(
                                    showTitles: true,
                                    getTitlesWidget: (value, meta) {
                                      final index = value.toInt();
                                      if (index < _sortedMonthKeys.length) {
                                        final parts = _sortedMonthKeys[index]
                                            .split('-');
                                        if (parts.length == 2) {
                                          final month =
                                              int.tryParse(parts[1]) ?? 0;
                                          return Text(
                                            '${month}월',
                                            style: const TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w600,
                                              color: Colors.black,
                                            ),
                                          );
                                        }
                                      }
                                      return const SizedBox.shrink();
                                    },
                                  ),
                                ),
                                leftTitles: AxisTitles(
                                  sideTitles: SideTitles(showTitles: false),
                                ),
                                topTitles: AxisTitles(
                                  sideTitles: SideTitles(showTitles: false),
                                ),
                                rightTitles: AxisTitles(
                                  sideTitles: SideTitles(showTitles: false),
                                ),
                              ),
                              borderData: FlBorderData(show: false),
                              gridData: FlGridData(show: false),
                            ),
                          ),
                        ),

                        const SizedBox(height: 48),
                        const Text(
                          '카테고리별 소비 비율',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 24),
                        pc.PieChart(
                          dataMap: categoryExpenseMap,
                          chartType: pc.ChartType.disc,
                          animationDuration: const Duration(milliseconds: 800),
                          chartRadius: MediaQuery.of(context).size.width / 2.2,
                          legendOptions: const pc.LegendOptions(
                            showLegends: true,
                            legendPosition: pc.LegendPosition.right,
                          ),
                          chartValuesOptions: const pc.ChartValuesOptions(
                            showChartValues: false,
                            showChartValuesInPercentage: false,
                          ),
                        ),
                        const SizedBox(height: 30),

                        GridView.count(
                          crossAxisCount: 4,
                          shrinkWrap: true,
                          crossAxisSpacing: 6,
                          mainAxisSpacing: 6,
                          childAspectRatio: 1.25,
                          physics: const NeverScrollableScrollPhysics(),
                          children:
                              categoryExpenseMap.entries.map((entry) {
                                final total = categoryExpenseMap.values
                                    .fold<double>(0, (sum, e) => sum + e);
                                final percentage =
                                    total == 0
                                        ? 0
                                        : (entry.value / total) * 100;

                                final card = widget.registerCards.firstWhere(
                                  (c) => c.name == entry.key,
                                  orElse:
                                      () => RegisterCardModel(
                                        id: '',
                                        name: entry.key,
                                        expenses: [],
                                        totalAmount: 0,
                                      ),
                                );

                                final statusColor = appState.getCardStatusColor(
                                  card.id,
                                );
                                final cardIndex = widget.registerCards
                                    .indexWhere((c) => c.name == entry.key);
                                final pieColor =
                                    cardIndex != -1
                                        ? pieChartColors[cardIndex %
                                            pieChartColors.length]
                                        : Colors.grey.shade300;

                                return Container(
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: statusColor.withOpacity(0.8),
                                      width: 1,
                                    ),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    // vertical: 3,
                                    horizontal: 8,
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        entry.key,
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.black87,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 10,
                                          vertical: 2,
                                        ),
                                        decoration: BoxDecoration(
                                          color: statusColor.withOpacity(0.5),
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                        child: Text(
                                          '${percentage.toStringAsFixed(1)}%',
                                          style: TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.w600,
                                            color: Colors.black38,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }).toList(),
                        ),
                      ],
                    ),
                  ),
                ),
      ),
    );
  }
}

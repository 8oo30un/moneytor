import 'package:flutter/material.dart';
import 'package:pie_chart/pie_chart.dart'
    as pc; // Make sure to add this package in pubspec.yaml
import 'package:fl_chart/fl_chart.dart';
import 'model/register_card_model.dart'; // Update the path according to your project structure
import 'utils/status_utils.dart'; // or the correct path to calculateStatusFromCard

/// GraphPage displays a pie chart of expenses per category (register card).
///
class GraphPage extends StatefulWidget {
  final List<RegisterCardModel> registerCards;

  const GraphPage({super.key, required this.registerCards});

  @override
  State<GraphPage> createState() => _GraphPageState();
}

class _GraphPageState extends State<GraphPage> {
  Map<String, double> categoryExpenseMap = {};
  List<BarChartGroupData> _barChartGroups = [];

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

    setState(() {
      categoryExpenseMap = map;
      _barChartGroups = _generateMonthlyBarData();
    });
  }

  List<BarChartGroupData> _generateMonthlyBarData() {
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
    return sortedKeys.map((key) {
      final value = monthlyTotals[key]!;
      return BarChartGroupData(
        x: index++,
        barRods: [
          BarChartRodData(toY: value / 10000, color: Colors.blue),
        ], // Scale for display
      );
    }).toList();
  }

  String _getStatusForCard(RegisterCardModel card) {
    final result = calculateStatusFromCard(selectedCard: card);
    return result.status;
  }

  @override
  Widget build(BuildContext context) {
    final totalSpending = categoryExpenseMap.values.fold(0.0, (a, b) => a + b);
    const totalGoal = 1000000;

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
                        if (totalSpending < totalGoal)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 12.0),
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.grey[200],
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Text('이번 달 목표 지출을 잘 지키고 있어요 🏝️ '),
                            ),
                          ),
                        Builder(
                          builder: (context) {
                            final weeklyGoal = totalGoal / 4;
                            final projectedSpending = totalSpending;
                            final isOver = projectedSpending > weeklyGoal;
                            return Container(
                              margin: const EdgeInsets.only(bottom: 16),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color:
                                    isOver ? Colors.red[100] : Colors.blue[50],
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                isOver
                                    ? '주의: 이번 주 예상 지출이 초과될 수 있어요 💸'
                                    : '이번 주 지출이 안정적이에요 👍',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            );
                          },
                        ),
                        const Text(
                          '월별 소비 추이',
                          style: TextStyle(
                            fontSize: 16,
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
                                      const style = TextStyle(fontSize: 10);
                                      final index = value.toInt();
                                      if (index < _barChartGroups.length) {
                                        final sortedKeys =
                                            categoryExpenseMap.keys.toList()
                                              ..sort();
                                        final label =
                                            sortedKeys.length > index
                                                ? sortedKeys[index]
                                                : '';
                                        return Text(label, style: style);
                                      }
                                      return Text('', style: style);
                                    },
                                  ),
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
                            fontSize: 16,
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
                        const SizedBox(height: 24),
                        ...categoryExpenseMap.entries.map((entry) {
                          final total = categoryExpenseMap.values.fold<double>(
                            0,
                            (sum, e) => sum + e,
                          );
                          final percentage =
                              total == 0 ? 0 : (entry.value / total) * 100;

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

                          final statusResult = calculateStatusFromCard(
                            selectedCard: card,
                          );

                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 6.0),
                            child: Container(
                              decoration: BoxDecoration(
                                color: statusResult.color.withOpacity(0.7),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              padding: const EdgeInsets.symmetric(
                                vertical: 10,
                                horizontal: 12,
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      entry.key,
                                      style: const TextStyle(fontSize: 16),
                                    ),
                                  ),
                                  Text(
                                    '${percentage.toStringAsFixed(1)}%',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                ),
      ),
    );
  }
}

// TODO: Fetch registerCards from Firestore or other backend and pass to GraphPage.

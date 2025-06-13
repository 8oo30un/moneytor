import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../model/register_card_model.dart';
import '../state/app_state.dart';

class CardSpendingDetailGrid extends StatelessWidget {
  final RegisterCardModel card;
  final Color statusColor;

  const CardSpendingDetailGrid({
    Key? key,
    required this.card,
    required this.statusColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final card = appState.selectedCard;
    final statusColor = appState.statusColor;

    final now = DateTime.now();
    final daysInMonth = DateUtils.getDaysInMonth(now.year, now.month);
    final currentDay = now.day;

    final goal = card?.spendingGoal ?? 0;
    final total = card?.totalAmount ?? 0;

    final goalAverage = (goal / daysInMonth).round();
    final currentAverage = ((total / currentDay)).round();

    Widget buildTile(String title, int amount) {
      return IntrinsicHeight(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0),
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(
                horizontal: 8,
                vertical: 6,
              ), // reduced padding
              child: Center(
                child: Text(
                  title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                    color: Colors.black87,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 4), // reduced spacing
            Text(
              '${amount.toString()}원',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: Colors.black,
              ),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8),
      child: Container(
        // ✅ 전체 영역 흰 배경 벤토 박스 스타일
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.3),
          borderRadius: BorderRadius.circular(16),
        ),
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 2.2,
              children: [
                buildTile('목표 지출', goal),
                buildTile('목표 평균', goalAverage),
                buildTile('현재 지출', total),
                buildTile('현재 평균', currentAverage),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

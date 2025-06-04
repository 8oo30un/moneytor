import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class ProgressBar extends StatelessWidget {
  final double progress; // 0.0 ~ 1.0
  final Color color;
  final double height;
  final double borderRadius;

  const ProgressBar({
    super.key,
    required this.progress,
    this.color = Colors.blue,
    this.height = 16.0,
    this.borderRadius = 6.0,
  });

  @override
  Widget build(BuildContext context) {
    final clampedProgress = progress.clamp(0.0, 1.0);

    return Container(
      height: height,
      decoration: BoxDecoration(
        color: const Color.fromRGBO(246, 246, 248, 1),
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      child: Stack(
        children: [
          FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: clampedProgress,
            child: Container(
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(borderRadius),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class MonthlySpendingHeader extends StatelessWidget {
  const MonthlySpendingHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final yearMonth = DateFormat('yyyy년 M월').format(now);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8),
      child: Text(
        '$yearMonth 지출',
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      ),
    );
  }
}

class BentoLabelBox extends StatelessWidget {
  final String label;
  final IconData? icon;

  const BentoLabelBox({super.key, required this.label, this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(right: 2.0),
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 2.0),
      decoration: BoxDecoration(
        color: Color.fromRGBO(247, 247, 249, 1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[Icon(icon, size: 18), const SizedBox(width: 6)],
          Text(
            label,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

/// A reusable widget that shows a progress bar and percentage text horizontally.
class LabeledProgressBox extends StatelessWidget {
  final double progress;
  final Color color;

  const LabeledProgressBox({
    super.key,
    required this.progress,
    this.color = Colors.blue,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: ProgressBar(progress: progress, color: color)),
        const SizedBox(width: 4),
      ],
    );
  }
}

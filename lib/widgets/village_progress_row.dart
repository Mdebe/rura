import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// One row inside "Top Villages": label, a horizontal progress bar sized
/// by [fraction] (0.0 - 1.0), the raw count and the percentage of total.
class VillageProgressRow extends StatelessWidget {
  final String village;
  final int count;
  final double percentage;
  final double fraction;

  const VillageProgressRow({
    super.key,
    required this.village,
    required this.count,
    required this.percentage,
    required this.fraction,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          SizedBox(
            width: 110,
            child: Text(village, style: const TextStyle(fontSize: 13), overflow: TextOverflow.ellipsis),
          ),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: fraction.clamp(0.0, 1.0),
                minHeight: 8,
                backgroundColor: AppColors.divider,
                valueColor: const AlwaysStoppedAnimation(AppColors.primary),
              ),
            ),
          ),
          const SizedBox(width: 10),
          SizedBox(
            width: 34,
            child: Text('$count', textAlign: TextAlign.right, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
          ),
          SizedBox(
            width: 46,
            child: Text('${percentage.toStringAsFixed(1)}%',
                textAlign: TextAlign.right, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
          ),
        ],
      ),
    );
  }
}

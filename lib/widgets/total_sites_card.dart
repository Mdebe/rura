import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class TotalSitesCard extends StatelessWidget {
  final int total;
  final int deltaToday;
  final int today;
  final int thisWeek;
  final int villages;

  const TotalSitesCard({
    super.key,
    required this.total,
    required this.deltaToday,
    required this.today,
    required this.thisWeek,
    required this.villages,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmall = screenWidth < 360;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isSmall ? 16 : 20),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Total Sites Registered',
            style: TextStyle(
              color: Colors.white70,
              fontSize: isSmall ? 13 : 14,
            ),
          ),

          const SizedBox(height: 6),

          Text(
            '$total',
            style: TextStyle(
              color: Colors.white,
              fontSize: isSmall ? 34 : 40,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 4),

          Row(
            children: [
              const Icon(
                Icons.arrow_upward,
                color: Colors.greenAccent,
                size: 14,
              ),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  '+$deltaToday today',
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.greenAccent,
                    fontSize: isSmall ? 12 : 13,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 18),

          Container(
            height: 1,
            color: Colors.white24,
          ),

          const SizedBox(height: 16),

          Row(
            children: [
              Expanded(
                child: _MiniStat(
                  icon: Icons.calendar_today_outlined,
                  label: 'Today',
                  value: '$today',
                  isSmall: isSmall,
                ),
              ),
              Expanded(
                child: _MiniStat(
                  icon: Icons.access_time,
                  label: 'This Week',
                  value: '$thisWeek',
                  isSmall: isSmall,
                ),
              ),
              Expanded(
                child: _MiniStat(
                  icon: Icons.location_on_outlined,
                  label: 'Villages',
                  value: '$villages',
                  isSmall: isSmall,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool isSmall;

  const _MiniStat({
    required this.icon,
    required this.label,
    required this.value,
    required this.isSmall,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(
            icon,
            color: Colors.white70,
            size: isSmall ? 16 : 18,
          ),

          const SizedBox(height: 6),

          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white70,
                fontSize: isSmall ? 10 : 12,
              ),
            ),
          ),

          const SizedBox(height: 2),

          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontSize: isSmall ? 16 : 18,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
import 'package:flutter/material.dart';
import '../utils/constants.dart';

class KpiCard extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final String? delta;
  final bool isDeltaUp;
  final bool isHighlighted;

  const KpiCard({
    super.key,
    required this.icon,
    required this.value,
    required this.label,
    this.delta,
    this.isDeltaUp = true,
    this.isHighlighted = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: AppConstants.bgCard,
        border: Border.all(
          color: isHighlighted
              ? AppConstants.gold.withValues(alpha: 0.16)
              : AppConstants.ink.withValues(alpha: 0.07),
        ),
        boxShadow: isHighlighted
            ? [
          BoxShadow(
            color: AppConstants.gold.withValues(alpha: 0.15),
            blurRadius: 40,
            offset: const Offset(0, 18),
          ),
        ]
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(9),
              color: AppConstants.gold.withValues(alpha: 0.1),
            ),
            child: Icon(icon, color: AppConstants.goldSoft, size: 17),
          ),
          const SizedBox(height: 12),
          // Value with FittedBox to prevent overflow
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: const TextStyle(
                fontFamily: 'Oswald',
                fontSize: 24,
                fontWeight: FontWeight.w600,
                color: AppConstants.ink,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 10.5,
              color: AppConstants.inkFaint,
              letterSpacing: 0.5,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
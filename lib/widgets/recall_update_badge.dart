/// Recall Update Badge Widget
/// Shows an "Updated" indicator on recall cards when the recall has recent changes.
library;

import 'package:flutter/material.dart';

/// A small badge indicating a recall has been recently updated
class RecallUpdateBadge extends StatelessWidget {
  final String? updateType;
  final bool isCompact;

  const RecallUpdateBadge({
    super.key,
    this.updateType,
    this.isCompact = false,
  });

  @override
  Widget build(BuildContext context) {
    final label = _getLabel();
    final color = _getColor();

    if (isCompact) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: color.withValues(alpha: 0.3), width: 1),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.update, size: 10, color: color),
            const SizedBox(width: 3),
            Text(
              label,
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.update, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  String _getLabel() {
    switch (updateType) {
      case 'remedy_available':
        return 'Remedy Available';
      case 'risk_level_changed':
        return 'Risk Changed';
      default:
        return 'Updated';
    }
  }

  Color _getColor() {
    switch (updateType) {
      case 'remedy_available':
        return Colors.green;
      case 'risk_level_changed':
        return Colors.orange;
      default:
        return Colors.blue;
    }
  }
}

/// A dot indicator for minimal space usage
class RecallUpdateDot extends StatelessWidget {
  final Color? color;
  final double size;

  const RecallUpdateDot({
    super.key,
    this.color,
    this.size = 8,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color ?? Colors.blue,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: (color ?? Colors.blue).withValues(alpha: 0.4),
            blurRadius: 4,
            spreadRadius: 1,
          ),
        ],
      ),
    );
  }
}

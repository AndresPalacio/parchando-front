import 'package:flutter/material.dart';

class PatchCard extends StatelessWidget {
  final String name;
  final String icon;
  final double balance;
  final VoidCallback onTap;

  const PatchCard({
    super.key,
    required this.name,
    required this.icon,
    required this.balance,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isNegative = balance < 0;
    final balanceText = balance == 0
        ? 'Al día'
        : '\$${balance.abs().toStringAsFixed(0)} ${isNegative ? 'debes' : 'te deben'}';

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 140,
        margin: const EdgeInsets.only(right: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              name,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              balanceText,
              style: TextStyle(
                color: isNegative ? Colors.red : Colors.green[700],
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Indicador visual do nível de umidade do solo com destaque para limiar crítico (< 40%).
class MoistureIndicator extends StatelessWidget {
  final double umidade;

  const MoistureIndicator({super.key, required this.umidade});

  @override
  Widget build(BuildContext context) {
    final bool critica = umidade < 40.0;
    final cor = critica ? AppTheme.dangerRed : AppTheme.agroGreenSecondary;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(
                  critica ? Icons.warning_amber_rounded : Icons.water_drop_rounded,
                  size: 16,
                  color: cor,
                ),
                const SizedBox(width: 4),
                Text(
                  critica ? 'Umidade Baixa (<40%)' : 'Umidade Adequada',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: cor,
                  ),
                ),
              ],
            ),
            Text(
              '${umidade.toStringAsFixed(1)}%',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: cor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            value: (umidade / 100.0).clamp(0.0, 1.0),
            backgroundColor: Colors.grey.shade200,
            valueColor: AlwaysStoppedAnimation<Color>(cor),
            minHeight: 8,
          ),
        ),
      ],
    );
  }
}


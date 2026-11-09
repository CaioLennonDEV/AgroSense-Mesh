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
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: cor.withAlpha(25),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Icon(
                    critica ? Icons.warning_amber_rounded : Icons.water_drop_rounded,
                    size: 15,
                    color: cor,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  critica ? 'Umidade Baixa (<40%)' : 'Umidade Adequada',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: cor,
                  ),
                ),
              ],
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: cor.withAlpha(20),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '${umidade.toStringAsFixed(1)}%',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: cor,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: (umidade / 100.0).clamp(0.0, 1.0),
            backgroundColor: const Color(0xFFE2E8F0),
            valueColor: AlwaysStoppedAnimation<Color>(cor),
            minHeight: 8,
          ),
        ),
      ],
    );
  }
}

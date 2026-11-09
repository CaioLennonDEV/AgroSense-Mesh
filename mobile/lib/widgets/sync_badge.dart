import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Badge visual para diferenciar itens sincronizados de itens pendentes no SQLite.
///
/// Atende ao **Requisito 1** da AP2B:
/// - Feedback visual de conectividade.
class SyncBadge extends StatelessWidget {
  final bool sincronizado;
  final bool exibirTexto;

  const SyncBadge({
    super.key,
    required this.sincronizado,
    this.exibirTexto = true,
  });

  @override
  Widget build(BuildContext context) {
    final cor = sincronizado ? AppTheme.syncGreen : AppTheme.pendingOrange;
    final icone = sincronizado ? Icons.cloud_done_rounded : Icons.cloud_upload_rounded;
    final texto = sincronizado ? 'Sincronizado' : 'Pendente';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: cor.withAlpha(25),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cor.withAlpha(120), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icone, size: 14, color: cor),
          if (exibirTexto) ...[
            const SizedBox(width: 4),
            Text(
              texto,
              style: TextStyle(
                color: cor,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ],
      ),
    );
  }
}


import 'package:flutter/material.dart';
import '../models/registro_telemetria.dart';
import '../theme/app_theme.dart';
import '../widgets/moisture_indicator.dart';
import '../widgets/responsive_layout.dart';
import '../widgets/sync_badge.dart';

/// Rota 5: Detalhamento de Leitura com passagem segura de argumentos via Rotas.
class DetalheLeituraScreen extends StatelessWidget {
  const DetalheLeituraScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final telemetria = ModalRoute.of(context)?.settings.arguments as RegistroTelemetria?;

    if (telemetria == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Detalhes')),
        body: const Center(child: Text('Nenhuma leitura selecionada.')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('${telemetria.sensorId} (${telemetria.zona})'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: SyncBadge(sincronizado: telemetria.sincronizado),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: ResponsiveLayout(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Cartão de Destaque
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppTheme.cardBorder, width: 1),
                  boxShadow: AppTheme.softShadow,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppTheme.agroGreenPrimary.withAlpha(20),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.sensors_rounded, color: AppTheme.agroGreenPrimary, size: 28),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                telemetria.sensorId,
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppTheme.textDark),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Localização: ${telemetria.zona}',
                                style: const TextStyle(color: AppTheme.textMuted, fontSize: 13),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      child: Divider(color: Colors.grey.shade200, height: 1),
                    ),
                    MoistureIndicator(umidade: telemetria.umidadeSolo),
                  ],
                ),
              ),

              const SizedBox(height: 18),

              // Especificações Técnicas
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppTheme.cardBorder, width: 1),
                  boxShadow: AppTheme.softShadow,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Telemetria e Diagnóstico de Campo',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.textDark),
                    ),
                    const SizedBox(height: 18),
                    _buildRow(
                      icone: Icons.thermostat_rounded,
                      cor: Colors.amber.shade700,
                      label: 'Temperatura Ambiente:',
                      valor: '${telemetria.temperatura.toStringAsFixed(1)} °C',
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Divider(color: Colors.grey.shade100, height: 1),
                    ),
                    _buildRow(
                      icone: Icons.battery_charging_full_rounded,
                      cor: AppTheme.agroGreenSecondary,
                      label: 'Nível da Bateria:',
                      valor: '${telemetria.bateria}%',
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Divider(color: Colors.grey.shade100, height: 1),
                    ),
                    _buildRow(
                      icone: Icons.access_time_rounded,
                      cor: Colors.blue.shade700,
                      label: 'Data / Hora da Leitura:',
                      valor:
                          '${telemetria.dataHora.day.toString().padLeft(2, '0')}/${telemetria.dataHora.month.toString().padLeft(2, '0')}/${telemetria.dataHora.year} ${telemetria.dataHora.hour.toString().padLeft(2, '0')}:${telemetria.dataHora.minute.toString().padLeft(2, '0')}',
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Divider(color: Colors.grey.shade100, height: 1),
                    ),
                    _buildRow(
                      icone: Icons.cloud_done_rounded,
                      cor: telemetria.sincronizado ? AppTheme.syncGreen : AppTheme.pendingOrange,
                      label: 'Estado de Persistência:',
                      valor: telemetria.sincronizado
                          ? 'Sincronizado na Nuvem'
                          : 'Armazenado no SQLite Local (Pendente)',
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Divider(color: Colors.grey.shade100, height: 1),
                    ),
                    _buildRow(
                      icone: Icons.water_drop_rounded,
                      cor: telemetria.precisaIrrigacao ? AppTheme.dangerRed : AppTheme.waterBlue,
                      label: 'Status da Válvula de Irrigação:',
                      valor: telemetria.precisaIrrigacao
                          ? 'ACIONADA AUTOMATICAMENTE (< 40%)'
                          : 'DESLIGADA (Umidade Adequada)',
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              OutlinedButton.icon(
                icon: const Icon(Icons.arrow_back_rounded),
                label: const Text('Voltar para Listagem'),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRow({
    required IconData icone,
    required Color cor,
    required String label,
    required String valor,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: cor.withAlpha(20),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Icon(icone, size: 18, color: cor),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13, color: AppTheme.textMuted),
          ),
        ),
        Text(
          valor,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppTheme.textDark),
        ),
      ],
    );
  }
}

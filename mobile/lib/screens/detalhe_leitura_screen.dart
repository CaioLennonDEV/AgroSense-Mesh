import 'package:flutter/material.dart';
import '../models/registro_telemetria.dart';
import '../theme/app_theme.dart';
import '../widgets/moisture_indicator.dart';
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
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Status Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 24,
                          backgroundColor: AppTheme.agroGreenPrimary.withAlpha(25),
                          child: const Icon(Icons.sensors_rounded, color: AppTheme.agroGreenPrimary, size: 28),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                telemetria.sensorId,
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                              ),
                              Text(
                                'Localização: ${telemetria.zona}',
                                style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 32),
                    MoistureIndicator(umidade: telemetria.umidadeSolo),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Especificações Técnicas
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Telemetria e Diagnóstico de Campo',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    const SizedBox(height: 16),
                    _buildRow(
                      icone: Icons.thermostat_rounded,
                      label: 'Temperatura Ambiente:',
                      valor: '${telemetria.temperatura.toStringAsFixed(1)} °C',
                    ),
                    const Divider(height: 20),
                    _buildRow(
                      icone: Icons.battery_charging_full_rounded,
                      label: 'Nível da Bateria:',
                      valor: '${telemetria.nivelBateria}%',
                    ),
                    const Divider(height: 20),
                    _buildRow(
                      icone: Icons.access_time_rounded,
                      label: 'Data / Hora da Leitura:',
                      valor:
                          '${telemetria.timestamp.day.toString().padLeft(2, '0')}/${telemetria.timestamp.month.toString().padLeft(2, '0')}/${telemetria.timestamp.year} ${telemetria.timestamp.hour.toString().padLeft(2, '0')}:${telemetria.timestamp.minute.toString().padLeft(2, '0')}',
                    ),
                    const Divider(height: 20),
                    _buildRow(
                      icone: Icons.cloud_done_rounded,
                      label: 'Estado de Persistência:',
                      valor: telemetria.sincronizado
                          ? 'Sincronizado na Nuvem'
                          : 'Armazenado no SQLite Local (Pendente)',
                    ),
                    const Divider(height: 20),
                    _buildRow(
                      icone: Icons.water_drop_rounded,
                      label: 'Status da Válvula de Irrigação:',
                      valor: telemetria.precisaIrrigacao
                          ? 'ACIONADA AUTOMATICAMENTE (< 40%)'
                          : 'DESLIGADA (Umidade Adequada)',
                    ),
                  ],
                ),
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
    );
  }

  Widget _buildRow({required IconData icone, required String label, required String valor}) {
    return Row(
      children: [
        Icon(icone, size: 20, color: AppTheme.agroGreenPrimary),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
          ),
        ),
        Text(
          valor,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
        ),
      ],
    );
  }
}


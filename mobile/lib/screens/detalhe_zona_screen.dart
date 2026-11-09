import 'package:flutter/material.dart';
import '../models/registro_telemetria.dart';
import '../theme/app_theme.dart';
import '../widgets/moisture_indicator.dart';
import '../widgets/responsive_layout.dart';
import '../widgets/sync_badge.dart';

/// Rota 9: Detalhamento de Zona com passagem de argumentos complexos via Rotas.
class DetalheZonaScreen extends StatelessWidget {
  const DetalheZonaScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;

    final zonaNome = args?['zona'] as String? ?? 'Zona de Plantio';
    final leituras = (args?['leituras'] as List<RegistroTelemetria>?) ?? [];
    final mediaUmidade = (args?['mediaUmidade'] as double?) ?? 0.0;

    return Scaffold(
      appBar: AppBar(
        title: Text('Detalhamento: $zonaNome'),
      ),
      body: SingleChildScrollView(
        child: ResponsiveLayout(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppTheme.cardBorder, width: 1),
                  boxShadow: AppTheme.softShadow,
                ),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppTheme.agroGreenPrimary.withAlpha(20),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.terrain_rounded, size: 36, color: AppTheme.agroGreenPrimary),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      zonaNome,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 22, color: AppTheme.textDark),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Monitoramento de Sensores de Solo do AgroSense Mesh',
                      style: TextStyle(fontSize: 12, color: AppTheme.textMuted),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      child: Divider(color: Colors.grey.shade100, height: 1),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        Column(
                          children: [
                            const Text('Sensores Ativos', style: TextStyle(fontSize: 12, color: AppTheme.textMuted)),
                            const SizedBox(height: 4),
                            Text(
                              '${leituras.length}',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 22, color: AppTheme.textDark),
                            ),
                          ],
                        ),
                        Container(height: 36, width: 1, color: Colors.grey.shade200),
                        Column(
                          children: [
                            const Text('Umidade Média', style: TextStyle(fontSize: 12, color: AppTheme.textMuted)),
                            const SizedBox(height: 4),
                            Text(
                              '${mediaUmidade.toStringAsFixed(1)}%',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 22,
                                color: mediaUmidade < 40 ? AppTheme.dangerRed : AppTheme.agroGreenPrimary,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              Text(
                'Leituras Registradas em $zonaNome',
                style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: AppTheme.textDark),
              ),
              const SizedBox(height: 12),

              if (leituras.isEmpty)
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppTheme.cardBorder, width: 1),
                  ),
                  child: const Center(
                    child: Text('Nenhuma leitura registrada para esta zona.', style: TextStyle(color: AppTheme.textMuted)),
                  ),
                )
              else
                ...leituras.map((t) => Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppTheme.cardBorder, width: 1),
                        boxShadow: AppTheme.softShadow,
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  t.sensorId,
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.textDark),
                                ),
                                SyncBadge(sincronizado: t.sincronizado),
                              ],
                            ),
                            const SizedBox(height: 10),
                            MoistureIndicator(umidade: t.umidadeSolo),
                            const SizedBox(height: 10),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    Icon(Icons.thermostat_rounded, size: 16, color: Colors.grey.shade600),
                                    const SizedBox(width: 4),
                                    Text(
                                      '${t.temperatura.toStringAsFixed(1)}°C',
                                      style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                                    ),
                                    const SizedBox(width: 12),
                                    Icon(Icons.battery_charging_full_rounded, size: 16, color: Colors.grey.shade600),
                                    const SizedBox(width: 4),
                                    Text(
                                      '${t.bateria}%',
                                      style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                                    ),
                                  ],
                                ),
                                Text(
                                  '${t.dataHora.hour.toString().padLeft(2, '0')}:${t.dataHora.minute.toString().padLeft(2, '0')}',
                                  style: const TextStyle(fontSize: 11, color: AppTheme.textMuted),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    )),
            ],
          ),
        ),
      ),
    );
  }
}

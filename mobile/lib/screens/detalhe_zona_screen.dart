import 'package:flutter/material.dart';
import '../models/registro_telemetria.dart';
import '../theme/app_theme.dart';
import '../widgets/moisture_indicator.dart';
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
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 30,
                      backgroundColor: AppTheme.agroGreenPrimary.withAlpha(20),
                      child: const Icon(Icons.terrain_rounded, size: 36, color: AppTheme.agroGreenPrimary),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      zonaNome,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 22),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Monitoramento de Sensores de Solo do AgroSense Mesh',
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                    ),
                    const Divider(height: 32),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        Column(
                          children: [
                            const Text('Sensores Ativos', style: TextStyle(fontSize: 12, color: Colors.grey)),
                            const SizedBox(height: 4),
                            Text(
                              '${leituras.length}',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
                            ),
                          ],
                        ),
                        Column(
                          children: [
                            const Text('Umidade Média', style: TextStyle(fontSize: 12, color: Colors.grey)),
                            const SizedBox(height: 4),
                            Text(
                              '${mediaUmidade.toStringAsFixed(1)}%',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 20,
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
            ),

            const SizedBox(height: 20),

            Text(
              'Leituras Registradas em $zonaNome',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),

            if (leituras.isEmpty)
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: Center(child: Text('Nenhuma leitura registrada para esta zona.')),
                ),
              )
            else
              ...leituras.map((t) => Card(
                    margin: const EdgeInsets.only(bottom: 10),
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
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                              ),
                              SyncBadge(sincronizado: t.sincronizado),
                            ],
                          ),
                          const SizedBox(height: 8),
                          MoistureIndicator(umidade: t.umidadeSolo),
                          const SizedBox(height: 8),
                          Text(
                            'Temp: ${t.temperatura.toStringAsFixed(1)}°C • Bateria: ${t.nivelBateria}%',
                            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                          ),
                        ],
                      ),
                    ),
                  )),
          ],
        ),
      ),
    );
  }
}


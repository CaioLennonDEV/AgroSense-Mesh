import 'package:flutter/material.dart';
import '../models/evento_irrigacao.dart';
import '../models/registro_telemetria.dart';
import '../services/app_service_locator.dart';
import '../theme/app_theme.dart';
import '../widgets/app_drawer.dart';
import '../widgets/moisture_indicator.dart';
import '../widgets/sync_badge.dart';

/// Rota 2: Dashboard Principal com métricas agropecuárias e estado de sincronização.
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  bool _isLoading = true;
  List<RegistroTelemetria> _telemetrias = [];
  List<EventoIrrigacao> _irrigacoes = [];

  @override
  void initState() {
    super.initState();
    _carregarDados();
  }

  Future<void> _carregarDados() async {
    setState(() => _isLoading = true);
    final repo = AppServiceLocator.instance.repository;
    try {
      final t = await repo.listarTelemetrias();
      final i = await repo.listarIrrigacoes();
      if (mounted) {
        setState(() {
          _telemetrias = t;
          _irrigacoes = i;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final totalPendentes = _telemetrias.where((t) => !t.sincronizado).length +
        _irrigacoes.where((i) => !i.sincronizado).length;

    final mediaUmidade = _telemetrias.isEmpty
        ? 0.0
        : _telemetrias.map((t) => t.umidadeSolo).reduce((a, b) => a + b) / _telemetrias.length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('AgroSense Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.sync_rounded),
            tooltip: 'Diagnóstico & Sincronização',
            onPressed: () async {
              await Navigator.pushNamed(context, '/sincronizacao');
              _carregarDados();
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Atualizar Dados Locais',
            onPressed: _carregarDados,
          ),
        ],
      ),
      drawer: const AppDrawer(currentRoute: '/dashboard'),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _carregarDados,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                  // Banner de Conectividade / Status Offline-First
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: totalPendentes > 0 ? Colors.amber.shade50 : Colors.green.shade50,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: totalPendentes > 0 ? Colors.amber.shade300 : Colors.green.shade300,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          totalPendentes > 0 ? Icons.cloud_queue_rounded : Icons.cloud_done_rounded,
                          size: 32,
                          color: totalPendentes > 0 ? AppTheme.pendingOrange : AppTheme.syncGreen,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                totalPendentes > 0
                                    ? '$totalPendentes registros pendentes de envio'
                                    : 'Base Local 100% Sincronizada',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Fonte Única da Verdade: SQLite Local Ativo',
                                style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                              ),
                            ],
                          ),
                        ),
                        TextButton(
                          onPressed: () async {
                            await Navigator.pushNamed(context, '/sincronizacao');
                            _carregarDados();
                          },
                          child: const Text('Sincronizar'),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Grid de Métricas do Campo
                  Row(
                    children: [
                      Expanded(
                        child: _buildMetricCard(
                          titulo: 'Leituras no Banco',
                          valor: '${_telemetrias.length}',
                          icone: Icons.sensors_rounded,
                          cor: AppTheme.agroGreenPrimary,
                          onTap: () => Navigator.pushNamed(context, '/leituras'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildMetricCard(
                          titulo: 'Irrigações Disparadas',
                          valor: '${_irrigacoes.length}',
                          icone: Icons.water_drop_rounded,
                          cor: Colors.blue.shade700,
                          onTap: () => Navigator.pushNamed(context, '/irrigacao'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _buildMetricCard(
                          titulo: 'Umidade Média',
                          valor: '${mediaUmidade.toStringAsFixed(1)}%',
                          icone: Icons.eco_rounded,
                          cor: mediaUmidade < 40.0 ? AppTheme.dangerRed : AppTheme.agroGreenSecondary,
                          onTap: () => Navigator.pushNamed(context, '/zonas'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildMetricCard(
                          titulo: 'Pendentes Cloud',
                          valor: '$totalPendentes',
                          icone: Icons.hourglass_top_rounded,
                          cor: AppTheme.pendingOrange,
                          onTap: () => Navigator.pushNamed(context, '/sincronizacao'),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Ações Rápidas
                  const Text(
                    'Ações Rápidas de Campo',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      ElevatedButton.icon(
                        icon: const Icon(Icons.add_rounded),
                        label: const Text('Nova Leitura'),
                        onPressed: () async {
                          await Navigator.pushNamed(context, '/leituras/novo');
                          _carregarDados();
                        },
                      ),
                      OutlinedButton.icon(
                        icon: const Icon(Icons.water_drop_outlined),
                        label: const Text('Acionar Válvula'),
                        onPressed: () async {
                          await Navigator.pushNamed(context, '/irrigacao/novo');
                          _carregarDados();
                        },
                      ),
                      OutlinedButton.icon(
                        icon: const Icon(Icons.grid_view_rounded),
                        label: const Text('Ver Zonas (A-C)'),
                        onPressed: () => Navigator.pushNamed(context, '/zonas'),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Últimas Leituras
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Últimas Leituras de Solo',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pushNamed(context, '/leituras'),
                        child: const Text('Ver Todas'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  if (_telemetrias.isEmpty)
                    const Card(
                      child: Padding(
                        padding: EdgeInsets.all(24),
                        child: Center(child: Text('Nenhuma leitura registrada no SQLite.')),
                      ),
                    )
                  else
                    ..._telemetrias.take(4).map((t) => Card(
                          margin: const EdgeInsets.only(bottom: 10),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(16),
                            onTap: () {
                              Navigator.pushNamed(context, '/leituras/detalhes', arguments: t);
                            },
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Row(
                                        children: [
                                          Icon(Icons.sensors_rounded,
                                              size: 20, color: AppTheme.agroGreenPrimary),
                                          const SizedBox(width: 8),
                                          Text(
                                            '${t.sensorId} • ${t.zona}',
                                            style: const TextStyle(
                                                fontWeight: FontWeight.bold, fontSize: 15),
                                          ),
                                        ],
                                      ),
                                      SyncBadge(sincronizado: t.sincronizado),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  MoistureIndicator(umidade: t.umidadeSolo),
                                  const SizedBox(height: 8),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        'Temp: ${t.temperatura.toStringAsFixed(1)}°C • Bateria: ${t.nivelBateria}%',
                                        style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                                      ),
                                      if (t.precisaIrrigacao)
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: AppTheme.dangerRed.withAlpha(20),
                                            borderRadius: BorderRadius.circular(6),
                                          ),
                                          child: const Text(
                                            'IRRIGAÇÃO ACIONADA',
                                            style: TextStyle(
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold,
                                              color: AppTheme.dangerRed,
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        )),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildMetricCard({
    required String titulo,
    required String valor,
    required IconData icone,
    required Color cor,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: cor.withAlpha(25),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icone, color: cor, size: 24),
              ),
              const SizedBox(height: 12),
              Text(
                valor,
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(
                titulo,
                style: TextStyle(fontSize: 12, color: Colors.grey.shade700, fontWeight: FontWeight.w500),
              ),
            ],
          ),
        ),
      ),
    );
  }
}


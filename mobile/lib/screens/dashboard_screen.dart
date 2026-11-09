import 'package:flutter/material.dart';
import '../models/evento_irrigacao.dart';
import '../models/registro_telemetria.dart';
import '../services/app_service_locator.dart';
import '../theme/app_theme.dart';
import '../widgets/app_drawer.dart';
import '../widgets/moisture_indicator.dart';
import '../widgets/responsive_layout.dart';
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
                child: ResponsiveLayout(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // ── Hero Header Gradiente ────────────────────────────────────
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF064E3B), Color(0xFF047857), Color(0xFF0D9488)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF064E3B).withAlpha(40),
                              blurRadius: 16,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withAlpha(35),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.circle, size: 8, color: Color(0xFF34D399)),
                                      SizedBox(width: 6),
                                      Text(
                                        'Cluster Mesh Conectado',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withAlpha(25),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Text(
                                    'Offline-First',
                                    style: TextStyle(color: Colors.white70, fontSize: 11),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              'Monitoramento em Tempo Real',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.3,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Zonas A, B e C com controle hídrico inteligente e tolerância a falhas',
                              style: TextStyle(
                                color: Colors.white.withAlpha(210),
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 18),

                      // ── Banner de Sincronização e Resiliência ────────────────────
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: totalPendentes > 0 ? const Color(0xFFFFFBEB) : const Color(0xFFECFDF5),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: totalPendentes > 0 ? const Color(0xFFFDE68A) : const Color(0xFFA7F3D0),
                            width: 1.2,
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: totalPendentes > 0
                                    ? AppTheme.pendingOrange.withAlpha(30)
                                    : AppTheme.syncGreen.withAlpha(30),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                totalPendentes > 0
                                    ? Icons.cloud_upload_rounded
                                    : Icons.cloud_done_rounded,
                                size: 24,
                                color: totalPendentes > 0
                                    ? AppTheme.pendingOrange
                                    : AppTheme.syncGreen,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    totalPendentes > 0
                                        ? '$totalPendentes registros pendentes de envio'
                                        : 'Base Local 100% Sincronizada',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                      color: totalPendentes > 0
                                          ? const Color(0xFF92400E)
                                          : const Color(0xFF065F46),
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Fonte Única da Verdade: SQLite Local Ativo',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: totalPendentes > 0
                                          ? const Color(0xFFB45309)
                                          : const Color(0xFF047857),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: totalPendentes > 0
                                    ? AppTheme.pendingOrange
                                    : AppTheme.agroGreenPrimary,
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                              ),
                              onPressed: () async {
                                await Navigator.pushNamed(context, '/sincronizacao');
                                _carregarDados();
                              },
                              child: const Text('Sincronizar'),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 20),

                      // ── Grid de Métricas do Campo ──────────────────────────────
                      Row(
                        children: [
                          Expanded(
                            child: _buildMetricCard(
                              titulo: 'Leituras no Banco',
                              valor: '${_telemetrias.length}',
                              subtitulo: 'SQLite Local',
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
                              subtitulo: 'Comandos locais',
                              icone: Icons.water_drop_rounded,
                              cor: AppTheme.waterBlue,
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
                              subtitulo: mediaUmidade < 40.0 ? 'Crítica (<40%)' : 'Solo Adequado',
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
                              subtitulo: 'Fila de upload',
                              icone: Icons.cloud_queue_rounded,
                              cor: AppTheme.pendingOrange,
                              onTap: () => Navigator.pushNamed(context, '/sincronizacao'),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 24),

                      // ── Ações Rápidas ───────────────────────────────────────────
                      const Text(
                        'Ações Rápidas de Campo',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textDark,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.agroGreenPrimary,
                                padding: const EdgeInsets.symmetric(vertical: 14),
                              ),
                              icon: const Icon(Icons.add_rounded, size: 20),
                              label: const Text('Nova Leitura'),
                              onPressed: () async {
                                await Navigator.pushNamed(context, '/leituras/novo');
                                _carregarDados();
                              },
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.waterBlue,
                                padding: const EdgeInsets.symmetric(vertical: 14),
                              ),
                              icon: const Icon(Icons.water_drop_outlined, size: 20),
                              label: const Text('Válvula Manual'),
                              onPressed: () async {
                                await Navigator.pushNamed(context, '/irrigacao/novo');
                                _carregarDados();
                              },
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: OutlinedButton.icon(
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 14),
                              ),
                              icon: const Icon(Icons.grid_view_rounded, size: 20),
                              label: const Text('Ver Zonas'),
                              onPressed: () => Navigator.pushNamed(context, '/zonas'),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 28),

                      // ── Últimas Leituras ────────────────────────────────────────
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Últimas Leituras de Solo',
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textDark,
                            ),
                          ),
                          TextButton.icon(
                            icon: const Icon(Icons.arrow_forward_rounded, size: 16),
                            label: const Text('Ver Todas'),
                            onPressed: () => Navigator.pushNamed(context, '/leituras'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),

                      if (_telemetrias.isEmpty)
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(28),
                            child: Center(
                              child: Column(
                                children: [
                                  Icon(Icons.inbox_outlined, size: 40, color: Colors.grey.shade400),
                                  const SizedBox(height: 8),
                                  const Text(
                                    'Nenhuma leitura registrada no SQLite.',
                                    style: TextStyle(color: AppTheme.textMuted),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        )
                      else
                        ..._telemetrias.take(4).map(
                              (t) => _buildReadingCard(t),
                            ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }

  Widget _buildMetricCard({
    required String titulo,
    required String valor,
    required String subtitulo,
    required IconData icone,
    required Color cor,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
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
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: cor.withAlpha(20),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icone, size: 20, color: cor),
                ),
                Icon(Icons.chevron_right_rounded, size: 18, color: Colors.grey.shade400),
              ],
            ),
            const SizedBox(height: 14),
            Text(
              valor,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: cor,
                letterSpacing: 0.2,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              titulo,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppTheme.textDark,
              ),
            ),
            Text(
              subtitulo,
              style: const TextStyle(
                fontSize: 11,
                color: AppTheme.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReadingCard(RegistroTelemetria t) {
    final bool seca = t.umidadeSolo < 40.0;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.cardBorder, width: 1),
        boxShadow: AppTheme.softShadow,
      ),
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
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF065F46).withAlpha(15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          t.sensorId,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                            color: Color(0xFF065F46),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          t.zona,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey.shade700,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SyncBadge(sincronizado: t.sincronizado),
                ],
              ),
              const SizedBox(height: 12),
              MoistureIndicator(umidade: t.umidadeSolo),
              const SizedBox(height: 12),
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
                      const SizedBox(width: 14),
                      Icon(Icons.battery_charging_full_rounded, size: 16, color: Colors.grey.shade600),
                      const SizedBox(width: 4),
                      Text(
                        '${t.bateria}%',
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                      ),
                    ],
                  ),
                  if (seca)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppTheme.dangerRed.withAlpha(20),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.bolt_rounded, size: 14, color: AppTheme.dangerRed),
                          SizedBox(width: 4),
                          Text(
                            'Irrigação Acionada',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.dangerRed,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

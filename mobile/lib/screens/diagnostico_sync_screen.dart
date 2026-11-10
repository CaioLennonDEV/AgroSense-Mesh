import 'package:flutter/material.dart';
import '../models/evento_irrigacao.dart';
import '../models/registro_telemetria.dart';
import '../repositories/telemetria_repository.dart';
import '../services/app_service_locator.dart';
import '../theme/app_theme.dart';
import '../widgets/app_drawer.dart';
import '../widgets/responsive_layout.dart';

/// Rota 10: Painel de Diagnóstico de Rede e Sincronização Offline-First.
///
/// Atende ao **Requisito 1 e 2** da AP2B:
/// - Feedback visual de conectividade.
/// - Orquestração e visualização da fila pendente local (SQLite).
class DiagnosticoSyncScreen extends StatefulWidget {
  const DiagnosticoSyncScreen({super.key});

  @override
  State<DiagnosticoSyncScreen> createState() => _DiagnosticoSyncScreenState();
}

class _DiagnosticoSyncScreenState extends State<DiagnosticoSyncScreen> {
  bool _isLoading = true;
  bool _sincronizando = false;
  List<RegistroTelemetria> _telemetriasPendentes = [];
  List<EventoIrrigacao> _irrigacoesPendentes = [];
  String? _ultimoResultado;

  @override
  void initState() {
    super.initState();
    _carregarPendencias();
  }

  Future<void> _carregarPendencias() async {
    setState(() => _isLoading = true);
    final repo = AppServiceLocator.instance.repository;
    try {
      // Puxa atualizações do cluster e lê pendências
      await repo.listarTelemetrias();
      final t = await repo.listarTelemetriasPendentes();
      final i = await repo.listarIrrigacoesPendentes();
      if (mounted) {
        setState(() {
          _telemetriasPendentes = t;
          _irrigacoesPendentes = i;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _executarSincronizacao() async {
    setState(() => _sincronizando = true);
    final repo = AppServiceLocator.instance.repository;

    try {
      final SyncResult resultado = await repo.sincronizarTudo();

      if (!mounted) return;

      setState(() {
        _ultimoResultado = resultado.mensagem;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(resultado.mensagem),
          backgroundColor: resultado.falhas == 0 ? AppTheme.syncGreen : AppTheme.pendingOrange,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          duration: const Duration(seconds: 4),
        ),
      );

      await _carregarPendencias();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Falha na sincronização: $e'),
          backgroundColor: AppTheme.dangerRed,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    } finally {
      if (mounted) setState(() => _sincronizando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final totalPendentes = _telemetriasPendentes.length + _irrigacoesPendentes.length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Diagnóstico & Sync'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _carregarPendencias,
          ),
        ],
      ),
      drawer: const AppDrawer(currentRoute: '/sincronizacao'),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: ResponsiveLayout(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Card Status Geral
                    Container(
                      padding: const EdgeInsets.all(22),
                      decoration: BoxDecoration(
                        color: totalPendentes == 0 ? const Color(0xFFECFDF5) : const Color(0xFFFFFBEB),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: totalPendentes == 0 ? const Color(0xFFA7F3D0) : const Color(0xFFFDE68A),
                          width: 1.5,
                        ),
                      ),
                      child: Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: totalPendentes == 0
                                  ? AppTheme.syncGreen.withAlpha(25)
                                  : AppTheme.pendingOrange.withAlpha(25),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              totalPendentes == 0 ? Icons.cloud_done_rounded : Icons.cloud_upload_rounded,
                              size: 40,
                              color: totalPendentes == 0 ? AppTheme.syncGreen : AppTheme.pendingOrange,
                            ),
                          ),
                          const SizedBox(height: 14),
                          Text(
                            totalPendentes == 0
                                ? 'Base Local 100% Sincronizada'
                                : '$totalPendentes registros aguardando envio',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                              color: totalPendentes == 0 ? const Color(0xFF065F46) : const Color(0xFF92400E),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            totalPendentes == 0
                                ? 'Nenhuma pendência na fila do SQLite local.'
                                : 'Os dados estão preservados no SQLite e serão enviados assim que houver rede.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 13,
                              color: totalPendentes == 0 ? const Color(0xFF047857) : const Color(0xFFB45309),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 18),

                    // Botão de Sincronização Manual
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: AppTheme.agroGreenPrimary,
                        elevation: 2,
                        shadowColor: AppTheme.agroGreenPrimary.withAlpha(70),
                      ),
                      icon: _sincronizando
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                            )
                          : const Icon(Icons.sync_rounded),
                      label: Text(
                        _sincronizando ? 'Sincronizando com a Nuvem...' : 'Sincronizar Cloud Agora',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      onPressed: _sincronizando ? null : _executarSincronizacao,
                    ),

                    if (_ultimoResultado != null) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppTheme.cardBorder),
                        ),
                        child: Text(
                          'Último Retorno: $_ultimoResultado',
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: AppTheme.textDark),
                        ),
                      ),
                    ],

                    const SizedBox(height: 24),

                    // Informações de Arquitetura Offline-First
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
                            'Parâmetros da Arquitetura Offline-First',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.textDark),
                          ),
                          const SizedBox(height: 16),
                          _buildParamRow(
                            'Fonte da Verdade:',
                            'SQLite Local (agrosense_mesh.db)',
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            child: Divider(color: Colors.grey.shade100, height: 1),
                          ),
                          _buildParamRow(
                            'Backend Distribuído:',
                            'Cluster Mesh Cloud (/api/telemetry)',
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            child: Divider(color: Colors.grey.shade100, height: 1),
                          ),
                          _buildParamRow(
                            'Timeout de Rede:',
                            '5.0 segundos (resiliente a modo avião)',
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            child: Divider(color: Colors.grey.shade100, height: 1),
                          ),
                          _buildParamRow(
                            'Telemetrias Pendentes:',
                            '${_telemetriasPendentes.length}',
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            child: Divider(color: Colors.grey.shade100, height: 1),
                          ),
                          _buildParamRow(
                            'Irrigações Pendentes:',
                            '${_irrigacoesPendentes.length}',
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Lista Detalhada das Pendências
                    if (_telemetriasPendentes.isNotEmpty) ...[
                      const Text(
                        'Fila de Telemetrias Pendentes',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textDark),
                      ),
                      const SizedBox(height: 10),
                      ..._telemetriasPendentes.map((t) => Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AppTheme.cardBorder),
                            ),
                            child: ListTile(
                              leading: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: AppTheme.pendingOrange.withAlpha(20),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(Icons.cloud_upload_rounded, color: AppTheme.pendingOrange, size: 20),
                              ),
                              title: Text('${t.sensorId} • ${t.zona}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                              subtitle: Text('Umidade: ${t.umidadeSolo}% • Temp: ${t.temperatura}°C', style: const TextStyle(fontSize: 12)),
                              trailing: Text(
                                'ID: ${t.id.split('-').last}',
                                style: const TextStyle(fontSize: 11, color: AppTheme.textMuted),
                              ),
                            ),
                          )),
                    ],

                    if (_irrigacoesPendentes.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      const Text(
                        'Fila de Irrigações Pendentes',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textDark),
                      ),
                      const SizedBox(height: 10),
                      ..._irrigacoesPendentes.map((i) => Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AppTheme.cardBorder),
                            ),
                            child: ListTile(
                              leading: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: AppTheme.waterBlue.withAlpha(20),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(Icons.water_drop_rounded, color: AppTheme.waterBlue, size: 20),
                              ),
                              title: Text('Válvula ${i.zona} (${i.volumeLitros}L)', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                              subtitle: Text(i.motivo, style: const TextStyle(fontSize: 12)),
                              trailing: const Text('⏳', style: TextStyle(fontSize: 14)),
                            ),
                          )),
                    ],
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildParamRow(String label, String valor) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13, color: AppTheme.textMuted)),
        Flexible(
          child: Text(
            valor,
            textAlign: TextAlign.end,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppTheme.textDark),
          ),
        ),
      ],
    );
  }
}

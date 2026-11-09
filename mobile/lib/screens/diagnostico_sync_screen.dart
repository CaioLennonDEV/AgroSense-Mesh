import 'package:flutter/material.dart';
import '../models/evento_irrigacao.dart';
import '../models/registro_telemetria.dart';
import '../repositories/telemetria_repository.dart';
import '../services/app_service_locator.dart';
import '../theme/app_theme.dart';
import '../widgets/app_drawer.dart';

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
          duration: const Duration(seconds: 4),
        ),
      );

      await _carregarPendencias();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Falha na sincronização: $e'), backgroundColor: Colors.red),
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
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Card Status Geral
                  Card(
                    color: totalPendentes == 0 ? Colors.green.shade50 : Colors.amber.shade50,
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        children: [
                          Icon(
                            totalPendentes == 0 ? Icons.cloud_done_rounded : Icons.cloud_queue_rounded,
                            size: 48,
                            color: totalPendentes == 0 ? AppTheme.syncGreen : AppTheme.pendingOrange,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            totalPendentes == 0
                                ? 'Base Local 100% Sincronizada'
                                : '$totalPendentes registros aguardando envio',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            totalPendentes == 0
                                ? 'Nenhuma pendência na fila do SQLite local.'
                                : 'Os dados estão preservados no SQLite e serão enviados assim que online.',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Botão de Sincronização Manual
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: AppTheme.agroGreenPrimary,
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
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: Text(
                        'Último Retorno: $_ultimoResultado',
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                      ),
                    ),
                  ],

                  const SizedBox(height: 24),

                  // Informações de Arquitetura Offline-First
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Parâmetros da Arquitetura Offline-First',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                          const SizedBox(height: 12),
                          _buildParamRow(
                            'Fonte da Verdade:',
                            'SQLite Local (agrosense_mesh.db)',
                          ),
                          const Divider(height: 16),
                          _buildParamRow(
                            'Endpoint REST:',
                            'https://jsonplaceholder.typicode.com/posts',
                          ),
                          const Divider(height: 16),
                          _buildParamRow(
                            'Timeout de Rede:',
                            '5.0 segundos (resiliente a modo avião)',
                          ),
                          const Divider(height: 16),
                          _buildParamRow(
                            'Telemetrias Pendentes:',
                            '${_telemetriasPendentes.length}',
                          ),
                          const Divider(height: 16),
                          _buildParamRow(
                            'Irrigações Pendentes:',
                            '${_irrigacoesPendentes.length}',
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Lista Detalhada das Pendências
                  if (_telemetriasPendentes.isNotEmpty) ...[
                    const Text(
                      'Fila de Telemetrias Pendentes',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    ..._telemetriasPendentes.map((t) => Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: ListTile(
                            leading: const Icon(Icons.cloud_upload_rounded, color: AppTheme.pendingOrange),
                            title: Text('${t.sensorId} • ${t.zona}'),
                            subtitle: Text('Umidade: ${t.umidadeSolo}% • Temp: ${t.temperatura}°C'),
                            trailing: Text(
                              'ID: ${t.id.split('-').last}',
                              style: const TextStyle(fontSize: 11, color: Colors.grey),
                            ),
                          ),
                        )),
                  ],

                  if (_irrigacoesPendentes.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    const Text(
                      'Fila de Irrigações Pendentes',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    ..._irrigacoesPendentes.map((i) => Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: ListTile(
                            leading: const Icon(Icons.water_drop_rounded, color: Colors.blue),
                            title: Text('Válvula ${i.zona} (${i.volumeLitros}L)'),
                            subtitle: Text(i.motivo),
                            trailing: const Text('⏳', style: TextStyle(fontSize: 14)),
                          ),
                        )),
                  ],
                ],
              ),
            ),
    );
  }

  Widget _buildParamRow(String label, String valor) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13)),
        Flexible(
          child: Text(
            valor,
            textAlign: TextAlign.end,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
          ),
        ),
      ],
    );
  }
}


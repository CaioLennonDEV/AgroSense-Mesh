import 'package:flutter/material.dart';
import '../models/evento_irrigacao.dart';
import '../services/app_service_locator.dart';
import '../theme/app_theme.dart';
import '../widgets/app_drawer.dart';
import '../widgets/responsive_layout.dart';
import '../widgets/sync_badge.dart';

/// Rota 6: Histórico de Acionamentos de Válvulas de Irrigação.
class IrrigacaoHistoricoScreen extends StatefulWidget {
  const IrrigacaoHistoricoScreen({super.key});

  @override
  State<IrrigacaoHistoricoScreen> createState() => _IrrigacaoHistoricoScreenState();
}

class _IrrigacaoHistoricoScreenState extends State<IrrigacaoHistoricoScreen> {
  bool _isLoading = true;
  List<EventoIrrigacao> _irrigacoes = [];

  @override
  void initState() {
    super.initState();
    _carregarIrrigacoes();
  }

  Future<void> _carregarIrrigacoes() async {
    setState(() => _isLoading = true);
    try {
      final lista = await AppServiceLocator.instance.repository.listarIrrigacoes();
      if (mounted) {
        setState(() {
          _irrigacoes = lista;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final volumeTotal = _irrigacoes.fold<double>(0.0, (acc, item) => acc + item.volumeLitros);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Histórico de Irrigação'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _carregarIrrigacoes,
          ),
        ],
      ),
      drawer: const AppDrawer(currentRoute: '/irrigacao'),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppTheme.waterBlue,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.water_drop_rounded),
        label: const Text('Acionar Válvula'),
        onPressed: () async {
          await Navigator.pushNamed(context, '/irrigacao/novo');
          _carregarIrrigacoes();
        },
      ),
      body: Column(
        children: [
          // Resumo Consolidado de Consumo Hídrico
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: const Color(0xFFF0F9FF),
              border: Border(bottom: BorderSide(color: Colors.blue.shade100, width: 1)),
            ),
            child: ResponsiveLayout(
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppTheme.waterBlue.withAlpha(25),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.water_drop_rounded, color: AppTheme.waterBlue, size: 24),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Volume Hídrico Total Despejado',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF0369A1)),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${volumeTotal.toStringAsFixed(1)} Litros (${_irrigacoes.length} acionamentos registrados)',
                          style: TextStyle(fontSize: 12, color: Colors.blue.shade900),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _irrigacoes.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.water_drop_outlined, size: 48, color: Colors.grey.shade400),
                            const SizedBox(height: 12),
                            const Text(
                              'Nenhum evento de irrigação registrado.',
                              style: TextStyle(color: AppTheme.textMuted, fontSize: 14),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _carregarIrrigacoes,
                        child: ResponsiveLayout(
                          child: ListView.builder(
                            padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
                            itemCount: _irrigacoes.length,
                            itemBuilder: (context, index) {
                              final item = _irrigacoes[index];
                              return Dismissible(
                                key: Key(item.id),
                                direction: DismissDirection.endToStart,
                                background: Container(
                                  margin: const EdgeInsets.only(bottom: 12),
                                  alignment: Alignment.centerRight,
                                  padding: const EdgeInsets.only(right: 20),
                                  decoration: BoxDecoration(
                                    color: AppTheme.dangerRed,
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: const Icon(Icons.delete_forever_rounded, color: Colors.white, size: 24),
                                ),
                                onDismissed: (_) async {
                                  await AppServiceLocator.instance.repository
                                      .removerIrrigacao(item.id);
                                  if (mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: const Text('Registro de irrigação removido do SQLite.'),
                                        backgroundColor: AppTheme.textDark,
                                        behavior: SnackBarBehavior.floating,
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                      ),
                                    );
                                  }
                                  _carregarIrrigacoes();
                                },
                                child: Container(
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
                                            Row(
                                              children: [
                                                Container(
                                                  padding: const EdgeInsets.all(6),
                                                  decoration: BoxDecoration(
                                                    color: (item.valvulaAcionada ? AppTheme.waterBlue : Colors.grey)
                                                        .withAlpha(20),
                                                    borderRadius: BorderRadius.circular(8),
                                                  ),
                                                  child: Icon(
                                                    item.valvulaAcionada
                                                        ? Icons.water_drop_rounded
                                                        : Icons.block_rounded,
                                                    color: item.valvulaAcionada
                                                        ? AppTheme.waterBlue
                                                        : Colors.grey,
                                                    size: 20,
                                                  ),
                                                ),
                                                const SizedBox(width: 10),
                                                Text(
                                                  'Válvula ${item.zona}',
                                                  style: const TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 16,
                                                    color: AppTheme.textDark,
                                                  ),
                                                ),
                                              ],
                                            ),
                                            SyncBadge(sincronizado: item.sincronizado),
                                          ],
                                        ),
                                        const SizedBox(height: 10),
                                        Text(
                                          item.motivo,
                                          style: const TextStyle(fontSize: 13, color: AppTheme.textMuted),
                                        ),
                                        const SizedBox(height: 12),
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                              decoration: BoxDecoration(
                                                color: Colors.blue.shade50,
                                                borderRadius: BorderRadius.circular(8),
                                              ),
                                              child: Text(
                                                'Volume: ${item.volumeLitros.toStringAsFixed(1)}L',
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  color: AppTheme.waterBlue,
                                                  fontSize: 12,
                                                ),
                                              ),
                                            ),
                                            Text(
                                              '${item.timestamp.hour.toString().padLeft(2, '0')}:${item.timestamp.minute.toString().padLeft(2, '0')} • ${item.timestamp.day.toString().padLeft(2, '0')}/${item.timestamp.month.toString().padLeft(2, '0')}',
                                              style: const TextStyle(
                                                fontSize: 11,
                                                color: AppTheme.textMuted,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}

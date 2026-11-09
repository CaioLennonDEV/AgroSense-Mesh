import 'package:flutter/material.dart';
import '../models/evento_irrigacao.dart';
import '../services/app_service_locator.dart';
import '../theme/app_theme.dart';
import '../widgets/app_drawer.dart';
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
        backgroundColor: Colors.blue.shade700,
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
            padding: const EdgeInsets.all(16),
            color: Colors.blue.shade50,
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: Colors.blue.shade100,
                  child: Icon(Icons.water_rounded, color: Colors.blue.shade800),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Volume Hídrico Total Despejado',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                      Text(
                        '${volumeTotal.toStringAsFixed(1)} Litros (${_irrigacoes.length} acionamentos)',
                        style: TextStyle(fontSize: 12, color: Colors.blue.shade900),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),

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
                            const Text('Nenhum evento de irrigação registrado.'),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _carregarIrrigacoes,
                        child: ListView.builder(
                          padding: const EdgeInsets.all(12),
                          itemCount: _irrigacoes.length,
                          itemBuilder: (context, index) {
                            final item = _irrigacoes[index];
                            return Dismissible(
                              key: Key(item.id),
                              direction: DismissDirection.endToStart,
                              background: Container(
                                alignment: Alignment.centerRight,
                                padding: const EdgeInsets.only(right: 20),
                                decoration: BoxDecoration(
                                  color: Colors.red.shade400,
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: const Icon(Icons.delete_rounded, color: Colors.white),
                              ),
                              onDismissed: (_) async {
                                await AppServiceLocator.instance.repository
                                    .removerIrrigacao(item.id);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Registro de irrigação removido.')),
                                );
                                _carregarIrrigacoes();
                              },
                              child: Card(
                                margin: const EdgeInsets.only(bottom: 10),
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
                                              Icon(
                                                item.valvulaAcionada
                                                    ? Icons.water_drop_rounded
                                                    : Icons.block_rounded,
                                                color: item.valvulaAcionada
                                                    ? Colors.blue.shade700
                                                    : Colors.grey,
                                                size: 20,
                                              ),
                                              const SizedBox(width: 8),
                                              Text(
                                                'Válvula ${item.zona}',
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 16,
                                                ),
                                              ),
                                            ],
                                          ),
                                          SyncBadge(sincronizado: item.sincronizado),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        item.motivo,
                                        style: TextStyle(fontSize: 13, color: Colors.grey.shade800),
                                      ),
                                      const SizedBox(height: 8),
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            'Volume: ${item.volumeLitros.toStringAsFixed(1)}L',
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              color: Colors.blue.shade800,
                                              fontSize: 12,
                                            ),
                                          ),
                                          Text(
                                            '${item.timestamp.hour.toString().padLeft(2, '0')}:${item.timestamp.minute.toString().padLeft(2, '0')} - ${item.timestamp.day}/${item.timestamp.month}',
                                            style: TextStyle(
                                              fontSize: 11,
                                              color: Colors.grey.shade600,
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
        ],
      ),
    );
  }
}


import 'package:flutter/material.dart';
import '../models/registro_telemetria.dart';
import '../services/app_service_locator.dart';
import '../theme/app_theme.dart';
import '../widgets/app_drawer.dart';
import '../widgets/moisture_indicator.dart';
import '../widgets/sync_badge.dart';

/// Rota 3: Listagem de Leituras de Sensores com `ListView.builder`, `Dismissible` e filtros.
class LeiturasListScreen extends StatefulWidget {
  const LeiturasListScreen({super.key});

  @override
  State<LeiturasListScreen> createState() => _LeiturasListScreenState();
}

class _LeiturasListScreenState extends State<LeiturasListScreen> {
  bool _isLoading = true;
  List<RegistroTelemetria> _todas = [];
  String _filtroZona = 'Todas';

  final List<String> _zonas = ['Todas', 'Zona A', 'Zona B', 'Zona C', 'Zona D', 'Zona E'];

  @override
  void initState() {
    super.initState();
    _carregarLeituras();
  }

  Future<void> _carregarLeituras() async {
    setState(() => _isLoading = true);
    try {
      final lista = await AppServiceLocator.instance.repository.listarTelemetrias();
      if (mounted) {
        setState(() {
          _todas = lista;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  List<RegistroTelemetria> get _filtradas {
    if (_filtroZona == 'Todas') return _todas;
    return _todas.where((t) => t.zona == _filtroZona).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Leituras de Solo'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Recarregar',
            onPressed: _carregarLeituras,
          ),
        ],
      ),
      drawer: const AppDrawer(currentRoute: '/leituras'),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppTheme.agroGreenPrimary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Nova Leitura'),
        onPressed: () async {
          await Navigator.pushNamed(context, '/leituras/novo');
          _carregarLeituras();
        },
      ),
      body: Column(
        children: [
          // Filtro por Zona
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: Colors.white,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _zonas.map((z) {
                  final isSelected = _filtroZona == z;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      selected: isSelected,
                      label: Text(z),
                      selectedColor: AppTheme.agroGreenPrimary.withAlpha(30),
                      labelStyle: TextStyle(
                        color: isSelected ? AppTheme.agroGreenPrimary : Colors.grey.shade800,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                      onSelected: (_) => setState(() => _filtroZona = z),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
          const Divider(height: 1),

          // Listagem com ListView.builder
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filtradas.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.sensors_off_rounded, size: 48, color: Colors.grey.shade400),
                            const SizedBox(height: 12),
                            Text(
                              'Nenhuma leitura encontrada para $_filtroZona',
                              style: TextStyle(color: Colors.grey.shade600),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _carregarLeituras,
                        child: ListView.builder(
                          padding: const EdgeInsets.all(12),
                          itemCount: _filtradas.length,
                          itemBuilder: (context, index) {
                            final item = _filtradas[index];
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
                                child: const Icon(Icons.delete_sweep_rounded, color: Colors.white),
                              ),
                              confirmDismiss: (_) async {
                                return await showDialog<bool>(
                                      context: context,
                                      builder: (ctx) => AlertDialog(
                                        title: const Text('Excluir Leitura?'),
                                        content: Text(
                                            'Deseja remover o registro ${item.sensorId} do SQLite?'),
                                        actions: [
                                          TextButton(
                                            onPressed: () => Navigator.pop(ctx, false),
                                            child: const Text('Cancelar'),
                                          ),
                                          ElevatedButton(
                                            style: ElevatedButton.styleFrom(
                                                backgroundColor: Colors.red),
                                            onPressed: () => Navigator.pop(ctx, true),
                                            child: const Text('Excluir'),
                                          ),
                                        ],
                                      ),
                                    ) ??
                                    false;
                              },
                              onDismissed: (_) async {
                                await AppServiceLocator.instance.repository
                                    .removerTelemetria(item.id);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Leitura ${item.sensorId} excluída do banco local.'),
                                    action: SnackBarAction(
                                      label: 'OK',
                                      onPressed: () {},
                                    ),
                                  ),
                                );
                                _carregarLeituras();
                              },
                              child: Card(
                                margin: const EdgeInsets.only(bottom: 10),
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(16),
                                  onTap: () {
                                    Navigator.pushNamed(
                                      context,
                                      '/leituras/detalhes',
                                      arguments: item,
                                    );
                                  },
                                  child: Padding(
                                    padding: const EdgeInsets.all(16),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(
                                              '${item.sensorId} • ${item.zona}',
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 16,
                                              ),
                                            ),
                                            SyncBadge(sincronizado: item.sincronizado),
                                          ],
                                        ),
                                        const SizedBox(height: 12),
                                        MoistureIndicator(umidade: item.umidadeSolo),
                                        const SizedBox(height: 8),
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(
                                              'Temp: ${item.temperatura.toStringAsFixed(1)}°C | Bat: ${item.nivelBateria}%',
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: Colors.grey.shade600,
                                              ),
                                            ),
                                            const Icon(Icons.arrow_forward_ios_rounded,
                                                size: 14, color: Colors.grey),
                                          ],
                                        ),
                                      ],
                                    ),
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


import 'package:flutter/material.dart';
import '../models/registro_telemetria.dart';
import '../services/app_service_locator.dart';
import '../theme/app_theme.dart';
import '../widgets/app_drawer.dart';
import '../widgets/moisture_indicator.dart';
import '../widgets/responsive_layout.dart';
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
          // ── Filtro de Zonas ───────────────────────────────────────────
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(bottom: BorderSide(color: AppTheme.cardBorder, width: 1)),
            ),
            child: ResponsiveLayout(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: _zonas.map((z) {
                    final selecionado = _filtroZona == z;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: FilterChip(
                        label: Text(z),
                        selected: selecionado,
                        selectedColor: AppTheme.agroGreenPrimary.withAlpha(25),
                        checkmarkColor: AppTheme.agroGreenPrimary,
                        labelStyle: TextStyle(
                          color: selecionado ? AppTheme.agroGreenPrimary : AppTheme.textDark,
                          fontWeight: selecionado ? FontWeight.bold : FontWeight.w500,
                          fontSize: 13,
                        ),
                        backgroundColor: const Color(0xFFF1F5F9),
                        side: BorderSide(
                          color: selecionado ? AppTheme.agroGreenPrimary : Colors.transparent,
                        ),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        onSelected: (val) {
                          setState(() => _filtroZona = z);
                        },
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
          ),

          // ── Lista Principal com ListView.builder e Dismissible ────────
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filtradas.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.filter_list_off_rounded, size: 50, color: Colors.grey.shade400),
                            const SizedBox(height: 12),
                            Text(
                              'Nenhuma leitura para "$_filtroZona"',
                              style: const TextStyle(fontSize: 15, color: AppTheme.textMuted),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _carregarLeituras,
                        child: ResponsiveLayout(
                          child: ListView.builder(
                            padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
                            itemCount: _filtradas.length,
                            itemBuilder: (context, index) {
                              final item = _filtradas[index];
                              return Dismissible(
                                key: Key('telemetria_${item.id}_${item.dataHora.toIso8601String()}'),
                                direction: DismissDirection.endToStart,
                                background: Container(
                                  margin: const EdgeInsets.only(bottom: 12),
                                  decoration: BoxDecoration(
                                    color: AppTheme.dangerRed,
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  alignment: Alignment.centerRight,
                                  padding: const EdgeInsets.only(right: 24),
                                  child: const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.delete_forever_rounded, color: Colors.white, size: 24),
                                      SizedBox(width: 8),
                                      Text(
                                        'Remover do SQLite',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                onDismissed: (direction) async {
                                  final deletado = item;
                                  if (item.id != null) {
                                    await AppServiceLocator.instance.repository
                                        .removerTelemetria(item.id!);
                                  }
                                  setState(() {
                                    _todas.removeWhere((t) => t.id == deletado.id);
                                  });
                                  if (mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('Leitura ${deletado.sensorId} removida do banco local.'),
                                        backgroundColor: AppTheme.textDark,
                                        behavior: SnackBarBehavior.floating,
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                      ),
                                    );
                                  }
                                },
                                child: Container(
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
                                      Navigator.pushNamed(context, '/leituras/detalhes', arguments: item);
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
                                                      color: AppTheme.agroGreenPrimary.withAlpha(20),
                                                      borderRadius: BorderRadius.circular(8),
                                                    ),
                                                    child: Text(
                                                      item.sensorId,
                                                      style: const TextStyle(
                                                        fontWeight: FontWeight.bold,
                                                        fontSize: 13,
                                                        color: AppTheme.agroGreenPrimary,
                                                      ),
                                                    ),
                                                  ),
                                                  const SizedBox(width: 8),
                                                  Container(
                                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                                    decoration: BoxDecoration(
                                                      color: const Color(0xFFF1F5F9),
                                                      borderRadius: BorderRadius.circular(6),
                                                    ),
                                                    child: Text(
                                                      item.zona,
                                                      style: TextStyle(
                                                        fontSize: 12,
                                                        fontWeight: FontWeight.w600,
                                                        color: Colors.grey.shade700,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              SyncBadge(sincronizado: item.sincronizado),
                                            ],
                                          ),
                                          const SizedBox(height: 12),
                                          MoistureIndicator(umidade: item.umidadeSolo),
                                          const SizedBox(height: 12),
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              Row(
                                                children: [
                                                  Icon(Icons.thermostat_rounded, size: 16, color: Colors.grey.shade600),
                                                  const SizedBox(width: 4),
                                                  Text(
                                                    '${item.temperatura.toStringAsFixed(1)}°C',
                                                    style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                                                  ),
                                                  const SizedBox(width: 14),
                                                  Icon(Icons.battery_charging_full_rounded, size: 16, color: Colors.grey.shade600),
                                                  const SizedBox(width: 4),
                                                  Text(
                                                    '${item.bateria}%',
                                                    style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                                                  ),
                                                ],
                                              ),
                                              Row(
                                                children: [
                                                  Text(
                                                    '${item.dataHora.hour.toString().padLeft(2, '0')}:${item.dataHora.minute.toString().padLeft(2, '0')}',
                                                    style: const TextStyle(fontSize: 11, color: AppTheme.textMuted),
                                                  ),
                                                  const SizedBox(width: 4),
                                                  const Icon(Icons.chevron_right_rounded, size: 16, color: Colors.grey),
                                                ],
                                              ),
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
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import '../models/registro_telemetria.dart';
import '../services/app_service_locator.dart';
import '../theme/app_theme.dart';
import '../widgets/app_drawer.dart';
import '../widgets/responsive_layout.dart';

/// Rota 8: Visão de Campo e Zonas de Plantio (Zonas A, B e C).
class MapaZonasScreen extends StatefulWidget {
  const MapaZonasScreen({super.key});

  @override
  State<MapaZonasScreen> createState() => _MapaZonasScreenState();
}

class _MapaZonasScreenState extends State<MapaZonasScreen> {
  bool _isLoading = true;
  List<RegistroTelemetria> _telemetrias = [];

  final List<String> _zonas = ['Zona A', 'Zona B', 'Zona C'];

  final Map<String, String> _descricoes = {
    'Zona A': 'Talhão Norte • Cultura de Café Arábica',
    'Zona B': 'Talhão Sul • Área de Pastagem & Silagem',
    'Zona C': 'Talhão Leste • Hortaliças & Estufas Climatizadas',
  };

  final Map<String, Color> _coresZona = {
    'Zona A': const Color(0xFF065F46),
    'Zona B': const Color(0xFF0284C7),
    'Zona C': const Color(0xFF7C3AED),
  };

  @override
  void initState() {
    super.initState();
    _carregarDados();
  }

  Future<void> _carregarDados() async {
    setState(() => _isLoading = true);
    try {
      final t = await AppServiceLocator.instance.repository.listarTelemetrias();
      if (mounted) {
        setState(() {
          _telemetrias = t;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Zonas de Plantio (A-C)'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _carregarDados,
          ),
        ],
      ),
      drawer: const AppDrawer(currentRoute: '/zonas'),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _carregarDados,
              child: ResponsiveLayout(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                  itemCount: _zonas.length,
                  itemBuilder: (context, index) {
                    final zonaNome = _zonas[index];
                    final leiturasZona = _telemetrias.where((t) => t.zona == zonaNome).toList();
                    final corZona = _coresZona[zonaNome] ?? AppTheme.agroGreenPrimary;
                    final descricao = _descricoes[zonaNome] ?? 'Talhão Agrícola';

                    final mediaUmidade = leiturasZona.isEmpty
                        ? 0.0
                        : leiturasZona.map((t) => t.umidadeSolo).reduce((a, b) => a + b) / leiturasZona.length;

                    final isCritica = leiturasZona.isNotEmpty && mediaUmidade < 40.0;

                    return Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isCritica ? AppTheme.dangerRed.withAlpha(90) : AppTheme.cardBorder,
                          width: isCritica ? 1.5 : 1,
                        ),
                        boxShadow: AppTheme.softShadow,
                      ),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(16),
                        onTap: () {
                          Navigator.pushNamed(
                            context,
                            '/zonas/detalhes',
                            arguments: {
                              'zona': zonaNome,
                              'leituras': leiturasZona,
                              'mediaUmidade': mediaUmidade,
                            },
                          );
                        },
                        child: Padding(
                          padding: const EdgeInsets.all(18),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(10),
                                        decoration: BoxDecoration(
                                          color: corZona.withAlpha(20),
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Icon(Icons.grid_view_rounded, color: corZona, size: 24),
                                      ),
                                      const SizedBox(width: 14),
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            zonaNome,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 18,
                                              color: AppTheme.textDark,
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            descricao,
                                            style: const TextStyle(
                                              fontSize: 12,
                                              color: AppTheme.textMuted,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: isCritica
                                          ? AppTheme.dangerRed.withAlpha(20)
                                          : AppTheme.agroGreenSecondary.withAlpha(20),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: isCritica
                                            ? AppTheme.dangerRed.withAlpha(80)
                                            : AppTheme.agroGreenSecondary.withAlpha(80),
                                        width: 1,
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          isCritica ? Icons.warning_amber_rounded : Icons.check_circle_outline_rounded,
                                          size: 13,
                                          color: isCritica ? AppTheme.dangerRed : AppTheme.agroGreenSecondary,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          isCritica ? 'CRÍTICA (<40%)' : 'NORMAL',
                                          style: TextStyle(
                                            color: isCritica ? AppTheme.dangerRed : AppTheme.agroGreenSecondary,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 11,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                child: Divider(color: Colors.grey.shade100, height: 1),
                              ),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      const Icon(Icons.sensors_rounded, size: 16, color: AppTheme.textMuted),
                                      const SizedBox(width: 6),
                                      Text(
                                        '${leiturasZona.length} Registros',
                                        style: const TextStyle(fontSize: 13, color: AppTheme.textMuted, fontWeight: FontWeight.w500),
                                      ),
                                    ],
                                  ),
                                  Row(
                                    children: [
                                      Icon(Icons.water_drop_rounded, size: 16, color: isCritica ? AppTheme.dangerRed : AppTheme.waterBlue),
                                      const SizedBox(width: 4),
                                      Text(
                                        'Média: ${mediaUmidade > 0 ? mediaUmidade.toStringAsFixed(1) : "--"}%',
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.bold,
                                          color: isCritica ? AppTheme.dangerRed : AppTheme.textDark,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      const Icon(Icons.chevron_right_rounded, size: 18, color: Colors.grey),
                                    ],
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
    );
  }
}

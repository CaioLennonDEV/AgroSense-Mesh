import 'package:flutter/material.dart';
import '../models/evento_irrigacao.dart';
import '../services/app_service_locator.dart';
import '../theme/app_theme.dart';
import '../widgets/responsive_layout.dart';

/// Rota 7: Formulário para Acionamento Manual Forçado de Válvula de Irrigação.
class NovoComandoIrrigacaoScreen extends StatefulWidget {
  const NovoComandoIrrigacaoScreen({super.key});

  @override
  State<NovoComandoIrrigacaoScreen> createState() => _NovoComandoIrrigacaoScreenState();
}

class _NovoComandoIrrigacaoScreenState extends State<NovoComandoIrrigacaoScreen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _volumeController;
  late final TextEditingController _motivoController;

  String _zonaSelecionada = 'Zona A';
  bool _salvando = false;

  final List<String> _zonas = ['Zona A', 'Zona B', 'Zona C', 'Zona D', 'Zona E'];

  @override
  void initState() {
    super.initState();
    _volumeController = TextEditingController(text: '100.0');
    _motivoController = TextEditingController(text: 'Comando Manual de Campo via Aplicativo');
  }

  @override
  void dispose() {
    _volumeController.dispose();
    _motivoController.dispose();
    super.dispose();
  }

  Future<void> _acionarValvula() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _salvando = true);

    final volume = double.parse(_volumeController.text.trim().replaceAll(',', '.'));
    final evento = EventoIrrigacao(
      id: 'IRR-MANUAL-${DateTime.now().millisecondsSinceEpoch}',
      zona: _zonaSelecionada,
      valvulaAcionada: true,
      volumeLitros: volume,
      motivo: _motivoController.text.trim(),
      timestamp: DateTime.now(),
      sincronizado: false,
    );

    try {
      final res = await AppServiceLocator.instance.repository.registrarEventoIrrigacao(evento);

      if (!mounted) return;

      final msg = res.sincronizado
          ? 'Comando registrado localmente e confirmado pelo Gateway!'
          : 'Comando gravado no SQLite (Offline-First: pendente de envio).';

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(msg),
          backgroundColor: res.sincronizado ? AppTheme.syncGreen : AppTheme.pendingOrange,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );

      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro: $e'),
          backgroundColor: AppTheme.dangerRed,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    } finally {
      if (mounted) setState(() => _salvando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Acionar Válvula Manual'),
        backgroundColor: AppTheme.waterBlue,
      ),
      body: SingleChildScrollView(
        child: ResponsiveLayout(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Setor
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
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppTheme.waterBlue.withAlpha(20),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(Icons.grid_view_rounded, color: AppTheme.waterBlue, size: 20),
                          ),
                          const SizedBox(width: 10),
                          const Text(
                            'Seleção de Setor de Irrigação',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.textDark),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),
                      DropdownButtonFormField<String>(
                        value: _zonaSelecionada,
                        decoration: const InputDecoration(
                          labelText: 'Zona Alvo *',
                          prefixIcon: Icon(Icons.location_on_rounded, color: AppTheme.waterBlue),
                        ),
                        items: _zonas.map((z) {
                          return DropdownMenuItem(value: z, child: Text(z));
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) setState(() => _zonaSelecionada = val);
                        },
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 18),

                // Parâmetros
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
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.blue.shade50,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(Icons.water_drop_rounded, color: AppTheme.waterBlue, size: 20),
                          ),
                          const SizedBox(width: 10),
                          const Text(
                            'Parâmetros do Disparo Hídrico',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.textDark),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),

                      TextFormField(
                        controller: _volumeController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: const InputDecoration(
                          labelText: 'Volume Estimado (Litros) *',
                          prefixIcon: Icon(Icons.opacity_rounded, color: AppTheme.waterBlue),
                          hintText: 'Ex: 150.0',
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Informe o volume em litros';
                          }
                          final v = double.tryParse(value.trim().replaceAll(',', '.'));
                          if (v == null) return 'Valor numérico inválido';
                          if (v <= 0) return 'O volume deve ser superior a zero';
                          return null;
                        },
                      ),

                      const SizedBox(height: 16),

                      TextFormField(
                        controller: _motivoController,
                        maxLines: 2,
                        decoration: const InputDecoration(
                          labelText: 'Motivo / Justificativa do Acionamento *',
                          prefixIcon: Icon(Icons.notes_rounded, color: AppTheme.waterBlue),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Descreva o motivo do acionamento';
                          }
                          return null;
                        },
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.waterBlue,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    elevation: 2,
                    shadowColor: AppTheme.waterBlue.withAlpha(80),
                  ),
                  icon: _salvando
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : const Icon(Icons.water_drop_rounded),
                  label: Text(
                    _salvando ? 'Processando Disparo...' : 'Confirmar Acionamento',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  onPressed: _salvando ? null : _acionarValvula,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

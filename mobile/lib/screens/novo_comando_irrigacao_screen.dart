import 'package:flutter/material.dart';
import '../models/evento_irrigacao.dart';
import '../services/app_service_locator.dart';
import '../theme/app_theme.dart';

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

  final List<String> _zonas = ['Zona A', 'Zona B', 'Zona C'];

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
        ),
      );

      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro: $e'), backgroundColor: Colors.red),
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
        backgroundColor: Colors.blue.shade800,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Seleção de Setor de Irrigação',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        value: _zonaSelecionada,
                        decoration: const InputDecoration(
                          labelText: 'Zona Alvo *',
                          prefixIcon: Icon(Icons.grid_view_rounded),
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
              ),

              const SizedBox(height: 16),

              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Parâmetros do Disparo Hídrico',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      const SizedBox(height: 16),

                      TextFormField(
                        controller: _volumeController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: const InputDecoration(
                          labelText: 'Volume Estimado (Litros) *',
                          prefixIcon: Icon(Icons.water_drop_rounded),
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
                          prefixIcon: Icon(Icons.notes_rounded),
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
              ),

              const SizedBox(height: 24),

              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.blue.shade800),
                icon: _salvando
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : const Icon(Icons.water_drop_rounded),
                label: Text(_salvando ? 'Processando...' : 'Confirmar Acionamento'),
                onPressed: _salvando ? null : _acionarValvula,
              ),
            ],
          ),
        ),
      ),
    );
  }
}


import 'package:flutter/material.dart';
import '../models/registro_telemetria.dart';
import '../services/app_service_locator.dart';
import '../theme/app_theme.dart';
import '../widgets/responsive_layout.dart';

/// Rota 4: Formulário Estruturado para Cadastro Manual de Leitura de Campo.
///
/// Atende ao **Requisito 1** da AP2B:
/// - Uso de `Form`, `GlobalKey<FormState>`, `TextEditingController` e `TextFormField` com validação real.
class NovaLeituraScreen extends StatefulWidget {
  const NovaLeituraScreen({super.key});

  @override
  State<NovaLeituraScreen> createState() => _NovaLeituraScreenState();
}

class _NovaLeituraScreenState extends State<NovaLeituraScreen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _sensorIdController;
  late final TextEditingController _umidadeController;
  late final TextEditingController _temperaturaController;
  late final TextEditingController _bateriaController;

  String _zonaSelecionada = 'Zona A';
  bool _salvando = false;

  final List<String> _zonas = ['Zona A', 'Zona B', 'Zona C'];

  @override
  void initState() {
    super.initState();
    _sensorIdController = TextEditingController(text: 'SENSOR-A${DateTime.now().millisecond}');
    _umidadeController = TextEditingController(text: '38.5');
    _temperaturaController = TextEditingController(text: '28.0');
    _bateriaController = TextEditingController(text: '95');
  }

  @override
  void dispose() {
    _sensorIdController.dispose();
    _umidadeController.dispose();
    _temperaturaController.dispose();
    _bateriaController.dispose();
    super.dispose();
  }

  Future<void> _submeterFormulario() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _salvando = true);

    final umidade = double.parse(_umidadeController.text.trim().replaceAll(',', '.'));
    final temperatura = double.parse(_temperaturaController.text.trim().replaceAll(',', '.'));
    final bateria = int.parse(_bateriaController.text.trim());

    final telemetria = RegistroTelemetria(
      id: 'TEL-MANUAL-${DateTime.now().millisecondsSinceEpoch}',
      sensorId: _sensorIdController.text.trim().toUpperCase(),
      zona: _zonaSelecionada,
      umidadeSolo: umidade,
      temperatura: temperatura,
      nivelBateria: bateria,
      timestamp: DateTime.now(),
      sincronizado: false,
    );

    try {
      final resultado = await AppServiceLocator.instance.repository.registrarTelemetria(telemetria);

      if (!mounted) return;

      final msg = resultado.sincronizado
          ? 'Leitura persistida localmente e sincronizada com a nuvem!'
          : 'Leitura gravada no SQLite (Pendente de sincronização).';

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(msg),
          backgroundColor: resultado.sincronizado ? AppTheme.syncGreen : AppTheme.pendingOrange,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );

      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao salvar: $e'),
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
        title: const Text('Nova Leitura de Campo'),
      ),
      body: SingleChildScrollView(
        child: ResponsiveLayout(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Cartão 1: Identificação
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
                              color: AppTheme.agroGreenPrimary.withAlpha(20),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(Icons.qr_code_rounded, color: AppTheme.agroGreenPrimary, size: 20),
                          ),
                          const SizedBox(width: 10),
                          const Text(
                            'Identificação e Localização',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.textDark),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),

                      // Campo Sensor ID
                      TextFormField(
                        controller: _sensorIdController,
                        decoration: const InputDecoration(
                          labelText: 'Identificador do Sensor *',
                          prefixIcon: Icon(Icons.sensors_rounded, color: AppTheme.agroGreenPrimary),
                          hintText: 'Ex: SENSOR-A1',
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Informe o ID do sensor';
                          }
                          if (value.trim().length < 3) {
                            return 'O ID deve ter pelo menos 3 caracteres';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Dropdown de Zona
                      DropdownButtonFormField<String>(
                        value: _zonaSelecionada,
                        decoration: const InputDecoration(
                          labelText: 'Zona de Plantio *',
                          prefixIcon: Icon(Icons.grid_view_rounded, color: AppTheme.agroGreenPrimary),
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

                // Cartão 2: Parâmetros de Solo
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
                            child: const Icon(Icons.water_drop_rounded, color: AppTheme.waterBlue, size: 20),
                          ),
                          const SizedBox(width: 10),
                          const Text(
                            'Parâmetros e Leituras de Solo',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppTheme.textDark),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),

                      // Campo Umidade
                      TextFormField(
                        controller: _umidadeController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: const InputDecoration(
                          labelText: 'Umidade do Solo (%) *',
                          prefixIcon: Icon(Icons.water_drop_outlined, color: AppTheme.waterBlue),
                          hintText: '0.0 a 100.0',
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Informe o valor da umidade';
                          }
                          final v = double.tryParse(value.trim().replaceAll(',', '.'));
                          if (v == null) return 'Valor numérico inválido';
                          if (v < 0.0 || v > 100.0) return 'Umidade deve estar entre 0% e 100%';
                          return null;
                        },
                        onChanged: (_) => setState(() {}),
                      ),

                      // Alerta de Acionamento Automático
                      Builder(builder: (ctx) {
                        final umidade = double.tryParse(_umidadeController.text.trim().replaceAll(',', '.'));
                        if (umidade != null && umidade < 40.0) {
                          return Container(
                            margin: const EdgeInsets.only(top: 12),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppTheme.dangerRed.withAlpha(15),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: AppTheme.dangerRed.withAlpha(60)),
                            ),
                            child: const Row(
                              children: [
                                Icon(Icons.warning_amber_rounded, color: AppTheme.dangerRed, size: 20),
                                SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    'Atenção: Como a umidade é inferior a 40%, a válvula de irrigação será ativada automaticamente no SQLite!',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: AppTheme.dangerRed,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        }
                        return const SizedBox.shrink();
                      }),

                      const SizedBox(height: 16),

                      // Campo Temperatura
                      TextFormField(
                        controller: _temperaturaController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: const InputDecoration(
                          labelText: 'Temperatura Ambiente (°C) *',
                          prefixIcon: Icon(Icons.thermostat_rounded, color: Colors.amber),
                          hintText: 'Ex: 27.5',
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Informe a temperatura';
                          }
                          final v = double.tryParse(value.trim().replaceAll(',', '.'));
                          if (v == null) return 'Temperatura inválida';
                          if (v < -20.0 || v > 70.0) return 'Temperatura fora da faixa permitida (-20 a 70°C)';
                          return null;
                        },
                      ),

                      const SizedBox(height: 16),

                      // Campo Bateria
                      TextFormField(
                        controller: _bateriaController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Nível da Bateria do Sensor (%) *',
                          prefixIcon: Icon(Icons.battery_charging_full_rounded, color: AppTheme.agroGreenSecondary),
                          hintText: '0 a 100',
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Informe o nível da bateria';
                          }
                          final v = int.tryParse(value.trim());
                          if (v == null) return 'Valor inteiro inválido';
                          if (v < 0 || v > 100) return 'Bateria deve estar entre 0% e 100%';
                          return null;
                        },
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.agroGreenPrimary,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    elevation: 2,
                    shadowColor: AppTheme.agroGreenPrimary.withAlpha(80),
                  ),
                  icon: _salvando
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : const Icon(Icons.save_rounded),
                  label: Text(
                    _salvando ? 'Gravando no SQLite...' : 'Salvar Leitura (Offline-First)',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  onPressed: _salvando ? null : _submeterFormulario,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

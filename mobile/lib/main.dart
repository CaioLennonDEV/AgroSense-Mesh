import 'package:flutter/material.dart';
import 'screens/dashboard_screen.dart';
import 'screens/detalhe_leitura_screen.dart';
import 'screens/detalhe_zona_screen.dart';
import 'screens/diagnostico_sync_screen.dart';
import 'screens/irrigacao_historico_screen.dart';
import 'screens/leituras_list_screen.dart';
import 'screens/mapa_zonas_screen.dart';
import 'screens/nova_leitura_screen.dart';
import 'screens/novo_comando_irrigacao_screen.dart';
import 'screens/splash_screen.dart';
import 'theme/app_theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const AgroSenseApp());
}

/// Aplicação Central do AgroSense Mesh Mobile.
///
/// Atende ao **Requisito 1** da AP2B:
/// - Implementação de no mínimo 10 rotas integradas utilizando rotas nomeadas.
/// - Configuração do Material Design 3.
class AgroSenseApp extends StatelessWidget {
  const AgroSenseApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AgroSense Mesh',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      initialRoute: '/',
      routes: {
        '/': (context) => const SplashScreen(),
        '/dashboard': (context) => const DashboardScreen(),
        '/leituras': (context) => const LeiturasListScreen(),
        '/leituras/novo': (context) => const NovaLeituraScreen(),
        '/leituras/detalhes': (context) => const DetalheLeituraScreen(),
        '/irrigacao': (context) => const IrrigacaoHistoricoScreen(),
        '/irrigacao/novo': (context) => const NovoComandoIrrigacaoScreen(),
        '/zonas': (context) => const MapaZonasScreen(),
        '/zonas/detalhes': (context) => const DetalheZonaScreen(),
        '/sincronizacao': (context) => const DiagnosticoSyncScreen(),
      },
    );
  }
}


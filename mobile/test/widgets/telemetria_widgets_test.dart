import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../lib/screens/nova_leitura_screen.dart';
import '../../lib/theme/app_theme.dart';
import '../../lib/widgets/app_drawer.dart';
import '../../lib/widgets/moisture_indicator.dart';
import '../../lib/widgets/sync_badge.dart';

void main() {
  group('Testes de Widgets — Componentes Visuais e Formulários (5 Testes)', () {
    testWidgets('1. Deve renderizar SyncBadge com status sincronizado (ícone e texto)', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SyncBadge(sincronizado: true),
          ),
        ),
      );

      expect(find.text('Sincronizado'), findsOneWidget);
      expect(find.byIcon(Icons.cloud_done_rounded), findsOneWidget);
    });

    testWidgets('2. Deve renderizar SyncBadge com status pendente (ícone e texto)', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SyncBadge(sincronizado: false),
          ),
        ),
      );

      expect(find.text('Pendente'), findsOneWidget);
      expect(find.byIcon(Icons.cloud_upload_rounded), findsOneWidget);
    });

    testWidgets('3. Deve renderizar MoistureIndicator com alerta de umidade baixa (< 40%)', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: MoistureIndicator(umidade: 32.5),
          ),
        ),
      );

      expect(find.text('Umidade Baixa (<40%)'), findsOneWidget);
      expect(find.text('32.5%'), findsOneWidget);
      expect(find.byIcon(Icons.warning_amber_rounded), findsOneWidget);
      expect(find.byType(LinearProgressIndicator), findsOneWidget);
    });

    testWidgets('4. Validação de Formulário: Ao submeter formulário com campo em branco deve exibir erro', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: const NovaLeituraScreen(),
        ),
      );

      // Limpa o campo do sensor ID
      final sensorField = find.byType(TextFormField).first;
      await tester.enterText(sensorField, '');
      await tester.pumpAndSettle();

      // Clica no botão de salvar
      final salvarBtn = find.text('Salvar Leitura (Offline-First)');
      await tester.ensureVisible(salvarBtn);
      await tester.tap(salvarBtn);
      await tester.pumpAndSettle();

      // Confirma que a mensagem de validação disparou
      expect(find.text('Informe o ID do sensor'), findsOneWidget);
    });

    testWidgets('5. Deve renderizar AppDrawer com links para Dashboard, Leituras e Sincronização', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            drawer: AppDrawer(currentRoute: '/dashboard'),
            body: Text('Conteudo'),
          ),
        ),
      );

      // Abre o drawer programaticamente
      final scaffoldState = tester.state<ScaffoldState>(find.byType(Scaffold));
      scaffoldState.openDrawer();
      await tester.pumpAndSettle();

      expect(find.text('AgroSense Mesh'), findsOneWidget);
      expect(find.text('Dashboard Geral'), findsOneWidget);
      expect(find.text('Leituras de Sensores'), findsOneWidget);
      expect(find.text('Histórico de Irrigação'), findsOneWidget);
    });
  });
}


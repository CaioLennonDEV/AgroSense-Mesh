import 'package:flutter_test/flutter_test.dart';
import '../../lib/models/evento_irrigacao.dart';

void main() {
  group('Testes de Unidade — Modelo EventoIrrigacao (5 Testes)', () {
    test('1. Deve serializar corretamente para Map compatível com SQLite', () {
      final evento = EventoIrrigacao(
        id: 'IRR-01',
        telemetriaId: 'TEL-01',
        zona: 'Zona B',
        valvulaAcionada: true,
        volumeLitros: 120.0,
        motivo: 'Umidade do solo em 32.0%',
        timestamp: DateTime(2026, 11, 10, 16, 0),
        sincronizado: false,
      );

      final map = evento.toMap();

      expect(map['id'], 'IRR-01');
      expect(map['telemetria_id'], 'TEL-01');
      expect(map['zona'], 'Zona B');
      expect(map['valvula_acionada'], 1);
      expect(map['volume_litros'], 120.0);
      expect(map['sincronizado'], 0);
    });

    test('2. Deve deserializar a partir de Map do SQLite e converter booleano', () {
      final map = {
        'id': 'IRR-02',
        'telemetria_id': 'TEL-02',
        'zona': 'Zona C',
        'valvula_acionada': 1,
        'volume_litros': 200.0,
        'motivo': 'Acionamento de Emergência',
        'timestamp': '2026-11-10T16:30:00.000',
        'sincronizado': 1,
      };

      final evento = EventoIrrigacao.fromMap(map);

      expect(evento.id, 'IRR-02');
      expect(evento.valvulaAcionada, isTrue);
      expect(evento.volumeLitros, 200.0);
      expect(evento.sincronizado, isTrue);
    });

    test('3. Deve suportar telemetriaId nulo para acionamentos manuais avulsos', () {
      final evento = EventoIrrigacao(
        id: 'IRR-03',
        zona: 'Zona A',
        valvulaAcionada: true,
        volumeLitros: 80.0,
        motivo: 'Teste de Vazão Manual',
        timestamp: DateTime.now(),
      );

      expect(evento.telemetriaId, isNull);
      expect(evento.toMap()['telemetria_id'], isNull);
    });

    test('4. Deve gerar cópia com copyWith alterando status de sincronização', () {
      final e1 = EventoIrrigacao(
        id: 'IRR-04',
        zona: 'Zona C',
        valvulaAcionada: true,
        volumeLitros: 100.0,
        motivo: 'Rotina periódica',
        timestamp: DateTime.now(),
        sincronizado: false,
      );

      final e2 = e1.copyWith(sincronizado: true);

      expect(e2.sincronizado, isTrue);
      expect(e1.sincronizado, isFalse);
    });

    test('5. Deve formatar toString() com status da válvula e flag de sync', () {
      final e = EventoIrrigacao(
        id: 'IRR-05',
        zona: 'Zona A',
        valvulaAcionada: true,
        volumeLitros: 50.0,
        motivo: 'Umidade baixa',
        timestamp: DateTime.now(),
        sincronizado: true,
      );

      final str = e.toString();
      expect(str, contains('IRR-05'));
      expect(str, contains('Zona A'));
      expect(str, contains('ABERTA'));
      expect(str, contains('✓ SYNC'));
    });
  });
}


import 'package:flutter_test/flutter_test.dart';
import '../../lib/models/registro_telemetria.dart';

void main() {
  group('Testes de Unidade — Modelo RegistroTelemetria (7 Testes)', () {
    test('1. Deve serializar corretamente para Map compatível com SQLite (booleano 0/1)', () {
      final t = RegistroTelemetria(
        id: 'TEL-01',
        sensorId: 'SENSOR-A1',
        zona: 'Zona A',
        umidadeSolo: 45.5,
        temperatura: 28.0,
        nivelBateria: 90,
        timestamp: DateTime(2026, 11, 10, 14, 30),
        sincronizado: true,
      );

      final map = t.toMap();

      expect(map['id'], 'TEL-01');
      expect(map['sensor_id'], 'SENSOR-A1');
      expect(map['zona'], 'Zona A');
      expect(map['umidade_solo'], 45.5);
      expect(map['temperatura'], 28.0);
      expect(map['nivel_bateria'], 90);
      expect(map['sincronizado'], 1); // 1 = true
    });

    test('2. Deve deserializar a partir de Map do SQLite com sincronizado = 0', () {
      final map = {
        'id': 'TEL-02',
        'sensor_id': 'SENSOR-B2',
        'zona': 'Zona B',
        'umidade_solo': 32.0,
        'temperatura': 31.5,
        'nivel_bateria': 80,
        'timestamp': '2026-11-10T15:00:00.000',
        'sincronizado': 0,
      };

      final t = RegistroTelemetria.fromMap(map);

      expect(t.id, 'TEL-02');
      expect(t.sensorId, 'SENSOR-B2');
      expect(t.umidadeSolo, 32.0);
      expect(t.sincronizado, isFalse);
    });

    test('3. Deve acionar a regra de irrigação (precisaIrrigacao == true) quando umidade < 40%', () {
      final t = RegistroTelemetria(
        id: 'TEL-03',
        sensorId: 'SENSOR-C1',
        zona: 'Zona C',
        umidadeSolo: 39.9,
        temperatura: 29.0,
        nivelBateria: 85,
        timestamp: DateTime.now(),
      );

      expect(t.precisaIrrigacao, isTrue);
    });

    test('4. Não deve acionar irrigação (precisaIrrigacao == false) quando umidade >= 40%', () {
      final t = RegistroTelemetria(
        id: 'TEL-04',
        sensorId: 'SENSOR-D1',
        zona: 'Zona D',
        umidadeSolo: 40.0,
        temperatura: 25.0,
        nivelBateria: 100,
        timestamp: DateTime.now(),
      );

      expect(t.precisaIrrigacao, isFalse);
    });

    test('5. Deve lançar ArgumentError se nível de bateria for menor que 0 ou maior que 100', () {
      expect(
        () => RegistroTelemetria.fromMap({
          'sensor_id': 'SENSOR-X',
          'nivel_bateria': 150,
          'umidade_solo': 50.0,
        }),
        throwsArgumentError,
      );

      expect(
        () => RegistroTelemetria.fromMap({
          'sensor_id': 'SENSOR-X',
          'nivel_bateria': -5,
          'umidade_solo': 50.0,
        }),
        throwsArgumentError,
      );
    });

    test('6. Deve lançar ArgumentError se umidade do solo for inválida (< 0 ou > 100)', () {
      expect(
        () => RegistroTelemetria.fromMap({
          'sensor_id': 'SENSOR-X',
          'nivel_bateria': 80,
          'umidade_solo': -10.0,
        }),
        throwsArgumentError,
      );

      expect(
        () => RegistroTelemetria.fromMap({
          'sensor_id': 'SENSOR-X',
          'nivel_bateria': 80,
          'umidade_solo': 105.0,
        }),
        throwsArgumentError,
      );
    });

    test('7. Deve gerar cópia com copyWith alterando status de sincronização', () {
      final t1 = RegistroTelemetria(
        id: 'TEL-05',
        sensorId: 'SENSOR-E1',
        zona: 'Zona E',
        umidadeSolo: 60.0,
        temperatura: 22.0,
        nivelBateria: 90,
        timestamp: DateTime.now(),
        sincronizado: false,
      );

      final t2 = t1.copyWith(sincronizado: true);

      expect(t2.id, t1.id);
      expect(t2.sensorId, t1.sensorId);
      expect(t2.sincronizado, isTrue);
      expect(t1.sincronizado, isFalse); // Imutabilidade preservada
    });
  });
}


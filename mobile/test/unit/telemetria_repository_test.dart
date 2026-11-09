import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import '../../lib/datasources/telemetria_local_datasource.dart';
import '../../lib/datasources/telemetria_remote_datasource.dart';
import '../../lib/models/evento_irrigacao.dart';
import '../../lib/models/registro_telemetria.dart';
import '../../lib/repositories/telemetria_repository.dart';

/// Fake Local DataSource em memória para testabilidade sem depender de emulador ou C-FFI.
class FakeLocalDatasource implements TelemetriaLocalDatasource {
  final Map<String, RegistroTelemetria> _telemetrias = {};
  final Map<String, EventoIrrigacao> _irrigacoes = {};

  @override
  Future<void> salvarOuAtualizarTelemetria(RegistroTelemetria t) async {
    _telemetrias[t.id] = t;
  }

  @override
  Future<List<RegistroTelemetria>> listarTodasTelemetrias() async {
    return _telemetrias.values.toList();
  }

  @override
  Future<List<RegistroTelemetria>> listarTelemetriasPendentes() async {
    return _telemetrias.values.where((t) => !t.sincronizado).toList();
  }

  @override
  Future<RegistroTelemetria?> buscarTelemetriaPorId(String id) async {
    return _telemetrias[id];
  }

  @override
  Future<void> removerTelemetriaPorId(String id) async {
    _telemetrias.remove(id);
  }

  @override
  Future<void> salvarOuAtualizarIrrigacao(EventoIrrigacao e) async {
    _irrigacoes[e.id] = e;
  }

  @override
  Future<List<EventoIrrigacao>> listarTodasIrrigacoes() async {
    return _irrigacoes.values.toList();
  }

  @override
  Future<List<EventoIrrigacao>> listarIrrigacoesPendentes() async {
    return _irrigacoes.values.where((i) => !i.sincronizado).toList();
  }

  @override
  Future<void> removerIrrigacaoPorId(String id) async {
    _irrigacoes.remove(id);
  }
}

void main() {
  group('Testes de Unidade — Repositório Offline-First e Fallback de Rede (8 Testes)', () {
    test('1. Deve salvar telemetria imediatamente no banco local com sincronizado: false', () async {
      final fakeLocal = FakeLocalDatasource();
      final mockClient = MockClient((_) async => http.Response('Created', 201));
      final remote = TelemetriaRemoteDatasourceImpl(client: mockClient);
      final repo = TelemetriaRepository(localDatasource: fakeLocal, remoteDatasource: remote);

      final telemetria = RegistroTelemetria(
        id: 'TEL-TEST-01',
        sensorId: 'SENSOR-A1',
        zona: 'Zona A',
        umidadeSolo: 50.0,
        temperatura: 25.0,
        nivelBateria: 100,
        timestamp: DateTime.now(),
      );

      final resultado = await repo.registrarTelemetria(telemetria);

      expect(resultado.id, 'TEL-TEST-01');
      final salvos = await fakeLocal.listarTodasTelemetrias();
      expect(salvos.length, 1);
      expect(salvos.first.id, 'TEL-TEST-01');
    });

    test('2. Deve marcar sincronizado: true quando API remota responder HTTP 201 com sucesso', () async {
      final fakeLocal = FakeLocalDatasource();
      final mockClient = MockClient((_) async => http.Response('{"status": "ok"}', 201));
      final remote = TelemetriaRemoteDatasourceImpl(client: mockClient);
      final repo = TelemetriaRepository(localDatasource: fakeLocal, remoteDatasource: remote);

      final telemetria = RegistroTelemetria(
        id: 'TEL-TEST-02',
        sensorId: 'SENSOR-B1',
        zona: 'Zona B',
        umidadeSolo: 48.0,
        temperatura: 26.0,
        nivelBateria: 95,
        timestamp: DateTime.now(),
      );

      final resultado = await repo.registrarTelemetria(telemetria);

      expect(resultado.sincronizado, isTrue);
      final salvo = await fakeLocal.buscarTelemetriaPorId('TEL-TEST-02');
      expect(salvo?.sincronizado, isTrue);
    });

    test('3. Fallback Offline: Deve manter dado salvo localmente quando API retornar HTTP 500', () async {
      final fakeLocal = FakeLocalDatasource();
      final mockClient = MockClient((_) async => http.Response('Internal Server Error', 500));
      final remote = TelemetriaRemoteDatasourceImpl(client: mockClient);
      final repo = TelemetriaRepository(localDatasource: fakeLocal, remoteDatasource: remote);

      final telemetria = RegistroTelemetria(
        id: 'TEL-TEST-03',
        sensorId: 'SENSOR-C1',
        zona: 'Zona C',
        umidadeSolo: 55.0,
        temperatura: 24.0,
        nivelBateria: 90,
        timestamp: DateTime.now(),
      );

      final resultado = await repo.registrarTelemetria(telemetria);

      expect(resultado.sincronizado, isFalse);
      final listaLocal = await fakeLocal.listarTodasTelemetrias();
      expect(listaLocal.length, 1);
      expect(listaLocal.first.sincronizado, isFalse);
    });

    test('4. Resiliência: Deve capturar exceção de socket/rede sem travar o aplicativo', () async {
      final fakeLocal = FakeLocalDatasource();
      final mockClient = MockClient((_) async => throw http.ClientException('Sem conexão com a internet'));
      final remote = TelemetriaRemoteDatasourceImpl(client: mockClient);
      final repo = TelemetriaRepository(localDatasource: fakeLocal, remoteDatasource: remote);

      final telemetria = RegistroTelemetria(
        id: 'TEL-TEST-04',
        sensorId: 'SENSOR-D1',
        zona: 'Zona D',
        umidadeSolo: 62.0,
        temperatura: 23.0,
        nivelBateria: 85,
        timestamp: DateTime.now(),
      );

      final resultado = await repo.registrarTelemetria(telemetria);

      expect(resultado.sincronizado, isFalse);
      final pendentes = await fakeLocal.listarTelemetriasPendentes();
      expect(pendentes.length, 1);
    });

    test('5. Regra de Domínio AgroSense: Deve acionar irrigação automática quando umidade < 40%', () async {
      final fakeLocal = FakeLocalDatasource();
      final mockClient = MockClient((_) async => http.Response('OK', 200));
      final remote = TelemetriaRemoteDatasourceImpl(client: mockClient);
      final repo = TelemetriaRepository(localDatasource: fakeLocal, remoteDatasource: remote);

      final leituraCritica = RegistroTelemetria(
        id: 'TEL-CRITICA',
        sensorId: 'SENSOR-B2',
        zona: 'Zona B',
        umidadeSolo: 31.0, // < 40%
        temperatura: 32.0,
        nivelBateria: 70,
        timestamp: DateTime.now(),
      );

      await repo.registrarTelemetria(leituraCritica);

      final irrigacoes = await fakeLocal.listarTodasIrrigacoes();
      expect(irrigacoes.length, 1);
      expect(irrigacoes.first.zona, 'Zona B');
      expect(irrigacoes.first.valvulaAcionada, isTrue);
      expect(irrigacoes.first.motivo, contains('< 40.0%'));
    });

    test('6. Regra de Domínio AgroSense: NÃO deve acionar irrigação quando umidade >= 40%', () async {
      final fakeLocal = FakeLocalDatasource();
      final mockClient = MockClient((_) async => http.Response('OK', 200));
      final remote = TelemetriaRemoteDatasourceImpl(client: mockClient);
      final repo = TelemetriaRepository(localDatasource: fakeLocal, remoteDatasource: remote);

      final leituraNormal = RegistroTelemetria(
        id: 'TEL-NORMAL',
        sensorId: 'SENSOR-A2',
        zona: 'Zona A',
        umidadeSolo: 45.0, // >= 40%
        temperatura: 25.0,
        nivelBateria: 80,
        timestamp: DateTime.now(),
      );

      await repo.registrarTelemetria(leituraNormal);

      final irrigacoes = await fakeLocal.listarTodasIrrigacoes();
      expect(irrigacoes.isEmpty, isTrue);
    });

    test('7. Rotina sincronizarTudo(): deve sincronizar registros pendentes e retornar SyncResult', () async {
      final fakeLocal = FakeLocalDatasource();
      // Insere um registro pendente prévio
      await fakeLocal.salvarOuAtualizarTelemetria(
        RegistroTelemetria(
          id: 'TEL-PENDENTE',
          sensorId: 'SENSOR-E1',
          zona: 'Zona E',
          umidadeSolo: 50.0,
          temperatura: 22.0,
          nivelBateria: 90,
          timestamp: DateTime.now(),
          sincronizado: false,
        ),
      );

      final mockClient = MockClient((_) async => http.Response('OK', 200));
      final remote = TelemetriaRemoteDatasourceImpl(client: mockClient);
      final repo = TelemetriaRepository(localDatasource: fakeLocal, remoteDatasource: remote);

      final resultado = await repo.sincronizarTudo();

      expect(resultado.totalPendentes, 1);
      expect(resultado.sincronizadosComSucesso, 1);
      expect(resultado.falhas, 0);

      final pendentesApos = await fakeLocal.listarTelemetriasPendentes();
      expect(pendentesApos.isEmpty, isTrue);
    });

    test('8. Deve remover telemetria do banco local via removerTelemetria', () async {
      final fakeLocal = FakeLocalDatasource();
      final mockClient = MockClient((_) async => http.Response('OK', 200));
      final remote = TelemetriaRemoteDatasourceImpl(client: mockClient);
      final repo = TelemetriaRepository(localDatasource: fakeLocal, remoteDatasource: remote);

      await fakeLocal.salvarOuAtualizarTelemetria(
        RegistroTelemetria(
          id: 'TEL-DEL',
          sensorId: 'SENSOR-X',
          zona: 'Zona A',
          umidadeSolo: 50.0,
          temperatura: 25.0,
          nivelBateria: 100,
          timestamp: DateTime.now(),
        ),
      );

      await repo.removerTelemetria('TEL-DEL');
      final buscado = await fakeLocal.buscarTelemetriaPorId('TEL-DEL');
      expect(buscado, isNull);
    });
  });
}

